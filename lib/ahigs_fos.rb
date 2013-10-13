require 'stringio'
require 'yaml'
require 'pathname'
require 'pp'

require 'debuglog'
require 'pry'

require 'facets/string/indent'
require 'facets/enumerable/graph'

# From facets.
class String
 def trim(n=0)
    md = /\A.*\n\s*(.)/.match(self) || /\A\s*(.)/.match(self)
    d = md[1]
    return '' unless d
    if n == 0
      gsub(/\n\s*\Z/,'').gsub(/^\s*[#{d}]/, '')
    else
      gsub(/\n\s*\Z/,'').gsub(/^\s*[#{d}]/, ' ' * n)
    end
  end
end

require "ahigs_fos/version"
require "ahigs_fos/err"
require "ahigs_fos/configuration"
require "ahigs_fos/debating"
require "ahigs_fos/results"
require "ahigs_fos/report"

class Array
  def sum
    self.inject(0) { |acc, n| acc + n }
  end
end

module AhigsFos
  # ...?
end
