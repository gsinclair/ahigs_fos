
module AhigsFos
	# DebatingResults contains a hash:
	#   { :Round1 => DebatingRound, :Round2A => DebatingRound, ... }
	# It is expected that it will be created via DebatingResults.from_results_data(hash)
	# and that the main methods called will be:
	#   results_for_school(Monte) -> [ [:p,3], [:r1,2], [:r2a,2], [:qf,3], [:sf,5] ]
	#                                # note this implies Monte made it to the grand final but didn't win
	#   results_for_school(OLMC)  -> [ [:p,3], [:r2b,2], [:qf,3] ]
	#                                # note OLMC lost Round 1 but won Round 2B and drew the wildcard to enter the QF
	#   points_for_school(Monte)  -> 15
	#   points_for_school(OLMC)   -> 8
	#   participating_schools     -> [...]        (perhaps, if needed)
  #
  # Finally, it is important that we can check the correctness of the debating results data.
  # That is, the winners and losers exactly match the schools registered in each round;
  # the winners from each round proceed to the appropriate next round, that Rounds 2A and 2B
  # are handled correctly; that wildcards work.
  # 
  # This is done with DebatingResults#check_validity.
	class DebatingResults
    ROUNDS = [:Round1, :Round2A, :Round2B, :QuarterFinal, :SemiFinal, :GrandFinal]
    ABBREV = {:Round1 => :r1, :Round2A => :r2a, :Round2B => :r2b,
              :QuarterFinal => :qf, :SemiFinal => :sf, :GrandFinal => :gf }

		# data: hash containing 'Round1', 'Round2', etc. from debating_results.yaml file.
		def DebatingResults.from_results_data(data, festival_info)
			x = ROUNDS.graph { |round|
				[round, DebatingRound.from_hash(data[round.to_s], festival_info)]
			}
			DebatingResults.new(x, festival_info)
		end

    # rounds: { :Round1 => DebatingRound, :Round2A => DebatingRound, ... }
    def initialize(rounds, festival_info)
    	@results = rounds
    	@festival_info = festival_info
    end

    def results_for_school(school)
      school_results = []
      if @results[:Round1].schools.include? school
        school_results << [:p, points_for_participation]
      end
      each_round do |name, result|
        if result.wins.include? school
          school_results << [ABBREV[name], points_for_round(name)]
        end        	
      end
      school_results
    end

    def points_for_school(school)
    	results_for_school(school).map { |x| x[1] }.sum
    end

    def round(name)
      Err.argument(DebatingResults, :round, name) unless ROUNDS.include? name
      @results[name]
    end

    # Checks that all the data is as it should be: winners, losers, pairs match schools
    # listed for each round; winners progress to next round; wilcards; etc.
    # Returns a list of errors (strings), hopefully empty.
    def validation_errors
      errors = []
      check_schools_consistency_in_each_round(errors)
      check_legitimate_progress_through_rounds(errors)
      check_wildcards(errors)
      errors
    end

    private
    
    def points_for_participation
    	@festival_info.debating_points_for(:participation)
    end

    def points_for_round(round)
    	@festival_info.debating_points_for(round)
    end

    # Yields the name and results for each round (e.g. :QuarterFinal, <DebatingRound>)
    def each_round
      ROUNDS.each do |r|
        yield [r, @results[r]]
      end
    end

    def check_schools_consistency_in_each_round(errors)
      each_round do |name, results|
        unless results.schools == (results.wins + results.losses)
          errors << "#{name}: schools doesn't match wins and losses"
        end
        unless results.schools == results.pairs.to_a.flatten.to_set
          errors << "#{name}: schools doesn't match result pairs"
        end
        unless results.wins.intersection(results.losses).empty?
          errors << "#{name}: at least one school has both won and lost"
        end
        wildcard = results.wildcard
        if wildcard
          wc_school, added_or_removed = wildcard
          case added_or_removed
          when :added
            unless results.schools.include? wc_school
              errors << "#{name}: wildcard school #{school.abbreviation} should be included in schools list"
            end
          when :removed
            if results.schools.include? wc_school
              errors << "#{name}: wildcard school #{school.abbreviation} ('removed') should NOT be included in schools list"
            end
          end
        end
      end
    end

    def check_legitimate_progress_through_rounds(errors)
      check_progress_from_one_round_to_next(:Round1, :win, :Round2A, errors)
      check_progress_from_one_round_to_next(:Round1, :lose, :Round2B, errors)
      check_progress_from_one_round_to_next(:Round2A, :win, :QuarterFinal, errors)
      check_progress_from_one_round_to_next(:QuarterFinal, :win, :SemiFinal, errors)
      check_progress_from_one_round_to_next(:SemiFinal, :win, :GrandFinal, errors)
    end

    # Checks the winners (or losers, as appropriate) from r1 make up the schools in r2,
    # modulo any wildcard.
    def check_progress_from_one_round_to_next(r1, win_or_lose, r2, errors)
      _r1, _r2 = r1, r2              # preserve the round _names_
      r1, r2 = round(r1), round(r2)
      # winners from first round should be the participants in the second round, modulo any wildcards
      r2_expected =
        case win_or_lose
        when :win then r1.wins
        when :lose then r1.losses
        end
      r2_expected, wc_sch =
        if (wc = r2.wildcard)
          wc_sch, action = wc
          case action
          when :added   then [r2_expected + Set[wc_sch], wc_sch]
          when :removed then [r2_expected - Set[wc_sch], wc_sch]
          end
        else
          [r2_expected, "nil"]
        end
      unless r2.schools == r2_expected
        errors << "#{_r2}: schools should be winners from #{_r1} +/- wildcard (#{wc_sch})"
      end
    end

    def check_blah_blah(errors)
      with_errors(errors) do |e|
        e.unless (qwfc[1] == :added),  "Quarter final wildcard must be an _addition_"
      end
    end

    # Compiles errors with an efficient API.
    class ErrorCompiler
      def initialize(errors)
        @errors = errors
      end
      def unless(positive_condition, message)
        unless positive_condition
          @errors << message
          yield if block_given?
        end
      end
      def <<(msg)
        @errors << msg
      end
    end

    def with_errors(errors)
      yield ErrorCompiler.new(errors)
      errors
    end

    # Checks specific things about wildcards.  General wildcard checks are done elsewhere.
    def check_wildcards(errors)
      # The quarter-final wildcard, if any, must be a Round 2B winner.
      # (And it must be an addition.)
      if (qfwc = round(:QuarterFinal).wildcard)
        unless qfwc[1] == :added
          errors << "Quarter final wildcard must be an _addition_"
        end
        unless round(:Round2B).wins.include? qfwc[0]
          errors << "Quarter final wildcard must be a Round 2B winner"
        end
      end
      # The Round 2A wildcard, if any, must be a Round 1 loser.  (Must be :added)
      # If it exists, it must also exist in Round 2B.
      if (r2awc = round(:Round2A).wildcard)
        unless r2awc[1] == :added
          errors << "Round 2A wildcard must be an _addition_"
        end
        pp round(:Round1).losses.map { |x| x.abbreviation }
        pp round(:Round2A).wildcard
        unless round(:Round1).losses.include? r2awc[0]
          errors << "Round 2A wildcard must be a Round 1 loser"
        end
      end
      # The Round 2B wildcard, if any, must be the same as Round 2A, but :removed.
      if (r2bwc = round(:Round2B).wildcard)
        unless r2bwc[1] == :removed
          errors << "Round 2B wildcard must be a _removal_"
        end
        if r2awc
          unless r2awc[0] == r2bwc[0]
            errors << "Round2B wildcard must be same school as Round2A wildcard"
          end
        else
          errors << "Round2B wildcard exists but Round2A wildcard does not"
        end
      end
    end  # check_wildcards
	end  # class DebatingResults

	# Contains the results of one round of debating.
	#   schools:  the set of schools that competed in this round
	#   wildcard: nil, or (for example) a tuple like [Frensham, :added] or [OLMC, :deleted]
	#             (a school can be added or deleted as a result of a wildcard)
	#   pairs:    the set of pairings, e.g. Set{ [Monte, Armidale], [MLC, Tara], ... }
	#   wins:     the set of winning schools
	#   losses:   the set of losing schools
	class DebatingRound < Struct.new(:schools, :wildcard, :pairs, :wins, :losses)
		def DebatingRound.from_hash(data, festival_info)
			schools_str = data["Schools"]
			wildcard_str = data["Wildcard"]
			results_str_arr = data["Results"]
			schools_list = schools_str.strip.split(/\s+/).map { |s| festival_info.school(s) }
      schools = schools_list.to_set
      # Wildcard string is like "Danebank (added)" or "OLMC (removed)"
      wildcard =
        if wildcard_str.nil?
          nil
        elsif wildcard_str.strip =~ /(\w+) \((added|removed)\)/
          [festival_info.school($1), $2.intern]
        else
          Err.invalid_value('Debating -> wildcard', wildcard_str, 'Frensham (added/removed)')
        end
      wins = Set.new
      losses = Set.new
      pairs = Set.new
      results_str_arr.each do |result_str|
      	# result_str is something like "SCEGGS  def  Tangara"
      	if result_str =~ /(\w+)\s+def\s+(\w+)/
          winner = festival_info.school($1)
          loser  = festival_info.school($2)
          wins << winner
          losses << loser
          pairs << [winner, loser]
      	else
      		Err.invalid_debating_result(result_str)
      	end
      end
      DebatingRound.new(schools, wildcard, pairs, wins, losses)
		end
	end
end