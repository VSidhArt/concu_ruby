# frozen_string_literal: true
require 'concurrent'
require 'concurrent-edge'
require 'pry'
require_relative '../http_client.rb'

class Processing
  attr_reader :a_in, :a_out, :b_in, :b_out, :c_in, :c_out
  attr_reader :a_limit, :b_limit, :c_limit
  attr_reader :client

  A_VALUES = [11, 12, 13, 21, 22, 23, 31, 32, 33].freeze
  B_VALUES = [1, 2, 3].freeze

  def initialize
    @client = HttpClient.new('https://localhost:9292')

    @a_in = Concurrent::Channel.new
    @a_out = Concurrent::Channel.new

    @b_in = Concurrent::Channel.new
    @b_out = Concurrent::Channel.new

    @c_in = Concurrent::Channel.new
    @c_out = Concurrent::Channel.new

    @a_limit = Concurrent::Throttle.new(3)
    @b_limit = Concurrent::Throttle.new(2)
    @c_limit = Concurrent::Throttle.new(1)


    start_goroutines
  end


  def run
    load_data(A_VALUES, a_in)
    load_data(B_VALUES, b_in)

    ~c_out
  end

  private

  def start_goroutines
    start_first_stage(a_in, a_out, a_limit, "a")
    start_first_stage(b_in, b_out, b_limit, "b")
    start_c_grouping_stage
    start_c_stage
  end

  def load_data(values, in_channel)
    Concurrent::Channel.go do
      values.each { |val| in_channel << val }

      in_channel.close
    end
  end

  def start_first_stage(in_ch, out_ch, limit, endpoint)
    Concurrent::Channel.go do
      in_ch.each do |val|
        Concurrent::Channel.go do
          limit.acquire do
            out_ch << { value: client.request(endpoint, {value: val}), group: val.digits.last }
          end
        end
      end
    end
  end

  def perform_grouping_stage(groups, val, type, ch)
    group = groups.fetch(val[:group], { a: [], b: [] })
    group[type] << val[:value]
    groups[val[:group]] = group

    if group_full?(group)
      ch << "#{collect_sorted(group[:a])}-#{group[:b].shift}"

      groups.delete(val[:group])
    end
  end

  def start_c_grouping_stage
    Concurrent::Channel.go do
      groups = {}

      loop do
        Concurrent::Channel.select do |s|
          s.take(a_out) do |val|
            perform_grouping_stage(groups, val, :a, c_in)
          end

          s.take(b_out) do |val|
            perform_grouping_stage(groups, val, :b, c_in)
          end
        end
      end
    end
  end

  def start_c_stage
    Concurrent::Channel.go do
      c_results = []

      c_in.each do |val|
        c_limit.acquire do
          c_results << client.request("c", {value: val})
        end

        if c_results.length == 3
          c_out << client.request("a", {value: collect_sorted(c_results)})

          c_results.clear
        end
      end
    end
  end

  def collect_sorted(arr)
    arr.sort.join('-')
  end

  def group_full?(group)
    group[:a].length == 3 && group[:b].length == 1
  end
end

Processing.new.run
