require 'net/http'
require 'uri'
require 'json'

class PostbinApi
  class Bin
    def self.create_url
      'https://postb.in/api/bin'
    end

    def initialize(data)
      @data = data
    end

    def id
      @data['binId']
    end

    def url
      "https://postb.in/#{id}"
    end

    def delete_url
      "https://postb.in/api/bin/#{id}"
    end

    def shift_request_url
      "https://postb.in/api/bin/#{id}/req/shift"
    end
  end

  class Request
    def initialize(data)
      @data = data
    end

    def query
      @data['query']
    end
  end

  def create_bin
    uri = URI(Bin.create_url)
    response = http(uri) do |http|
      http.post(uri.path, '')
    end
    case response
    when Net::HTTPCreated
      data = JSON.parse(response.body)
      Bin.new(data)
    else
      raise "Error creating bin: #{response.body}"
    end
  end

  def shift_request(bin)
    uri = URI(bin.shift_request_url)
    response = http(uri) do |http|
      http.get(uri.path)
    end
    case response
    when Net::HTTPOK
      data = JSON.parse(response.body)
      Request.new(data)
    when Net::HTTPNotFound
      nil
    else
      raise "Error shifting request: #{response.body}"
    end
  end

  def delete_bin(bin)
    uri = URI(bin.delete_url)
    response = http(uri) do |http|
      http.delete(uri.path)
    end
    case response
    when Net::HTTPOK
      true
    else
      raise "Error deleting bin: #{response.body}"
    end
  end

  private

  def http(uri)
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      yield(http)
    end
  end
end
