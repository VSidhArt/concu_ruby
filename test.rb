# frozen_string_literal: true

require 'benchmark'
require 'minitest/autorun'
#require_relative './futures_solution/processing.rb'
require_relative './csp_solution/processing.rb'

class MainTest < Minitest::Test
  def test_correct_result
    result = Processing.new.run

    assert_equal '0bbe9ecf251ef4131dd43e1600742cfb', result
  end

  def test_execution_time
    time = Benchmark.realtime { Processing.new.run }

    assert time <= 7, "Time more then 7 seconds time: #{time}"
  end
end
