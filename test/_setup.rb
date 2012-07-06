require 'ahigs_fos'

module AhigsFosTest
  DIRECTORIES_YAML = "test/_data/directories.yaml"
end  # module AhigsFosTest

def sch(abbr, name=nil)
  AhigsFos::School.new(abbr, name || abbr)
end

def s
  if @s
    @s
  else
    @s = OpenStruct.new
    @s.frensham = sch("Frensham")
    @s
  end
end
