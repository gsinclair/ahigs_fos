module AhigsFos

  module Report
    class Base; end
    class Report < Base; end
    class Header < Base; end
    class Status < Base; end
    class Summary < Base; end
    class Sections < Base; end
    class Schools < Base; end
    class Footer < Base; end
  end

  class Report::Base
    def initialize(results, festival_info)
      puts "Report::Base.initialize called (#{self.class})"
      @results, @festival_info = results, festival_info
      @out = StringIO.new
      @written = false
    end
    def nl(n=1)
      n.times do @out.puts end
    end
    def pr(str)
      @out.puts str
    end
    def heading(str)
      # output =========== S U M M A R Y ========= or whatever
      "*** heading: #{str}"   # for now
    end
    def string
      @out.string
    end
    def timestamp
      t = Time.now
      h = t.hour % 12
      Time.now.strftime("%d %b %Y (#{h}.%M%P)")  # 20 May 2012 (1.37pm)
    end
  end  # class Report::Base

  class Report::Report
#    def initialize(r, fi)
#      puts "Report::Report.initialize called"
#    end
    def write(directory)
      if @out.nil?
        puts "@out is nil!"
      end
      pr header
      nl
      pr status
      nl 2
      pr summary
      nl 2
      pr sections
      nl 2
      pr schools
      nl
      pr footer
      timestamp = Time.now.to_i
      path = directory + "#{timestamp}.txt"
      path.open('w') do |f|
        f.puts @out.string
      end
      puts "Wrote file: #{path}"
    end
    def header()     Report::Header.new(@results, @festival_info).report end
    def status()     Report::Status.new(@results, @festival_info).report end
    def summary()   Report::Summary.new(@results, @festival_info).report end
    def sections() Report::Sections.new(@results, @festival_info).report end
    def schools()   Report::Schools.new(@results, @festival_info).report end
    def footer()     Report::Footer.new(@results, @festival_info).report end
  end  # class Report::Report

  class Report::Header #< Report::Base
    # No need for initialize, I hope.
    def report
      nl
      pr "AHIGS Festival of Speech #{@festival_info.year} score report"
      nl
      pr timestamp
      string
    end
  end  # class Report::Header

  class Report::Status
    def report
      pr "Status:"
      nl
      report_status_for_sections(@festival_info.sections(:junior))
      nl
      report_status_for_sections(@festival_info.sections(:senior))
      string
    end
    private
    def report_status_for_sections(sections)
      sections.each do |section|
        report_status(section)
      end
    end
    def report_status(section)
      line = section.ljust(33) + " : "
      results = @results.for_section(section)
      if results.nil?
        line += "waiting"
      else
        pts = results.total_points
        line += "completed (#{pts} points total)"
        if results.tie?
          line += " TIE"
        end
      end
      pr line.indent(2)
    end
  end  # class Report::Status

  class Report::Summary
    def report
      pr "summary..."
      string
    end
  end  # class Report::Summary

  class Report::Sections
    def report
      pr "sections..."
      string
    end
  end  # class Report::Sections

  class Report::Schools
    def report
      pr "schools..."
      string
    end
  end  # class Report::Schools

  class Report::Footer
    def report
      pr ("=" * 78)
      nl
      pr timestamp
      string
    end
  end  # class Report::Footer

end  # module AhigsFos
