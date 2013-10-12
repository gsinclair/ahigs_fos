# Test DebatingResults

D "Load debating results file" do
  @f = FestivalInfo.new(AhigsFosTest::DIRECTORIES_YAML, "2013")
  Eq @f.debating_points_for(:participation), 3
end
