
module AhigsFos

  # Places is essentially a list of five schools. It is fed a string like:
  #   "1. Frensham  2. Danebank  3. PLCS  4. Kirribilli  5. Normanhurst"
  # and stores a hash like:
  #   { School[Frensham] => 1, School[Danebank] => 2, ... }
  # That is, it does school lookup and stores the results for later query.
  # The hash is keyed by school, not place, as ties are possible, and we can't
  # have two "3" keys in a hash, for instance.
  # This class also handles validation, so that results with non-existent or
  # duplicate schools, or more or less than five places will not be allowed
  # through.
  class Places
    def initialize(string, festival_info)
      @tie = false
      @places = _process_places_string(string, festival_info)
        # -> { "Meriden" => 1, "Calrossy" => 2, ... }
      @schools = @places.keys.to_set
      self.freeze
    end
    # Given a School object, returns 1-5 or nil, representing its place.
    def place(school)
      @places[school]
    end
    # List of schools that gained a place (School objects).
    def list
      @schools.to_a
    end
    def inspect
      @places.sort_by { |s,p| [p, s.name] }.map { |sch, pl|
        "#{pl}. #{sch.abbreviation}"
      }.join(', ')
    end
    alias to_s inspect
    # e.g. [1,2,3,4,5] or [1,1,3,4,5]
    def places_awarded
      @places.values.sort
    end

    private
    def _process_places_string(string, festival_info)
      hash = {}
      words = string.split
      # There must be exactly 10 words: five place markers and the school for
      # each.
      err 'Place marker must have 10 words', string unless words.size == 10
      words.each_slice(2) do |place, school_abbreviation|
        unless place =~ /\A([1-5]\.)\Z/
          err 'Place number must be 1-5', string
        end
        place_number = $1.to_i
        school = festival_info.school(school_abbreviation)
        if school.nil?
          err "No such school: #{school_abbreviation}", string
        elsif hash.key? school
          err "School #{school_abbreviation} appears twice", string
        end
        hash[school] = place_number
      end
      _check_valid_place_numbers(hash, string)
      hash
    end
    def _check_valid_place_numbers(hash, string)
      # Examples of valid place numbers:
      #   12345   11345   11335   12245   11111   12344
      #
      # Examples of invalid ones
      #   11234   12455   15555   22355
      #
      # In a valid set of sorted place numbers, each number is either equal to
      # its 1-based index or equal to the number before it.
      places = hash.values.sort
      (0..4).each do |idx|
        expected_value = idx+1    # In the normal sequence 12345
        unless places[idx] == places[idx-1] or places[idx] == expected_value
          err "Invalid set of place numbers: #{places}", string
        end
      end
    end
    def err(message, string)
      Err.invalid_place_string(message, string)
    end
  end  # class Places


  # This class processes a list of participant or non-participant strings and
  # stores a set of School objects that participated, using the master list in
  # the FestivalInfo object. (We ensure that schools who placed are counted as
  # participating, so that they don't need to be typed in twice.)
  class Participants
    def initialize(participants, nonparticipants, places, festival_info)
      @participants_set = _process(participants, nonparticipants, places, festival_info)
      @nonparticipants_set = festival_info.schools_list.to_set - @participants_set
      @self.freeze
    end
    def participated?(school)
      @participants_set.include? school
    end
    alias include? participated?
    def inspect
      p = @participants_set.to_a.map { |sch| sch.abbreviation }.sort.join(', ')
      np = @nonparticipants_set.to_a.map { |sch| sch.abbreviation }.sort.join(', ')
      "Participants: #{p}\nNon-participants: #{np}"
    end
    alias to_s inspect
    def size
      @participants_set.size
    end
    private
    def _process(participants, nonparticipants, places, festival_info)
      # Exactly one of participants and nonparticipants must be nil. The other
      # must be a list of strings.
      list = []
      if participants.nil? and nonparticipants.nil?
        err "Neither Participants nor Nonparticipants is defined"
      elsif participants and nonparticipants
        err "Both Participants and Nonparticipants are defined"
      end
      if participants
        unless Array === participants and participants.all? { |x| String === x }
          err "Participants: not array of strings: #{participants.inspect}"
        end
        # Build school list out of strings in participant list. Ensure we
        # include schools that placed, regardless of whether they are in the
        # participant list.
        list = festival_info.school_list(participants)
        list = (list + places.list).uniq
      elsif nonparticipants
        unless Array === nonparticipants and nonparticipants.all? { |x| String === x }
          err "Nonparticipants: not array of strings: #{nonparticipants.inspect}"
        end
        list = festival_info.schools_list.dup - festival_info.school_list(nonparticipants)
      else
        err "Can't get here"
      end
      list.to_set
    end
    def err(msg)
      Err.invalid_section(msg)
    end
  end  # class Participants


  class Results
    def initialize(festival_info)
      @festival_info = festival_info
      @section_results = _process_results(festival_info)
      @leaderboards = _generate_leaderboards
    end
    def inspect
      out = StringIO.new
      out.puts "Results:"
      @section_results.each do |sec, res|
        out.puts res.to_s.indent(2)
      end
      out.string
    end
    alias to_s inspect
    def for_section(str)
      if @festival_info.section? str
        @section_results[str]
      else
        Err.invalid_section(str)
      end
    end
    def points_for_school(school, division)
      section_results(division).map { |sec|
        sec && sec.points_for_school(school) || 0
      }.sum
    end
    def section_results(division)
      @festival_info.sections(division).map { |sec|
        @section_results[sec]
      }
    end
    # Yields: position (1-5), school (School), points (int).
    def top_five_schools(division, &block)
      @leaderboards[division].top_schools(5, &block)
    end
    private
    def _process_results(festival_info)
      path = Dirs.instance.current_year_data_directory + "results.yaml"
      data = YAML.load(path.read)
      _validate_data(data)
      results = {}
      data.each do |hash|
        section = hash["Section"]
        err "Invalid section: #{section}" unless festival_info.section?(section)
        places_str = hash["Places"]
        unless String === places_str and places_str["1."]
          err "Invalid places string: #{places_str}"
        end
        places = Places.new(places_str, festival_info)
        p, nonp = hash.values_at("Participants", "Nonparticipants")
        participants = Participants.new(p, nonp, places, festival_info)
        results[section] = SectionResult.new(section, places, participants, festival_info)
      end
      results
    end
    def _generate_leaderboards
      leaderboards = {}
      [:junior, :senior, :all].each do |division|
        results = @festival_info.schools_list.map { |school|
          [school, points_for_school(school, division)]
        }
        leaderboards[division] = SchoolLeaderboard.new(division, results)
      end
      leaderboards
    end
    # 'data' is expected to be an array of hashes, each of which contains
    # keys "Sections", "Places", and optionally "Participants" or
    # "Nonparticipants".
    def _validate_data(data)
      valid_keys = ['Section', 'Places', 'Participants', 'Nonparticipants']
      err 'not an array of hashes' unless
        Array === data and data.all? { |x| Hash === x }
      err 'missing keys Section and Places' unless
        data.all? { |h| h.key? "Section" and h.key? "Places" }
      unless data.all? { |h| (h.keys - valid_keys).empty? }
        err 'invalid key'
      end
    end
    def err(str) Err.invalid_results_data(str) end
  end  # class Results


  # A SectionResult knows what section it is, which schools were placed 1-5 (or
  # with a tie, if necessary), and a full list of participating schools. It can
  # then answer questions like:
  #  * how many points did school X get from this section?
  #  * what achievement did school X get in this section (e.g. 4, P, -)
  # That way, each school can iterate over each section to find out their total
  # points tally.
  class SectionResult
    def initialize(section, places, participants, festival_info)
      @section, @places, @participants = section, places, participants
      @festival_info = festival_info
      puts "* Section result created (@section)"
      #p self
      self.freeze
    end
    def inspect
      out = StringIO.new
      out.puts "Section: #{@section}"
      out.puts "  Places: #{@places}"
      out.puts @participants.to_s.indent(2)
      out.string
    end
    alias to_s inspect
    def points_for_school(school)
      if place = @places.place(school)
        @festival_info.points_for_place(place)
      elsif @participants.include?(school)
        @festival_info.points_for_participation
      else
        0
      end
    end
    def total_points
      total = 0
      @places.places_awarded.each do |p|
        total += @festival_info.points_for_place(p)
      end
      total += @participants.size * @festival_info.points_for_participation
        # FIXME: this could be counting winners as participants as well
      total
    end
    def tie?
      @places.places_awarded.uniq.size != @places.places_awarded.size
    end
  end  # class SectionResult

  
  class SchoolLeaderboard
    # division: junior, senior, all
    # results: array of [school, points].
    def initialize(division, results)
      @division = division
      @results = results.sort_by { |sch, pts| [-pts, sch.abbreviation.downcase] }
    end
    # Yields: position (1-5), school (School), points (int).
    def top_schools(n)
      # todo: handle ties
      @results[0...n].each.with_index do |(school, points), idx|
        yield [idx+1, school, points]
      end
    end
    def schools(starting_position)
      @results[starting_position-1..-1].map { |school, _| school }
    end
  end  # class SchoolLeaderboard

end  # module AhigsFos
