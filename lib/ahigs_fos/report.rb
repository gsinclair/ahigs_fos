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
      exploded = str.upcase.split('').join(' ')
      len = 80 - exploded.length
      left = len / 2
      right = len - left
      left, right = left-1, right-1
      ("=" * left) + " #{exploded} " + ("=" * right)
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
      pr heading("Summary")
      nl
      table
      nl
      junior
      nl
      senior
      nl
      total
      string
    end
    private
    def table
      header = _fmt_school_label("") + "Junior    Senior    Total"
      pr header.indent(2)
      @festival_info.schools_list.each do |sch|
        label = sch.abbreviation
        jnr   = @results.points_for_school(sch, :junior)
        snr   = @results.points_for_school(sch, :senior)
        tot   = jnr + snr
        line  = _fmt_school_label(label) + _fmt_table(jnr, snr, tot)
        pr line.indent(2)
      end
    end
    def _fmt_table(jnr, snr, tot)
      jnr, snr, tot = [jnr,snr,tot].map { |n| n.zero? && '-' || n }
      [jnr,snr].map { |a|
        a.to_s.rjust(4) + "      "
      }.join + tot.to_s.rjust(5)
    end
    def junior
      pr "  JUNIOR"
      _top_five_schools(:junior)
    end
    def senior
      pr "  SENIOR"
      _top_five_schools(:senior)
    end
    def total
      pr "  TOTAL"
      _top_five_schools(:all)
    end
    def _top_five_schools(division)
      @results.top_five_schools(division) do |pos, school, points|
        line = _fmt_jnr_sen_tot(pos, school.abbreviation, points)
        pr line.indent(4)
      end
    end
    def _fmt_school_label(label)
      width = @festival_info.max_abbreviation_length + 3
      label.ljust(width)
    end
    def _fmt_jnr_sen_tot(position, schoolname, points)
      points_str = points.to_s.rjust(6) + " points"
      "#{position}. #{_fmt_school_label(schoolname)} #{points_str}"
    end
  end  # class Report::Summary

  class Report::Sections
    def report
      pr heading("Sections")
      string
    end
  end  # class Report::Sections

  class Report::Schools
    def report
      pr heading("Schools")
      string
    end
  end  # class Report::Schools

  class Report::Footer
    def report
      pr ("=" * 80)
      nl
      pr timestamp
      string
    end
  end  # class Report::Footer

end  # module AhigsFos
