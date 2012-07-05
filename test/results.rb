
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
      D "list the schools that placed ('list')" do
        Eq @p.list, [School.new("Frensham", "Frensham"),
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
        # list the schools that placed
        Eq @p.list, [School.new("Calrossy", "Calrossy"),
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
      end
    end
  end  # D "Participants"

end  # D "Results (building blocks)"


D "Results" do
  D "SectionResult" do
  end  # D "SectionResult"

  D "Results" do
  end  # D "Results"
end  # D "Results"
