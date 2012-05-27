# app/comp-scorer.rb -- the main file

require 'ap'
require 'pp'
require 'yaml'
require 'pathname'

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
      puts "\n\n\n"
      pp festival_info
      puts "\n\n\n"
      results = Results.new(festival_info)
      report = Report.new(results)
      report.write(Dirs.instance.current_year_reports_directory)
    end
  end
end

AhigsFos::App.new.run
