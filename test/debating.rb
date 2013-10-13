
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
    	N! @dr
    end
	end
end

