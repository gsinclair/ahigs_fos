include AhigsFos

D "Configuration" do
  D "FestivalInfo" do
  end
  D "School" do
    @s = School.new("Pittwater", "Pittwater High School")
    D "Basics" do
      Eq @s.abbreviation, "Pittwater"
      Eq @s.name, "Pittwater High School"
    end
    D "Object is frozen" do
      E { @s.instance_variable_set :@name, "foo" }
    end
  end
  D "Dirs" do
    @d = Dirs.new(AhigsFosTest::DIRECTORIES_YAML)
    Eq @d.current_year_data_directory, Pathname.new("test/_data/data/2012")
    Eq @d.current_year_reports_directory, Pathname.new("test/_data/reports/2012")
  end
end
