module AhigsFos

  class Report
    def initialize(results)
      @results = results
    end
    def write(directory)
      timestamp = Time.now.to_i
      path = directory + "#{timestamp}.txt"
      path.open('w') do |f|
        f.puts "Report... #{Time.now}"
      end
      puts "Wrote file: #{path}"
    end
  end  # class Report

end  # module AhigsFos
