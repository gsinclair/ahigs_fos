
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
	class DebatingResults
    ROUNDS = [:Round1, :Round2A, :Round2B, :QuarterFinal, :SemiFinal, :GrandFinal]
    ABBREV = {:Round1 => :r1, :Round2A => :r2a, :Round2B => :r2b,
              :QuarterFinal => :qf, :SemiFinal => :sf, :GrandFinal => :gf }

		# data: hash containing 'Round1', 'Round2', etc. from debating_results.yaml file.
		def DebatingResults.from_results_data(data, festival_info)
			x = ROUNDS.graph { |round|
				[round, DebatingRound.from_hash(data[round.to_s], festival_info)]
			}
			DebatingResults.new(x)
		end

    # rounds: { :Round1 => DebatingRound, :Round2A => DebatingRound, ... }
    def initialize(rounds, festival_info)
    	@results = rounds
    	@festival_info = festival_info
    end

    def results_for_school(school)
      results = []
      if @results[:Round1].schools.include? school
      	results << [:p, points_for_participation]
      end
      ROUNDS.each do |round|
        result = @results[round]
        if @results[round].wins.include? school
        	results << [ABBREV[round], points_for_round(round)]
        end        	
      end
      results
    end

    def points_for_school(school)
    	results_for_school(school).map { |x| x[1] }.sum
    end

    private
    
    def points_for_participation
    	@festival_info.debating_points_for(:participation)
    end

    def points_for_round(round)
    	@festival_info.debating_points_for(round)
    end
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
			schools = Set.new(@schools_str.strip.split(/\s+/).map { |s| @festival_info.school(s) })
			wildcard = [:not_yet_implemented]
      wins = Set.new
      losses = Set.new
      pairs = Set.new
      results_str_arr.each do |result_str|
      	# result_str is something like "SCEGGS  def  Tangara"
      	if result_str =~ /(\w+)\s+def\s+(\w+)/
      		winner = @festival_info.school($1)
      		loser  = @festival_info.school($2)
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