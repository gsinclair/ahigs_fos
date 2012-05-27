# app/comp-scorer/err.rb -- handles all error messages

module AhigsFos
  class ConfigurationError < StandardError; end
  class ResultsError < StandardError; end
end

module AhigsFos; class Err
  def Err.assert(condition)
    unless condition
      raise "Assertion failed"
    end
  end

  def Err.no_configuration_file
    filename = Constants::BASIC_CONFIG_FILE_NAME
    msg = %{
      Cannot read basic configuration file #{filename}. It should contain
      directory information like so:
     
        directories:
          data: ~/speech_comp/data
          reports: ~/tmp/reports
    }.trim
    raise AhigsFos::ConfigurationError, msg
  end

  def Err.no_directory_information(args)
    assert args.key?(:label)
    msg = "No directory information provided: #{args[:label]}"
    raise AhigsFos::ConfigurationError, msg
  end

  def Err.invalid_section(msg)
    raise AhigsFos::ResultsError, "Invalid Section: #{msg}"
  end

  def Err.invalid_results_data(msg)
    raise AhigsFos::ResultsError, msg
  end
end; end
