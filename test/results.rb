
D "Results (building blocks)" do
  @f = FestivalInfo.new(AhigsFosTest::DIRECTORIES_YAML)
  D "Places" do
    D "Regular test (places 1-5 awarded)" do
      string = "1. Frensham 2. Danebank  3. PLCS    4.  Kirribilli  5.  Normanhurst"
      @p = Places.new(string, @f)
      D "find the place of a given school ('place')" do
        Eq @p.place(School.new("Frensham", "Frensham")), 1
        Eq @p.place(School.new("Danebank", "Danebank")), 2
        Eq @p.place(School.new("PLCS", "PLC Sydney")), 3
        Eq @p.place(School.new("Kirribilli", "Loreto Kirribilli")), 4
        Eq @p.place(School.new("Normanhurst", "Loreto Normanhurst")), 5
        D "nil if school didn't place" do
          N @p.place(School.new("Armidale", "PLC Armidale"))
          D "and even if the school isn't a real one" do
            N @p.place(School.new("Foo", "Bar"))
          end
        end
      end
      D "query whether a school placed ('include?')" do
        T @p.include?(School.new("Frensham", "Frensham"))
        T @p.include?(School.new("Danebank", "Danebank"))
        T @p.include?(School.new("PLCS", "PLC Sydney"))
        T @p.include?(School.new("Kirribilli", "Loreto Kirribilli"))
        T @p.include?(School.new("Normanhurst", "Loreto Normanhurst"))
        F @p.include?(School.new("Armidale", "PLC Armidale"))
        F @p.include?(School.new("Foo", "Bar"))
      end
      D "list the schools that placed ('school_list')" do
        Eq @p.school_list, [School.new("Frensham", "Frensham"),
                            School.new("Danebank", "Danebank"),
                            School.new("PLCS", "PLC Sydney"),
                            School.new("Kirribilli", "Loreto Kirribilli"),
                            School.new("Normanhurst", "Loreto Normanhurst")]
      end
      D "list the numerical places awarded ('places_awarded')" do
        Eq @p.places_awarded, [1,2,3,4,5]
      end
      D "can iterate over each place and school in order" do
        places = { 1 => "Frensham", 2 => "Danebank", 3 => "PLCS",
                   4 => "Kirribilli", 5 => "Normanhurst"}
        @p.each_place do |p, s|
          T places.key? p
          Eq s.abbreviation, places.delete(p)
        end
        T places.empty?
      end
    end  # D "Regular test ..."
    D "Irregular test (tie for 2nd and 4th places)" do
      string = "1. Calrossy 2. Armidale 2. OLMC 4. Canberra 4. StClares"
      @p = Places.new(string, @f)
      D "same tests as above" do
        # find the place of a given school ('place')
        Eq @p.place(School.new("Calrossy", "Calrossy")), 1
        Eq @p.place(School.new("OLMC", "Our Lady of Mercy College")), 2
        Eq @p.place(School.new("Armidale", "PLC Armidale")), 2
        Eq @p.place(School.new("Canberra", "Canberra Girls Grammar")), 4
        Eq @p.place(School.new("StClares", "St Clare's")), 4
        # nil if a school didn't place or doesn't exist
        N @p.place(School.new("StCatherines", "St Catherine's"))
        N @p.place(School.new("Foo", "Bar"))
        # include?
        T @p.include?(School.new("Calrossy", "Calrossy"))
        T @p.include?(School.new("OLMC", "Our Lady of Mercy College"))
        T @p.include?(School.new("Armidale", "PLC Armidale"))
        T @p.include?(School.new("Canberra", "Canberra Girls Grammar"))
        T @p.include?(School.new("StClares", "St Clare's"))
        F @p.include?(School.new("StCatherines", "St Catherine's"))
        F @p.include?(School.new("Foo", "Bar"))
        # list the schools that placed
        Eq @p.school_list, [School.new("Calrossy", "Calrossy"),
                            School.new("Armidale", "PLC Armidale"),
                            School.new("OLMC", "Our Lady of Mercy College"),
                            School.new("Canberra", "Canberra Girls Grammar"),
                            School.new("StClares", "St Clare's")]
        # list the numerical places awarded
        Eq @p.places_awarded, [1,2,2,4,4]
        # can iterate over each place and school in order
        places = [ [1, "Calrossy"], [2, "OLMC"], [2, "Armidale"],
                   [4, "Canberra"], [4, "StClares"] ]
        @p.each_place do |p, s|
          place = places.shift
          Eq p, place.first
          Eq s.abbreviation, place.last
        end
        T places.empty?
      end
    end  # D "Irregular test..."
    D "Invalid input" do
      D "invalid place allocations (11234, 12346)" do
        # 11234 (and check that 11345 is OK)
        string = "1. Calrossy 1. Armidale 2. OLMC 3. Canberra 4. StClares"
        E { Places.new(string, @f) }
        Mt Whitestone.exception.message, /invalid place string/i
        string = "1. Calrossy 1. Armidale 3. OLMC 4. Canberra 5. StClares"
        E! { Places.new(string, @f) }
        # place number out of range (6)
        string = "1. Calrossy 2. Armidale 3. OLMC 4. Canberra 6. StClares"
        E { Places.new(string, @f) }
      end
      D "invalid school abbreviations" do
        string = "1. Calrossy 2. Armidale 2. INVALID 4. Canberra 4. StClares"
        E { Places.new(string, @f) }
        Mt Whitestone.exception.message, /invalid place string/i
      end
    end
  end  # D "Places"

  D "Participants" do
    string = "1. Frensham 2. Danebank  3. PLCS    4.  Kirribilli  5.  Normanhurst"
    @places = Places.new(string, @f)
    D "Defined by who's participating" do
      list = ["Queenwood", "Ravenswood", "Meriden", "OLMC", "Pymble"]
      @p = Participants.new(list, nil, @places, @f)
      D "query whether a school participated ('participated?')" do
        T @p.participated?(School.new("Ravenswood", "Ravenswood"))
        T @p.participated?(School.new("Meriden", "Meriden"))
        T @p.participated?(School.new("Pymble", "Pymble Ladies College"))
        T @p.participated?(School.new("OLMC", "Our Lady of Mercy College"))
        F @p.participated?(School.new("StClares", "St Clare's"))
        D "those who placed DID participate, whether listed or not" do
          T @p.participated?(School.new("Frensham", "Frensham"))
          T @p.participated?(School.new("Danebank", "Danebank"))
          T @p.participated?(School.new("PLCS", "PLC Sydney"))
          T @p.participated?(School.new("Kirribilli", "Loreto Kirribilli"))
          T @p.participated?(School.new("Normanhurst", "Loreto Normanhurst"))
        end
        D "size" do
          Eq @p.size, 10
        end
        D "participants() and nonparticipants() return set of schools" do
          Ko @p.participants, Set
          Eq @p.participants.size, 10
          Ko @p.nonparticipants, Set
          Eq @p.nonparticipants.size, 19
          T  @p.nonparticipants.include?(School.new("StClares", "St Clare's"))
          D "nonparticipants() doesn't include place-getters" do
            F @p.nonparticipants.include?(School.new("Frensham", "Frensham"))
          end
        end
        D "strict_participants() doesn't include place-getters" do
          Ko @p.strict_participants, Set
          Eq @p.strict_participants.size, 5
          T  @p.strict_participants.include?(School.new("Queenwood", "Queenwood"))
          T  @p.strict_participants.include?(School.new("Ravenswood", "Ravenswood"))
          T  @p.strict_participants.include?(School.new("Meriden", "Meriden"))
          T  @p.strict_participants.include?(School.new("OLMC", "Our Lady of Mercy College"))
          T  @p.strict_participants.include?(School.new("Pymble", "Pymble Ladies College"))
          F  @p.strict_participants.include?(School.new("Frensham", "Frensham"))
        end
      end
    end
    D "Defined by who's NOT participating" do
      list = ["Queenwood", "Ravenswood", "Meriden", "OLMC", "Pymble"]
      @p = Participants.new(nil, list, @places, @f)
      D "same tests as above" do
        # "query whether a school participated ('participated?')"
        F @p.participated?(School.new("Ravenswood", "Ravenswood"))
        F @p.participated?(School.new("Meriden", "Meriden"))
        F @p.participated?(School.new("Pymble", "Pymble Ladies College"))
        F @p.participated?(School.new("OLMC", "Our Lady of Mercy College"))
        T @p.participated?(School.new("StClares", "St Clare's"))
        # "those who placed DID participate, whether listed or not"
        T @p.participated?(School.new("Frensham", "Frensham"))
        T @p.participated?(School.new("Danebank", "Danebank"))
        T @p.participated?(School.new("PLCS", "PLC Sydney"))
        T @p.participated?(School.new("Kirribilli", "Loreto Kirribilli"))
        T @p.participated?(School.new("Normanhurst", "Loreto Normanhurst"))
        # "size"
        Eq @p.size, 24
        # "participants() and nonparticipants() return set of schools"
        Ko @p.participants, Set
        Eq @p.participants.size, 24
        Ko @p.nonparticipants, Set
        Eq @p.nonparticipants.size, 5
        T  @p.nonparticipants.include?(School.new("Queenwood", "Queenwood"))
        # "strict_participants() doesn't include place-getters"
        Ko @p.strict_participants, Set
        Eq @p.strict_participants.size, 19
        F  @p.strict_participants.include?(School.new("Frensham", "Frensham"))
        F  @p.strict_participants.include?(School.new("Danebank", "Danebank"))
        F  @p.strict_participants.include?(School.new("PLCS", "PLC Sydney"))
        F  @p.strict_participants.include?(School.new("Kirribilli", "Loreto Kirribilli"))
        F  @p.strict_participants.include?(School.new("Normanhurst", "Loreto Normanhurst"))
        T  @p.strict_participants.include?(School.new("StClares", "St Clare's"))
      end
    end
  end  # D "Participants"

end  # D "Results (building blocks)"

# ------------------------------------------------------------------------------

D "Results" do

  D "SectionResult" do
    @f = FestivalInfo.new(AhigsFosTest::DIRECTORIES_YAML)

    D "Broad test of a specific instance" do
      @places = Places.new("1. Frensham 2. Danebank 3. PLCS 4. Kirribilli 5. Normanhurst", @f)
      list = ["Queenwood", "Ravenswood", "Meriden", "OLMC", "Pymble"]
      @participants = Participants.new(list, nil, @places, @f)
      @sr = SectionResult.new("Current Affairs", @places, @participants, @f)
      D "'result_for_school' -> result (1..5,:p,:dnp) and points" do
        D "hardcoded outcomes" do
          Eq @sr.result_for_school(School.new("Frensham", "Frensham")), [1, 30]
          Eq @sr.result_for_school(School.new("Danebank", "Danebank")), [2, 25]
          Eq @sr.result_for_school(School.new("PLCS", "PLC Sydney")), [3, 20]
          Eq @sr.result_for_school(School.new("Kirribilli", "Loreto Kirribilli")), [4, 15]
          Eq @sr.result_for_school(School.new("Normanhurst", "Loreto Normanhurst")), [5, 10]
          Eq @sr.result_for_school(School.new("Queenwood", "Queenwood")), [:p, 5]
          Eq @sr.result_for_school(School.new("Ravenswood", "Ravenswood")), [:p, 5]
          Eq @sr.result_for_school(School.new("Meriden", "Meriden")), [:p, 5]
          Eq @sr.result_for_school(School.new("OLMC", "Our Lady of Mercy College")), [:p, 5]
          Eq @sr.result_for_school(School.new("Pymble", "Pymble Ladies College")), [:p, 5]
          Eq @sr.result_for_school(School.new("Abbotsleigh", "Abbotsleigh")), [:dnp, 0]
          Eq @sr.result_for_school(School.new("Ascham", "Ascham")), [:dnp, 0]
          Eq @sr.result_for_school(School.new("Brigidine", "Brigidine")), [:dnp, 0]
          Eq @sr.result_for_school(School.new("Calrossy", "Calrossy")), [:dnp, 0]
          Eq @sr.result_for_school(School.new("Canberra", "Canberra Girls Grammar")), [:dnp, 0]
          Eq @sr.result_for_school(School.new("Kambala", "Kambala")), [:dnp, 0]
          Eq @sr.result_for_school(School.new("Kincoppal", "Kincoppal Rose Bay")), [:dnp, 0]
          Eq @sr.result_for_school(School.new("MLC", "MLC Sydney")), [:dnp, 0]
          Eq @sr.result_for_school(School.new("Monte", "Monte Sant' Angelo")), [:dnp, 0]
          Eq @sr.result_for_school(School.new("Armidale", "PLC Armidale")), [:dnp, 0]
          Eq @sr.result_for_school(School.new("Roseville", "Roseville College")), [:dnp, 0]
          Eq @sr.result_for_school(School.new("Santa", "Santa Sabina College")), [:dnp, 0]
          Eq @sr.result_for_school(School.new("SCEGGS", "SCEGGS Darlinghurst")), [:dnp, 0]
          Eq @sr.result_for_school(School.new("StCatherines", "St Catherine's")), [:dnp, 0]
          Eq @sr.result_for_school(School.new("StClares", "St Clare's")), [:dnp, 0]
          Eq @sr.result_for_school(School.new("StVincents", "St Vincent's")), [:dnp, 0]
          Eq @sr.result_for_school(School.new("Tangara", "Tangara")), [:dnp, 0]
          Eq @sr.result_for_school(School.new("Tara", "Tara")), [:dnp, 0]
          Eq @sr.result_for_school(School.new("Wenona", "Wenona")), [:dnp, 0]
        end
        D "programmatic outcomes (check consistency with places and participants)" do
          @places.each_place do |pl, sc|
            Eq @sr.result_for_school(sc), [pl, @f.points_for_place(pl)]
          end
          @participants.participants.each do |sc|
            next if @places.include?(sc)
            Eq @sr.result_for_school(sc), [:p, @f.points_for_participation]
          end
          @participants.nonparticipants.each do |sc|
            Eq @sr.result_for_school(sc), [:dnp, 0]
          end
        end
        D "error on unknown school" do
          E { @sr.result_for_school(School.new("Foo", "Bar")) }
          Mt Whitestone.exception.message, /school does not exist/i
        end
      end  # D "'result_for_school' -> result (1..5,:p,:dnp) and points"
      D "points_for_school -> number of points" do
          Eq @sr.points_for_school(School.new("Frensham", "Frensham")), 30
          Eq @sr.points_for_school(School.new("Danebank", "Danebank")), 25
          Eq @sr.points_for_school(School.new("PLCS", "PLC Sydney")), 20
          Eq @sr.points_for_school(School.new("Kirribilli", "Loreto Kirribilli")), 15
          Eq @sr.points_for_school(School.new("Normanhurst", "Loreto Normanhurst")), 10
          Eq @sr.points_for_school(School.new("Queenwood", "Queenwood")), 5
          Eq @sr.points_for_school(School.new("Ravenswood", "Ravenswood")), 5
          Eq @sr.points_for_school(School.new("Meriden", "Meriden")), 5
          Eq @sr.points_for_school(School.new("OLMC", "Our Lady of Mercy College")), 5
          Eq @sr.points_for_school(School.new("Pymble", "Pymble Ladies College")), 5
          Eq @sr.points_for_school(School.new("Abbotsleigh", "Abbotsleigh")), 0
          Eq @sr.points_for_school(School.new("Ascham", "Ascham")), 0
          # etc
          Eq @sr.points_for_school(School.new("Tangara", "Tangara")), 0
          Eq @sr.points_for_school(School.new("Tara", "Tara")), 0
          Eq @sr.points_for_school(School.new("Wenona", "Wenona")), 0
          E { @sr.points_for_school(School.new("Foo", "Bar")) }
          Mt Whitestone.exception.message, /school does not exist/i
      end
      D "calculate the total points awarded in this section ('total_points')" do
        Eq @sr.total_points, 125
      end
      D "tie?" do
        F @sr.tie?
      end
      D "places() yields position, school, points awarded" do
        # "1. Frensham 2. Danebank 3. PLCS 4. Kirribilli 5. Normanhurst"
        values = [ [1, School.new("Frensham", "Frensham"), 30],
                   [2, School.new("Danebank", "Danebank"), 25],
                   [3, School.new("PLCS", "PLC Sydney"), 20],
                   [4, School.new("Kirribilli", "Loreto Kirribilli"), 15],
                   [5, School.new("Normanhurst", "Loreto Normanhurst"), 10] ]
        @sr.places do |pos, sch, pts|
          expected_value = values.shift
          Eq pos, expected_value[0]
          Eq sch, expected_value[1]
          Eq pts, expected_value[2]
        end
        T values.empty?
      end
      D "{,non,strict_}participants() delegate appropriately" do
        Eq @sr.participants, @participants.participants
        Eq @sr.nonparticipants, @participants.nonparticipants
        Eq @sr.strict_participants, @participants.strict_participants
      end
    end  # "Broad test of a specific instance"

    D "Various other tests of above functionality" do
      # ...
    end
  end  # D "SectionResult"

  D "Results" do
  end  # D "Results"

end  # D "Results"
