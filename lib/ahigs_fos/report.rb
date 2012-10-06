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

  # ====================================================================== #

  class Report::Report
    WRITE_TO_FILE = false
    def write
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
      directory = @festival_info.dirs.current_year_reports_directory
      timestamp = Time.now.to_i
      path = directory + "#{timestamp}.txt"
      if WRITE_TO_FILE
        path.open('w') do |f|
          f.puts @out.string
        end
        STDERR.puts "Wrote file: #{path}"
      end
    end
    def header()     Report::Header.new(@results, @festival_info).report end
    def status()     Report::Status.new(@results, @festival_info).report end
    def summary()   Report::Summary.new(@results, @festival_info).report end
    def sections() Report::Sections.new(@results, @festival_info).report end
    def schools()   Report::Schools.new(@results, @festival_info).report end
    def footer()     Report::Footer.new(@results, @festival_info).report end
  end  # class Report::Report

  # ====================================================================== #

  class Report::Header #< Report::Base
    def report
      nl
      pr "AHIGS Festival of Speech #{@festival_info.year} score report"
      nl
      pr timestamp
      string
    end
  end  # class Report::Header

  # ====================================================================== #

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

  # ====================================================================== #

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
      @results.all_schools_by_total_desc do |sch, jnr, snr, tot|
        label = sch.abbreviation
        line  = _fmt_school_label(label) + _fmt_table(jnr, snr, tot)
        pr line.indent(2)
      end
      # @festival_info.schools_list.each do |sch|
      #   label = sch.abbreviation
      #   jnr   = @results.points_for_school(sch, :junior)
      #   snr   = @results.points_for_school(sch, :senior)
      #   tot   = jnr + snr
      #   line  = _fmt_school_label(label) + _fmt_table(jnr, snr, tot)
      #   pr line.indent(2)
      # end
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

  # ====================================================================== #

  class Report::Sections
    def report
      pr heading("Sections")
      [:junior, :senior].each do |division|
        @festival_info.sections(division).each do |section|
          results = @results.for_section(section)
          next if results.nil?
          nl
          pr "  Section: #{_upcase(section)}"
          pr "  Places:"
          results.places do |pos, school, pts|
            pr "    #{pos}. #{school.abbreviation} (#{pts})"
          end
          pr "  Participants (#{@festival_info.points_for_participation}):"
          pr _wrap(results.participants, 76).indent(4)
          pr "  Non-participants:"
          pr _wrap(results.nonparticipants, 76).indent(4)
        end
      end
      string
    end
    # Change the string, up to and not including a bracket, to upper case.
    def _upcase(string)
      string.split.map { |word|
        if word.start_with? '('
          word
        else
          word.upcase
        end
      }.join(' ')
    end
    def _wrap(schools, limit)
      schools = schools.map { |sch| sch.abbreviation }.sort_by { |str| str.downcase }
      lines = []
      lines << schools.shift.dup
      loop do
        if schools.empty?
          return lines.join("\n")
        end
        if lines.last.length + 1 + schools.first.size <= limit
          lines.last << " " << schools.shift.dup
        else
          lines << schools.shift.dup
        end
      end
    end
  end  # class Report::Sections

  # ====================================================================== #

  class Report::Schools
    def report
      pr heading("Schools")
      @festival_info.schools_list.sort_by { |s| s.name }.each do |school|
        nl
        report_school(school)
      end
      string
    end
    private
    def report_school(school)
      pr _school_name_and_points(school).indent(2)
      pr _report_sections(school, :junior).indent(4)
      pr _report_sections(school, :senior).indent(4)
    end
    def _school_name_and_points(school)
      line = school.name.ljust(27)
      jnr  = @results.points_for_school(school, :junior)
      snr  = @results.points_for_school(school, :senior)
      tot  = jnr + snr
      line << _fmt_points(jnr, snr, tot)
      line
    end
    def _fmt_points(jnr, snr, tot)
      "(J: #{jnr}  S: #{snr}  T: #{tot})"
    end
    def _report_sections(school, division)
      out = StringIO.new
      out.puts _division_heading(division)
      @festival_info.sections(division).each do |section|
        line = _fmt_section_name(section)
        section_result = @results.for_section(section)
        if section_result.nil?
          line << " -        [not yet available]"
        else
          result, points = section_result.result_for_school(school)
          line << _fmt_results(result, points)
        end
        out.puts line.indent(2)
      end
      out.string
    end
    def _division_heading(division)
      case division
      when :junior then "Junior"
      when :senior then "Senior"
      end
    end
    def _fmt_section_name(section)
      section =
        if idx = section.index('(')
          section[0...idx].strip
        elsif section.start_with? "Religious"
          "Religious and ..."
        else
          section
        end
      section.ljust(23)
    end
    def _fmt_results(result, points)
      desc =
        case result
        when Integer then "#{_ordinal(result)} place"
        when Symbol  then "#{result}"
        else
          Err.invalid_section_result(result)
        end
      "#{points.to_s.rjust(2)} points (#{desc})"
    end
    def _ordinal(n)
      case n
      when 1 then "1st"
      when 2 then "2nd"
      when 3 then "3rd"
      when 4 then "4th"
      when 5 then "5th"
      else
        Err.invalid_place(n)
      end
    end
  end  # class Report::Schools

  # ====================================================================== #

  class Report::Footer
    def report
      pr ("=" * 80)
      nl
      pr timestamp
      string
    end
  end  # class Report::Footer

end  # module AhigsFos
