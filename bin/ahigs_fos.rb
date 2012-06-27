# app/comp-scorer.rb -- the main file

require 'ap'
require 'pp'
require 'yaml'
require 'pathname'

require 'debuglog'

require 'ahigs_fos'

module AhigsFos
  module Constants
    DIRECTORIES_CONFIG_FILE_NAME = "directories.yaml"
  end

  # What does the app do when it is run?
  # * Read the configuration file (create a Configuration object)
  # * Process the results from the relevant YAML file(s) (Results object)
  # * Produce and write a report (Report object)
  class App
    def initialize
    end
    def run
      festival_info = FestivalInfo.new
      #pp festival_info
      puts "\n\n"
      results = Results.new(festival_info)
      puts "\n\n"
      report = Report::Report.new(results, festival_info)
      report.write(Dirs.instance.current_year_reports_directory)
      puts "\n\n"
      puts report.string
    end
  end
end

AhigsFos::App.new.run
