D "Configuration" do
  D "School" do
    @s = School.new("Pittwater", "Pittwater High School")
    D "basics" do
      Eq @s.abbreviation, "Pittwater"
      Eq @s.name, "Pittwater High School"
      Eq @s.to_s, "School[Pittwater, Pittwater High School]"
    end
    D "object is frozen" do
      E { @s.instance_variable_set :@name, "foo" }
    end
    D "equality and hash lookup" do
      Eq @s, School.new("Pittwater", "Pittwater High School")
      hash = { @s => 5 }
      Eq hash[@s], 5
    end
  end

  D "Directories" do
    @d = Directories.new(AhigsFosTest::DIRECTORIES_YAML, "2012")
    Eq @d.current_year_data_directory, Pathname.new("test/_data/data/2012")
    Eq @d.current_year_reports_directory, Pathname.new("test/_data/reports/2012")
  end

  D "FestivalInfo" do
    @f = FestivalInfo.new(AhigsFosTest::DIRECTORIES_YAML, "2012")
    D "knows what year it is configured for" do
      Eq @f.year, 2012
    end
    D "can return and query section titles for junior, senior or all" do
      expected_junior = ["Reading (Junior)", "Poetry (Junior)", "Public Speaking (Junior)"]
      expected_senior = ["Reading (Senior)", "Poetry (Senior)", "Public Speaking (Senior)"]
      expected_senior += ["Current Affairs", "Religious and Ethical Questions"]
      Eq @f.sections(:junior), expected_junior
      Eq @f.sections(:senior), expected_senior
      Eq @f.sections(:all), expected_junior + expected_senior
      T  @f.section? "Current Affairs"
      F  @f.section? "Qwyjibo"
    end
    D "has access to a Directories object" do
      Ko @f.dirs, Directories
    end
    D "schools_list and schools_set" do
      list, set = @f.schools_list, @f.schools_set
      Eq list.size, 29
      Eq set.size, 29
      T list.all? { |s| School === s }
      T set.all? { |s| School === s }
      T list.include? School.new("Ascham", "Ascham")
      T set.include? School.new("Ascham", "Ascham")
      T list.include? School.new("Normanhurst", "Loreto Normanhurst")
      T set.include? School.new("Normanhurst", "Loreto Normanhurst")
      T list.include? School.new("Armidale", "PLC Armidale")
      T set.include? School.new("Armidale", "PLC Armidale")
      F list.include? School.new("NSBHS", "North Sydney Boys High School")
      F set.include? School.new("NSBHS", "North Sydney Boys High School")
    end
    D "can look up a school by name or abbreviation ('school')" do
      Eq @f.school("Calrossy"), School.new("Calrossy", "Calrossy")
      Eq @f.school("Monte"), School.new("Monte", "Monte Sant' Angelo")
      Eq @f.school("Monte Sant' Angelo"), School.new("Monte", "Monte Sant' Angelo")
      Eq @f.school("StClares"), School.new("StClares", "St Clare's")
      Eq @f.school("St Clare's"), School.new("StClares", "St Clare's")
      D "nil if school not known" do
        N @f.school("foobar")
      end
      D "generate a list of School objects ('school_list')" do
        list = @f.school_list ['Monte', 'Calrossy', 'Ravenswood', 'Roseville College']
        Eq list, [School.new("Monte", "Monte Sant' Angelo"),
                  School.new("Calrossy", "Calrossy"),
                  School.new("Ravenswood", "Ravenswood"),
                  School.new("Roseville", "Roseville College")]
        D "error if school not known" do
          E { @f.school_list ['Monte', 'Calrossy', 'foobar', 'Roseville'] }
        end
      end
    end
    D "points for place or participation" do
      Eq @f.points_for_place(1), 30
      Eq @f.points_for_place(2), 25
      Eq @f.points_for_place(3), 20
      Eq @f.points_for_place(4), 15
      Eq @f.points_for_place(5), 10
      Eq @f.points_for_participation, 5
    end
  end
end  # D "Configuration"
