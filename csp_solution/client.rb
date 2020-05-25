require 'openssl'
require 'faraday'
require 'concurrent'
#require 'concurrent-edge'
require 'benchmark'

require './processing'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

a_values = [11, 12, 13, 21, 22, 23, 31, 32, 33].freeze
b_values = [1, 2, 3].freeze

value = ""

time = Benchmark.measure do
  c_out = Processing.new.process(a_values, b_values)

  value = ~c_out
  puts "FINAL RES #{value}"
end
puts "TIME #{time}"

