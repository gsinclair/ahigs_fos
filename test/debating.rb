
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

  D "DebatingResults (Junior, correct)" do
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
      Eq r1.wins, Set[s.canberra, s.wenona, s.queenwood, s.santa, s.kincoppal,
                      s.brigidine, s.stvincents, s.mlc, s.pymble, s.abbotsleigh,
                      s.ascham, s.monte, s.plcs]
      Eq r1.losses, Set[s.sceggs, s.tangara, s.meriden, s.frensham, s.kirribilli,
                        s.normanhurst, s.armidale, s.stcatherines, s.olmc,
                        s.danebank, s.stpatricks, s.tara, s.ravenswood]
      T  r1.pairs.include? [s.wenona, s.tangara]
      T  r1.pairs.include? [s.abbotsleigh, s.danebank]
      T  r1.pairs.include? [s.plcs, s.ravenswood]
      N  r1.wildcard
    end
    D "Details of Round 2A" do
      r2a = @dr.round(:Round2A)
      Eq r2a.schools.size, 14
      w = Set[s.canberra, s.santa, s.kincoppal, s.stvincents, s.pymble, s.monte, s.plcs]
      l = Set[s.wenona, s.queenwood, s.brigidine, s.mlc, s.abbotsleigh, s.ascham, s.danebank]
      Eq r2a.schools, (w + l)
      Eq r2a.wins,   w
      Eq r2a.losses, l
      Eq r2a.wildcard, [s.danebank, :added]
    end
    D "Details of Quarter Final" do
      qf = @dr.round(:QuarterFinal)
      Eq qf.schools, Set[s.canberra, s.santa, s.kincoppal, s.stvincents, s.pymble,
                         s.monte, s.plcs, s.frensham]
      Eq qf.wins,    Set[s.kincoppal, s.frensham, s.pymble, s.stvincents]
      Eq qf.losses,  Set[s.monte, s.plcs, s.canberra, s.santa]
      Eq qf.pairs,   Set[[s.kincoppal, s.monte], [s.frensham, s.plcs],
                         [s.pymble, s.canberra], [s.stvincents, s.santa]]
      Eq qf.wildcard, [s.frensham, :added]
    end
    D "Basic details of other rounds" do
      r2a = @dr.round(:Round2A)
      Eq r2a.schools.size, 14
      Eq r2a.pairs.size, 7
      Eq r2a.wins.size, 7
      Eq r2a.losses.size, 7
      Eq r2a.wildcard, [s.danebank, :added]
      r2b = @dr.round(:Round2B)
      Eq r2b.schools.size, 12
      Eq r2b.wildcard, [s.danebank, :removed]
      gf  = @dr.round(:GrandFinal)
      Eq gf.schools, Set[s.kincoppal, s.stvincents]
      Eq gf.wins, Set[s.kincoppal]
      Eq gf.losses, Set[s.stvincents]
      N  gf.wildcard
    end
    D "Calculation of school results and points" do
      D "Various participating schools" do
        r = @dr.result_for_school(s.kincoppal)
        Eq r.outcome, [:p, :Round1, :Round2A, :QuarterFinal, :SemiFinal, :GrandFinal]
        Eq r.points,  20
        r = @dr.result_for_school(s.ravenswood)
        Eq r.outcome, [:p]
        Eq r.points,  3
        r = @dr.result_for_school(s.tara)
        Eq r.outcome, [:p, :Round2B]
        Eq r.points,  5
        r = @dr.result_for_school(s.frensham)
        Eq r.outcome, [:p, :Round2B, :QuarterFinal]
        Eq r.points,  8
      end
      D "Non-participating schools" do
        r = @dr.result_for_school(s.roseville)
        Eq r.outcome, []
        Eq r.points,  0
      end
    end
    D "No validation errors for this data" do
      Eq @dr.validation_errors, []
    end
  end # DebatingResults (Junior, correct)

  D "DebatingResults (Senior, with validation errors)" do
    path = @f.dirs.current_year_data_directory + "debating_results.yaml"
    data = YAML.load(path.read)
    Eq data.keys.sort, ["Debating (Junior)", "Debating (Senior)"]
    @dr = DebatingResults.from_results_data(data["Debating (Senior)"], @f)
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
    D "Validation errors" do
      T true
      Eq @dr.validation_errors,
      ["Round1: schools doesn't match wins and losses",
       "Round1: schools doesn't match result pairs",
       "SemiFinal: schools doesn't match wins and losses",
       "SemiFinal: schools doesn't match result pairs",
       "Round2A: schools should be winners from Round1 +/- wildcard (nil)",
       "QuarterFinal: schools should be winners from Round2A +/- wildcard (Frensham)",
       "SemiFinal: schools should be winners from QuarterFinal +/- wildcard (nil)",
       "Round2B wildcard exists but Round2A wildcard does not"]
    end
  end

  D "Results (including debating)" do
    @f = FestivalInfo.new(AhigsFosTest::DIRECTORIES_YAML, "2013")
    @r = Results.new(@f)
    Ko @r, Results
  end
end # Debating

