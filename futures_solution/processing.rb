require 'openssl'
require 'faraday'
require 'benchmark'
require 'concurrent'
require_relative './http_client.rb'


class Processing
  # Creates 3 concurrent pools for each endpoint
  POOL_A = Concurrent::FixedThreadPool.new(3)
  POOL_B = Concurrent::FixedThreadPool.new(2)
  POOL_C = Concurrent::FixedThreadPool.new(1)

  def initialize(client = HttpClient.new('https://localhost:9292'))
    @client = client
  end

  def a(value)
    Concurrent::Promises.future_on(POOL_A) do
      @client.request("a", {value: value})
    end
  end

  def b(value)
    Concurrent::Promises.future_on(POOL_B) do
      puts "B for #{value}"
      @client.request("b", {value: value})
    end
  end

  def c(value)
    Concurrent::Promises.future_on(POOL_C) do
      puts "C for #{value}"
      @client.request("c", {value: value})
    end
  end

  def ab(aa_feature, b_feature)
    Concurrent::Promises.zip(b_feature, *aa_feature).then do |b, *aa|
      c("#{collect_sorted(aa)}-#{b}")
    end.flat
  end


  def collect_sorted(arr)
    arr.sort.join('-')
  end

  def run
    aa1 = [11, 12, 13].map { |v| a(v) }
    aa2 = [21, 22, 23].map { |v| a(v) }
    aa3 = [31, 32, 33].map { |v| a(v) }

    b1 = b(1)
    b2 = b(2)
    b3 = b(3)

    c1 = ab(aa1, b1)
    c2 = ab(aa2, b2)
    c3 = ab(aa3, b3)

    c123 = Concurrent::Promises.zip(c1, c2, c3).then do |*cc|
      a(collect_sorted(cc))
    end.flat

    puts 'Work!'

    c123.value!
  end
end

Processing.new.run
