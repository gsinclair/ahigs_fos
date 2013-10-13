
D "Debating" do
	D "Configuration (2013 test data)" do
	  @f = FestivalInfo.new(AhigsFosTest::DIRECTORIES_YAML, "2013")
	  D "Sections" do
	  	T @f.debating_included?
	  	T @f.sections(:junior).include?("Debating (Junior)")
	  	T @f.sections(:senior).include?("Debating (Senior)")
	  end
	  D "Points" do
	  	Eq @f.debating_points_for(:participation), 3
	  	Eq @f.debating_points_for(:Round2B), 2
	  	Eq @f.debating_points_for(:SemiFinal), 5
	  end
	end

  D "DebatingResults" do
    path = @f.dirs.current_year_data_directory + "debating_results.yaml"
    data = YAML.load(path.read)
    Eq data.keys.sort, ["Debating (Junior)", "Debating (Senior)"]
    @dr = DebatingResults.from_results_data(data["Debating (Junior)"], @f)
    D "Results data loaded" do
    	Ko @dr, DebatingResults
    	Ko @dr.round(:Round1), DebatingRound
    	Ko @dr.round(:Round2A), DebatingRound
    	Ko @dr.round(:Round2B), DebatingRound
    	Ko @dr.round(:QuarterFinal), DebatingRound
    	Ko @dr.round(:SemiFinal), DebatingRound
    	Ko @dr.round(:GrandFinal), DebatingRound
    	E(AhigsFos::ArgumentError) { @dr.round(:non_existent) }
    end
    D "Details of Round 1" do
      r1 = @dr.round(:Round1)
      Eq r1.schools.size, 26
      T  r1.schools.include? s.olmc
      T  r1.schools.include? s.ravenswood
      T  r1.schools.include? s.wenona
      Eq r1.pairs.size, 13
      Eq r1.wins.size, 13
      Eq r1.losses.size, 13
      T  r1.pairs.include? [s.wenona, s.tangara]
      T  r1.pairs.include? [s.abbotsleigh, s.danebank]
      T  r1.pairs.include? [s.plcs, s.ravenswood]
    end
    D "Details of Quarter Final" do
      qf = @dr.round(:QuarterFinal)
      Eq qf.schools, Set[s.canberra, s.santa, s.kincoppal, s.stvincents, s.pymble,
                         s.monte, s.plcs, s.frensham]
      Eq qf.wins,    Set[s.kincoppal, s.frensham, s.pymble, s.stvincents]
      Eq qf.losses,  Set[s.monte, s.plcs, s.canberra, s.santa]
      Eq qf.pairs,   Set[[s.kincoppal, s.monte], [s.frensham, s.plcs],
                         [s.pymble, s.canberra], [s.stvincents, s.santa]]
      Eq qf.wildcard, [:not_yet_implemented]
    end
    D "Basic details of other rounds" do
      r2a = @dr.round(:Round2A)
      Eq r2a.schools.size, 14
      Eq r2a.pairs.size, 7
      Eq r2a.wins.size, 7
      Eq r2a.losses.size, 7
      gf  = @dr.round(:GrandFinal)
      Eq gf.schools, Set[s.kincoppal, s.stvincents]
      Eq gf.wins, Set[s.kincoppal]
      Eq gf.losses, Set[s.stvincents]
    end
    D "Calculation of school results and points" do
      D "Various participating schools" do
        r = @dr.results_for_school(s.kincoppal)
        Eq r, [[:p,3], [:r1,2], [:r2a,2], [:qf,3], [:sf,5], [:gf,5]]
        r = @dr.results_for_school(s.ravenswood)
        Eq r, [[:p,3]]
        r = @dr.results_for_school(s.tara)
        Eq r, [[:p,3], [:r2b,2]]
        r = @dr.results_for_school(s.frensham)
        Eq r, [[:p,3], [:r2b,2], [:qf,3]]
        Eq @dr.points_for_school(s.kincoppal), 20
        Eq @dr.points_for_school(s.ravenswood), 3
        Eq @dr.points_for_school(s.tara), 5
        Eq @dr.points_for_school(s.frensham), 8
      end
      D "Non-participating schools" do
        Eq @dr.results_for_school(s.roseville), []
        Eq @dr.points_for_school(s.roseville),  0
      end
    end
  end
end

