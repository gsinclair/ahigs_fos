
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
    def include?(school)
      @places.key?(school)
    end
    # List of schools that gained a place (School objects).
    def school_list
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
    # Yields: place, school
    def each_place
      @places.sort_by { |s,p| [p, s.name] }.each do |school, place|
        yield [place, school]
      end
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
      @strict_participants_set = @participants_set - places.school_list
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
    def participants() @participants_set end
    def nonparticipants() @nonparticipants_set end
    def strict_participants() @strict_participants_set end
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
        list = (list + places.school_list).uniq
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


  # The result that a school achieved in one section.
  # Contains the outcome (1,2,3,4,5,:p,:dnp) and the points (e.g. 30,25,...,5,0).
  # Used (only) as a return value from SectionResult#result_for_school.
  class Result
    attr_reader :outcome, :points
    def initialize(outcome, points)
      @outcome, @points = outcome, points
    end
    def participated?
      outcome == :p or Integer === outcome
    end
    def to_a
      [@outcome, @points]
    end
  end


  # This is the main class in this file. It combines the section results and the school results,
  # and methods to quuery these.
  #
  # NOTE: how should debating results be handled. Should @section_results look like this?
  #
  #   { "Reading (Junior)"  => SectionResult,
  #     "Reading (Senior)"  => SectionResult,
  #     "Debating (Junior)" => DebatingResult,
  #     ... }
  #
  # That kind of data structure seems good, but the naming of @section_results and SectionResult
  # is a clash.  @section_results seems like the right name; SectionResult doesn't.  But what?
  # NonDebatingSectionResult?  Should I have SectionResult::Debating and SectionResult::NonDebating?
  # PlaceGettingSectionResult?  That last one is an accurate and general description.  Maybe
  # SectionResult::Debating and SectionResult::PlaceGetting.
  #
  # Anyway, assuming this kind of (mixed) data structure, could @school_results do its thing?
  # Well, it must!  It needs the number of points from each section and not much else..
  #
  # And then there is the line in bin/ahigs_fos.rb:
  #
  #   report = Report::Report.new(results, festival_info)
  #
  # I think the reporting code can be smart enough to treat debating and non-debating results
  # separately.
  class Results
    def initialize(festival_info)
      @festival_info = festival_info
      @place_getting_section_results = _process_section_results(festival_info)
        # -> { "Readings (Junior)" => SectionResult,
        #      "Current Affairs" => SectionResult, ... }
      @debating_results = _process_debating_results(festival_info)
        # -> { "Debating (Junior)" => DebatingResult,
        #      "Debating (Senior)" => DebatingResult }
      @section_results = @debating_results.merge @place_getting_section_results
      @school_results = _process_school_results(festival_info, @section_results, @debating_results)
        # -> { "Ascham" => SchoolResults, "Monte" => SchoolResults, ... }
      debug "Results object created"
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
    
    # -> [15,0,5,10,5,5,5]
    # todo -- maybe can this; we have SchoolResults and FestivalAwardsLeaderboard
    def results_for_school(school, division)
      section_results(division).map { |sec|
        sec && sec.points_for_school(school) || 0
      }
    end

    # -> 45
    # todo -- maybe can this; we have SchoolResults and FestivalAwardsLeaderboard
    def points_for_school(school, division)
      results_for_school(school, division).sum
    end
    
    def section_results(division)
      @festival_info.sections(division).map { |sec|
        for_section(sec)
      }
    end

    # Yields: position (1-5), SchoolResult
    def top_five_schools(division, &block)
      leaderboard(division).top_schools(20, &block)
    end
    
    # Yields: school, junior, senior, total
    def all_schools_by_total_desc
      leaderboard(:all).schools(1).each do |sch|
        jnr   = points_for_school(sch, :junior)
        snr   = points_for_school(sch, :senior)
        tot   = jnr + snr
        yield sch, jnr, snr, tot
      end
    end
    
    def leaderboard(division)
      FestivalAwardsLeaderboard.new(division, @school_results.values)
    end
    
    private
    
    def _process_section_results(festival_info)
      path = @festival_info.dirs.current_year_data_directory + "results.yaml"
      data = YAML.load(path.read)
      _validate_section_data(data)
      section_results = {}
      data.each do |hash|
        section = hash["Section"]
        err "Invalid section: #{section}" unless festival_info.section?(section)
        places_str = hash["Places"]
        section_results[section] =
          if String === places_str and places_str["1."]
            places = Places.new(places_str, festival_info)
            p, nonp = hash.values_at("Participants", "Nonparticipants")
            participants = Participants.new(p, nonp, places, festival_info)
            SectionResult.new(section, places, participants, festival_info)
          elsif String === places_str and places_str.empty?
            nil
          else
            err "Invalid places string: #{places_str}"
          end
      end
      section_results
    end
    
    def _process_debating_results(festival_info)
      if festival_info.debating_included?
        path = @festival_info.dirs.current_year_data_directory + "debating_results.yaml"
        data = YAML.load(path.read)
        _validate_debating_data(data)
        debating_results = {}
        ["Debating (Junior)", "Debating (Senior)"].each do |x|
          debating_results[x] = DebatingResults.from_results_data(data[x], festival_info)
        end
        debating_results
      else
        {}
      end
    end
    
    def _process_school_results(festival_info, section_results, debating_results)
      # NOTE: we need to do something with the debating_results parameter
      school_results = {}
      festival_info.schools_set.each do |school|
        results = {}
        section_results.each do |name, sr|
          results[name] =
            if sr.nil?
              nil
            else
              sr.result_for_school(school)
            end
        end
        # This next line could include debating results for the school.
        school_results[school] = SchoolResults.new(festival_info, school, results)
      end
      school_results
    end
    
    # 'data' is expected to be an array of hashes, each of which contains
    # keys "Sections", "Places", and optionally "Participants" or
    # "Nonparticipants".
    def _validate_section_data(data)
      valid_keys = ['Section', 'Places', 'Participants', 'Nonparticipants']
      err 'not an array of hashes' unless
        Array === data and data.all? { |x| Hash === x }
      err 'missing keys Section and Places' unless
        data.all? { |h| h.key? "Section" and h.key? "Places" }
      unless data.all? { |h| (h.keys - valid_keys).empty? }
        err 'invalid key'
      end
    end
    
    def _validate_debating_data(data)
      err '(debating) expect keys for junior and senior debating' unless 
        data.keys.sort == ["Debating (Junior)", "Debating (Senior)"]
      # err '(debating) values are not hashes with Round1, Round2A etc.' unless
      #   data.values.all? { |x| Hash === x and x.key?('Round1') }
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
  # NOTE: This class should almost certainly be called SectionResults to match
  #       DebatingResults and SchoolResults.
  class SectionResult
    def initialize(section, places, participants, festival_info)
      @section, @places, @participants = section, places, participants
      @festival_info = festival_info
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
    def debating?
      false
    end
    # Return the result and the number of points. Examples:
    #   [3, 20]
    #   [:p, 5]   (participated)
    #   [:dnp, 0] (did not participate)
    def result_for_school(school)
      @festival_info.check_school(school)
      if place = @places.place(school)
        Result.new(place, @festival_info.points_for_place(place))
      elsif @participants.include?(school)
        Result.new(:p, @festival_info.points_for_participation)
      else
        Result.new(:dnp, 0)
      end
    end
    # Return just the number of points the school got in this section.
    def points_for_school(school)
      result_for_school(school).points
    end
    # Total points awarded in this section.
    def total_points
      # There are two ways to calculate the total:
      #   1. Points awarded for each place + points awarded for participating schools.
      #   2. Total of points awarded to all schools (less efficient to calculate).
      # We do both totals as a check and raise an error if they're not the same.
      total1 = 0
      @places.places_awarded.each do |p|
        total1 += @festival_info.points_for_place(p)
      end
      total1 += @participants.strict_participants.size * @festival_info.points_for_participation
      total2 = @festival_info.schools_list.map { |sc| points_for_school(sc) }.sum
      unless total1 == total2
        Err.inconsistent_total_points_for_section_result(total1, total2)
      end
      total1
    end
    def tie?
      @places.places_awarded.uniq.size != @places.places_awarded.size
    end
    # Yields: position, school, points awarded
    def places
      @places.each_place do |pos, school|
        yield [pos, school, @festival_info.points_for_place(pos)]
      end
    end
    def participants
      @participants.participants
    end
    def nonparticipants
      @participants.nonparticipants
    end
    def strict_participants
      @participants.strict_participants
    end
  end  # class SectionResult


  # This class aggregates all the results for a given school. This is the place
  # to determine whether a school is a full participant of the festival, whether
  # it is eligible for each award, and its point score for each of the awards.
  #
  # For example:
  #   s = SchoolResults.new(<Monte>, { "Current Affairs" => Result,
  #                                    "Readings (Junior) => Result, ... })
  class SchoolResults
    attr_reader :school
    def initialize(festival_info, school, results_hash)
      @festival_info = festival_info
      @school, @results = school, results_hash
    end
    def result_for_section(section)
      @results[section]
    end
    # division: junior, senior, all
    # returns: hash (subset of the @results hash)
    def results_for_division(division)
      if division == :all
        @results
      else
        sections = @festival_info.sections(division)
        @results.select { |section, result| sections.include? section }
      end
    end
    def full_participant?
      n_entered = @results.values.count { |r| r && r.participated? }
      ca, req = "Current Affairs", "Religious and Ethical Questions"
      n_entered >= 5 and [ca, req].any? { |sec|
        (r = @results[sec]) && r.participated?
      }
    end
    def eligible?(division)
      results = results_for_division(division)
      n_entered = results.values.count { |r| r && r.participated? }
      # todo -- configure this in festival_info.yaml
      case division
      when :junior
        n_entered == 3
      when :senior
        n_entered >= 4
      when :all
        full_participant?
      end
    end
    # The score for a festival award in a certain division is the sum of the best N
    # results, where N varies by division.  We do not consider eligibility here; we just
    # add up the scores.  Eligibility is for others to consider.
    def score(division)
      # todo -- configure this in festival_info.yaml
      n = case division
          when :junior then 3
          when :senior then 3
          when :all then @results.size
          end
      point_list(division).sort.reverse.take(n).sum
    end
    def point_list(division)
      results_for_division(division).values.map { |r| r && r.points || 0 }
    end
  end  # class SchoolResults

  
  # This class contains the results for all schools in a single division
  # (junior, senior, all).
  class FestivalAwardsLeaderboard
    # division: junior, senior or all (symbol)
    # school_results: [ SchoolResult ]
    def initialize(division, school_results)
      @division = division
      @leaderboard = school_results.sort_by { |r|
        [ -r.score(division), r.school.abbreviation.downcase ]
      }
    end
    # Yields: position (1-n), SchoolResult object
    def top_schools(n)
      @leaderboard.take(n).each.with_index do |schoolresult, idx|
        yield [idx+1, schoolresult]
      end
    end
    # Returns a list of schools starting at the given position.
    # E.g. schools(6) -> [school_in_position_6, school_in_position_7, ...]
    def schools(starting_position)
      (@leaderboard.drop(starting_position-1) || []).map { |sr| sr.school }
    end
    private
  end  # class SchoolLeaderboard

end  # module AhigsFos
