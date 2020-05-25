# frozen_string_literal: true

require 'openssl'
require 'faraday'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

class HttpClient
  def initialize(host)
    @connection = Faraday.new(url: host)
  end

  def request(endpoint, query)
    response = @connection.get(endpoint, query)
    response.body
  end
end
