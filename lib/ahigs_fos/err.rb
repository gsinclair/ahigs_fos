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

  def Err.invalid_abbreviation(abbr)
    raise AhigsFos::ConfigurationError, "Invalid school abbreviation: #{abbr.inspect}"
  end

  def Err.invalid_place_string(msg, str)
    message = "Invalid place string: #{str.inspect} (#{msg})"
    raise AhigsFos::ResultsError, message
  end

  def Err.nonexistent_school(string)
    raise AhigsFos::ConfigurationError, "School does not exist: #{string.inspect}"
  end

  def Err.inconsistent_total_points_for_section_result(section, total1, total2)
    message =  "Total points for section #{section.inspect} is different depending\n"
    message += "on the way it is calculated: #{total1} vs #{total2}."
    raise AhigsFos::ResultsError, message
  end
end; end
