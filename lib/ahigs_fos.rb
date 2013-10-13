require 'stringio'
require 'yaml'
require 'pathname'
require 'pp'

require 'debuglog'
require 'pry'

require 'facets/string/indent'
require 'facets/enumerable/graph'

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
