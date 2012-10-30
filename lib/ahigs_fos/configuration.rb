# app/comp-scorer/configuration.rb -- handles configuration

require 'singleton'
require 'set'

module AhigsFos

  # class Directories
  #
  # Provides an interface to the data and reports directories. It configures
  # itself from a yaml file that looks like:
  #
  #   directories:
  #     config:  "config"
  #     data:    "data"
  #     reports: "reports"
  #
  class Directories
    def initialize(config_file_path, calyear)
      begin
        data = File.read(config_file_path)
      rescue
        Err.no_configuration_file
      end
      data = YAML.load(data)
      dirs = data['directories'] || Err.invalid_config("No 'directories' config")
      @data_directory    = _check('directories/data',    dirs['data'])
      @reports_directory = _check('directories/reports', dirs['reports'])
      @year = calyear
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
  end  # class Directories


  # A School value object simply contains an abbreviation and a name.
  class School
    def initialize(abbreviation, name)
      @abbreviation, @name = abbreviation.dup, name.dup
      self.freeze
    end
    attr_reader :abbreviation, :name
    def hash() [self.class, @abbreviation, @name].hash end
    def eql?(other)
      self.equal? other or (
        other.class == self.class and
          other.abbreviation == self.abbreviation and
          other.name == self.name
      )
    end
    alias == eql?
    def to_s
      "School[#{abbreviation}, #{name}]"
    end
    def <=>(other)
      self.abbreviation <=> other.abbreviation
    end
    include Comparable
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
    def initialize(config_file_path, calyear)
      @dirs = Directories.new(config_file_path, calyear)
      path  = @dirs.current_year_data_directory + "festival_info.yaml"
      data  = path.read
      data  = YAML.load(data)
      @year = data["year"]
      raise "Year mismatch between command-line and data" unless @year.to_s == calyear
      @points_for_place, @points_for_participation = _process_points(data["points"])
      @sections = _process_sections(data["sections"])
      @schools_by_abbreviation, @schools_by_name = _process_schools(data["schools"])
        # { "OLMC" -> School, "PLCS" -> School, ... } and
        # { "Our Lady of Mercy College" -> School, "PLC Sydney" -> School, ... }
      @schools_set = @schools_by_abbreviation.values.to_set
      @schools_list = @schools_set.to_a
      self.freeze
    end
    def dirs
      @dirs
    end
    def year
      @year
    end
    # ["Reading (Junior)", "Reading (Senior)", ...]
    def sections(division=nil)
      case division
      when :junior   then @sections[:junior]
      when :senior   then @sections[:senior]
      when nil, :all then @sections[:all]
      else
        Err.argument_error("FestivalInfo#sections: #{division}")
      end
    end
    def section?(str)
      @sections[:all].include? str
    end
    # List of schools (School objects)
    def schools_list
      @schools_list
    end
    def schools_set
      @schools_set
    end
    def max_abbreviation_length
      @schools_list.map { |s| s.abbreviation.length }.max
    end
    def max_school_name_length
      @schools_list.map { |s| s.name.length }.max
    end
    # school("OLMC") or school("Our Lady of Mercy College")
    # Returns School object or nil.
    def school(string)
      if @schools_by_abbreviation.key?(string)
        @schools_by_abbreviation[string]
      elsif @schools_by_name.key?(string)
        @schools_by_name[string]
      else
        nil
      end
    end
    # Generates a list of School objects from a list of abbreviations or names,
    # raising an error if any doesn't exist.
    # TODO: better name
    def school_list(abbrs)
      abbrs.map { |abbr|
        s = school(abbr)
        if s.nil?
          Err.nonexistent_school(abbr)
        end
        s
      }
    end
    # Simply raise an error if the school doesn't exist.
    def check_school(school)
      Err.nonexistent_school(school.abbreviation) unless @schools_set.include? school
    end
    # Argument: 1 to 5 (integer)
    def points_for_place(n)
      Err.invalid_place(n) unless (1..5) === n
      @points_for_place[n]
    end
    def points_for_participation
      @points_for_participation
    end
    def _process_sections(hash)
      h = {}
      h[:junior] = hash["junior"]
      h[:senior] = hash["senior"]
      h[:all] = h[:junior] + h[:senior]
      h
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

end  # module AhigsFos
