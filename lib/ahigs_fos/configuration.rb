# app/comp-scorer/configuration.rb -- handles configuration

require 'singleton'
require 'set'

module AhigsFos

  # class Dirs
  #
  # Provides an interface to the data and reports directories.  Is responsible
  # for configuring itself (single instance) from the standard configuration
  # file.
  #
  class Dirs
    include Singleton

    def initialize
      begin
        data = File.read( Constants::DIRECTORIES_CONFIG_FILE_NAME )
      rescue
        Err.no_configuration_file
      end
      data = YAML.load(data)
      dirs = data['directories'] || Err.invalid_config("No 'directories' config")
      @data_directory    = _check('directories/data',    dirs['data'])
      @reports_directory = _check('directories/reports', dirs['reports'])
      @year = Date.today.year.to_s
    end
    def current_year_data_directory
      @data_directory + @year
    end
    def current_year_reports_directory
      @reports_directory + @year
    end
    def _check(label, object)
      if object.nil?
        Err.no_directory_information(label: label)
      end
      path = Pathname(object)
      unless path.exist? and path.directory?
        Err.directory_doesnt_exist(label: label)
      end
      path
    end
    private :_check
  end  # class Dirs


  # A School value object simply contains an abbreviation and a name.
  class School
    def initialize(abbreviation, name)
      @abbreviation, @name = abbreviation, name
    end
    attr_reader :abbreviation, :name
    def hash() [self.class, @abbreviation, @name].hash end
    def ==(other)
      other.class == self.class and
        other.abbreviation == self.abbreviation and
        other.name == self.name
    end
    def to_s
      "School[#{abbreviation}, #{name}]"
    end
  end  # class School


  # The FestivalInfo class (instance) knows such things as:
  # * what schools are participating
  # * what sections (events) are run
  # * points awarded for places 1-5 and participation
  #
  # These events are the non-debating events. Debating is competed over several
  # rounds and must be considered separately (and I don't know the details at
  # the moment).
  class FestivalInfo
    def initialize
      path = Dirs.instance.current_year_data_directory + "festival_info.yaml"
      data = path.read
      data = YAML.load(data)
      @points_for_place, @points_for_participation = _process_points(data["points"])
      @sections = data["sections"]
      @schools_by_abbreviation, @schools_by_name = _process_schools(data["schools"])
        # { "OLMC" -> School, "PLCS" -> School, ... } and
        # { "Our Lady of Mercy College" -> School, "PLC Sydney" -> School, ... }
      @schools = @schools_by_abbreviation.values.to_set
      @school_names = @schools.map { |s| s.name }.to_set
      self.freeze
    end
    # ["Reading (Junior)", "Reading (Senior)", ...]
    def sections
      @sections
    end
    # List of schools (School objects)
    def schools
      @schools
    end
    def school_names
      @schools.map { |s| s.name }
    end
    # school("OLMC") or school("Our Lady of Mercy College")
    # Returns School object or raises error.
    def school(string)
      if @schools_by_abbreviation.key?(string)
        @schools_by_abbreviation[string]
      elsif @schools_by_name.key?(string)
        @schools_by_name[string]
      else
        Err.school_not_found(string)
      end
    end
    # Argument: 1 to 5 (integer)
    def points_for_place(n)
      Err.invalid_place(n) unless (1..5) === n
      @points_for_place[n]
    end
    def points_for_participation
      @points_for_participation
    end
    def _process_schools(list)
      by_abbrev, by_name = {}, {}
      list.each do |item|
        words = item.gsub(/[()]/, '').split(/\s+/)
        abbrev, name = words[0], words[1..-1]
        name = [abbrev] if name.empty?
        name = name.join(' ')
        by_abbrev[abbrev] = by_name[name] = School.new(abbrev, name)
      end
      [by_abbrev, by_name]
    end
    # Returns a hash of points for places (1..5) and the value of participation.
    # Expected return value (2012):
    #   { 1 -> 30, 2 -> 25, ..., 5 -> 10 }   and   5
    def _process_points(hash)
      unless hash.keys.to_set == Set[1,2,3,4,5,"participation"]
        Err.invalid_points_config(hash.keys)
      end
      points = hash.select { |k| Integer === k and k >= 1 and k <= 5 }
      participation = hash["participation"]
      [points, participation]
    end
    private :_process_schools, :_process_points
  end  # class FestivalInfo


  class Results
    def initialize(festival_info)
      @festival_info = festival_info
      process_results
    end
    def process_results
      path = Dirs.instance.current_year_data_directory + "results.yaml"
      data = YAML.load(path)
    end
  end  # class Results


  class Report
    def initialize(results)
      @results = results
    end
    def write(directory)
      timestamp = Time.now.to_i
      path = directory + "#{timestamp}.txt"
      path.open('w') do |f|
        f.puts "Report... #{Time.now}"
      end
      puts "Wrote file: #{path}"
    end
  end  # class Report

end  # module AhigsFos
