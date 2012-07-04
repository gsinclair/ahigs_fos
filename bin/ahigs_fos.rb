# app/comp-scorer.rb -- the main file

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
      festival_info = FestivalInfo.new(Constants::DIRECTORIES_CONFIG_FILE_NAME)
      results = Results.new(festival_info)
      report = Report::Report.new(results, festival_info)
      report.write
      puts report.string
    end
  end
end

AhigsFos::App.new.run
