
module AhigsFos

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
    def if(positive_condition, message)
      if positive_condition
        @errors << message
        yield if block_given?
      end
    end
    def error(msg)
      @errors << msg
    end
    def <<(msg)
      @errors << msg
    end
    def ErrorCompiler.with_errors(errors)
      yield ErrorCompiler.new(errors)
      errors
    end
  end


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

    def debating?
      true
    end

    def total_points
      45  # to satisfy Report::Status
    end

    def result_for_school(school)
      outcome, points = [], []
      if @results[:Round1].schools.include? school
        outcome << :p
        points  << points_for_participation
      end
      each_round do |name, result|
        if result.wins.include? school
          outcome << ABBREV[name]
          points  << points_for_round(name)
        end        	
      end
      Result.new(outcome, points.sum)
    end

    # Unfortunately we need this to satisfy Results#all_schools_by_total_desc.
    # In other words, this mimics Results#points_for_school, which has a comment saying
    # I'd like to get rid of it in favour of SchoolResults and Leaderboard.
    # It seems that DebatingResults is mimicing both SectionResults and Results, and I don't like it.
    def points_for_school(school)
      result_for_school(school).points
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
      ErrorCompiler.with_errors(errors) do |e|
        check_schools_consistency_in_each_round(e)
        check_legitimate_progress_through_rounds(e)
        check_wildcards(e)
      end
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

    def check_schools_consistency_in_each_round(e)
      each_round do |name, results|
        e.unless (results.schools == (results.wins + results.losses)),
                 "#{name}: schools doesn't match wins and losses"
        e.unless (results.schools == results.pairs.to_a.flatten.to_set),
                 "#{name}: schools doesn't match result pairs"
        e.unless (results.wins.intersection(results.losses).empty?),
                 "#{name}: at least one school has both won and lost"
        wildcard = results.wildcard
        if wildcard
          wc_school, added_or_removed = wildcard
          case added_or_removed
          when :added
            e.unless (results.schools.include? wc_school),
                     "#{name}: wildcard school #{wc_school.abbreviation} should be included in schools list"
          when :removed
            e.if (results.schools.include? wc_school),
                 "#{name}: wildcard school #{wc_school.abbreviation} ('removed') should NOT be included in schools list"
          end
        end
      end
    end

    def check_legitimate_progress_through_rounds(e)
      check_progress_from_one_round_to_next(:Round1, :win, :Round2A, e)
      check_progress_from_one_round_to_next(:Round1, :lose, :Round2B, e)
      check_progress_from_one_round_to_next(:Round2A, :win, :QuarterFinal, e)
      check_progress_from_one_round_to_next(:QuarterFinal, :win, :SemiFinal, e)
      check_progress_from_one_round_to_next(:SemiFinal, :win, :GrandFinal, e)
    end

    # Checks the winners (or losers, as appropriate) from r1 make up the schools in r2,
    # modulo any wildcard.
    def check_progress_from_one_round_to_next(r1, win_or_lose, r2, e)
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
          when :added   then [r2_expected + Set[wc_sch], wc_sch.abbreviation]
          when :removed then [r2_expected - Set[wc_sch], wc_sch.abbreviation]
          end
        else
          [r2_expected, "nil"]
        end
      e.unless (r2.schools == r2_expected),
               "#{_r2}: schools should be winners from #{_r1} +/- wildcard (#{wc_sch})"
    end


    # Checks specific things about wildcards.  General wildcard checks are done elsewhere.
    def check_wildcards(e)
      # The quarter-final wildcard, if any, must be a Round 2B winner.
      # (And it must be an addition.)
      if (qfwc = round(:QuarterFinal).wildcard)
        e.unless (qfwc[1] == :added),
                 "Quarter final wildcard must be an _addition_"
        e.unless (round(:Round2B).wins.include? qfwc[0]),
                 "Quarter final wildcard must be a Round 2B winner"
      end
      # The Round 2A wildcard, if any, must be a Round 1 loser.  (Must be :added)
      # If it exists, it must also exist in Round 2B.
      if (r2awc = round(:Round2A).wildcard)
        e.unless (r2awc[1] == :added),
                 "Round 2A wildcard must be an _addition_"
        e.unless (round(:Round1).losses.include? r2awc[0]),
                 "Round 2A wildcard must be a Round 1 loser"
      end
      # The Round 2B wildcard, if any, must be the same as Round 2A, but :removed.
      if (r2bwc = round(:Round2B).wildcard)
        e.unless (r2bwc[1] == :removed),
                 "Round 2B wildcard must be a _removal_"
        if r2awc
          e.unless (r2awc[0] == r2bwc[0]),
                   "Round2B wildcard must be same school as Round2A wildcard"
        else
          e.error  "Round2B wildcard exists but Round2A wildcard does not"
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

	end  # class DebatingResults

end  # module AhigsFos