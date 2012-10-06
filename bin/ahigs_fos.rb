# app/comp-scorer.rb -- the main file

require 'ahigs_fos'

module AhigsFos
  module Constants
    DIRECTORIES_CONFIG_FILE_NAME = "directories.yaml"
  end

  # What does the app do when it is run?
  # * Take note of a calendar year passed on the command line
  # * Read the configuration file (create a Configuration object)
  # * Process the results from the relevant YAML file(s) (Results object)
  # * Produce and write a report (Report object)
  class App
    def initialize
    end
    def run
      calyear = get_calendar_year(ARGV)
      festival_info = FestivalInfo.new(Constants::DIRECTORIES_CONFIG_FILE_NAME, calyear)
      results = Results.new(festival_info)
      report = Report::Report.new(results, festival_info)
      report.write
      puts report.string
    end
    private
    def get_calendar_year(args)
      if args.first and args.first =~ /\d\d\d\d/
        args.shift
      else
        Time.now.year.to_s
      end
    end
  end
end

AhigsFos::App.new.run
