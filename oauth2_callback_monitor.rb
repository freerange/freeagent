require 'postbin_api'

class OAuth2CallbackMonitor
  def initialize
    @postbin_api = PostbinApi.new
  end

  def create_endpoint
    @bin = @postbin_api.create_bin
  end

  def endpoint_url
    @bin ? @bin.url : nil
  end

  def wait_for_auth_code
    request = nil
    loop do
      request = @postbin_api.shift_request(@bin)
      break if request
      sleep 1
    end
    request.query['code']
  ensure
    @postbin_api.delete_bin(@bin)
  end
end
