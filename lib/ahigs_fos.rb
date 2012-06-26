require 'pry'
require 'stringio'

require 'facets/string/indent'

require "ahigs_fos/version"
require "ahigs_fos/err"
require "ahigs_fos/configuration"
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
