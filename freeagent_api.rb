require 'json'
require 'oauth2'
require 'dotenv'
require 'oauth2_callback_monitor'

Dotenv.load

class FreeagentAPI
  MAXIMUM_RESULTS_PER_PAGE = 100

  def initialize
    client_id = ENV.fetch('CLIENT_ID')
    client_secret = ENV.fetch('CLIENT_SECRET')
    site = 'https://api.freeagent.com/v2'
    @client = OAuth2::Client.new(client_id, client_secret, {
      site: site,
      authorize_url: '/v2/approve_app',
      token_url: '/v2/token_endpoint'
    })
    @resources = {}
  end

  def get_resource(name, url)
    if (resource = @resources[url])
      resource
    else
      response = get(url)
      resource = OpenStruct.new(response.parsed[name])
      @resources[url] = resource
    end
  end

  def get_resources(name, filters = {})
    page = 1
    resources = []
    filters[:per_page] = MAXIMUM_RESULTS_PER_PAGE
    loop do
      uri = URI(name)
      filters[:page] = page
      uri.query = URI.encode_www_form(filters)
      response = get(uri.to_s)
      next_resources = response.parsed[name].map { |r| OpenStruct.new(r) }
      resources += next_resources
      break unless next_resources.length == filters[:per_page]
      page += 1
    end
    resources
  end

  private

  def get(path, opts = {}, &block)
    access_token.get(path, opts = {}, &block)
  end

  def access_token
    access_token = load_access_token
    if access_token.nil?
      access_token = obtain_access_token
      save_access_token(access_token)
    end
    if access_token.expired?
      access_token = access_token.refresh!
      save_access_token(access_token)
    end
    access_token
  end

  def load_access_token
    return nil unless File.exist?('access-token.json')
    hash = JSON.parse(File.read('access-token.json'))
    OAuth2::AccessToken.from_hash(@client, hash)
  end

  def save_access_token(access_token)
    File.write('access-token.json', access_token.to_hash.to_json)
  end

  def obtain_access_token
    monitor = OAuth2CallbackMonitor.new
    monitor.create_endpoint
    redirect_uri = monitor.endpoint_url
    authorize_url = auth_code.authorize_url(redirect_uri: redirect_uri)

    puts 'Press <enter> to open a browser, sign in to FreeAgent, and authorize the app'
    puts "URL: #{authorize_url}"
    gets
    system(%{open "#{authorize_url}"})

    code = monitor.wait_for_auth_code
    auth_code.get_token(code, redirect_uri: redirect_uri)
  end

  def auth_code
    @client.auth_code
  end
end
