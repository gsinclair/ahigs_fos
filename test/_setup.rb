require 'ahigs_fos'
include AhigsFos

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
    @s.abbotsleigh = sch("Abbotsleigh")
    @s.ascham = sch("Ascham")
    @s.brigidine = sch("Brigidine")
    @s.calrossy = sch("Calrossy")
    @s.canberra = sch("Canberra", "Canberra Girls Grammar")
    @s.danebank = sch("Danebank")
    @s.frensham = sch("Frensham")
    @s.kambala = sch("Kambala")
    @s.kincoppal = sch("Kincoppal", "Kincoppal Rose Bay")
    @s.kirribilli = sch("Kirribilli", "Loreto Kirribilli")
    @s.normanhurst = sch("Normanhurst", "Loreto Normanhurst")
    @s.meriden = sch("Meriden")
    @s.mlc = sch("MLC", "MLC Sydney")
    @s.monte = sch("Monte", "Monte Sant' Angelo")
    @s.olmc = sch("OLMC", "Our Lady of Mercy College")
    @s.plcs = sch("PLCS", "PLC Sydney")
    @s.armidale = sch("Armidale", "PLC Armidale")
    @s.pymble = sch("Pymble", "Pymble Ladies College")
    @s.queenwood = sch("Queenwood")
    @s.ravenswood = sch("Ravenswood")
    @s.roseville = sch("Roseville", "Roseville College")
    @s.santa = sch("Santa", "Santa Sabina College")
    @s.sceggs = sch("SCEGGS", "SCEGGS Darlinghurst")
    @s.stcatherines = sch("StCatherines", "St Catherine's")
    @s.stclares = sch("StClares", "St Clare's")
    @s.stvincents = sch("StVincents", "St Vincent's")
    @s.tangara = sch("Tangara")
    @s.tara = sch("Tara")
    @s.stpatricks = sch("StPatricks", "St Patrick's")
    @s.wenona = sch("Wenona")
    @s.freeze
    @s
  end
end


__END__


The following text is a convenience for copying and pasting.

s.frensham
s.abbotsleigh
s.ascham
s.brigidine
s.calrossy
s.canberra
s.danebank
s.frensham
s.kambala
s.kincoppal
s.kirribilli
s.normanhurst
s.meriden
s.mlc
s.monte
s.olmc
s.plcs
s.armidale
s.pymble
s.queenwood
s.ravenswood
s.roseville
s.santa
s.sceggs
s.stcatherines
s.stclares
s.stvincents
s.tangara
s.tara
s.wenona
