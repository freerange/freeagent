require 'bundler/setup'
require 'oauth2'
require 'dotenv'
require 'csv'

Dotenv.load

reference_date = Date.parse(ARGV[0]) rescue Date.today << 1
year = reference_date.year
month = reference_date.month

from_date = Date.new(year, month, 1)
to_date = Date.new(year, month, -1)

client_id = ENV.fetch('CLIENT_ID')
client_secret = ENV.fetch('CLIENT_SECRET')
site = 'https://api.freeagent.com/v2/'

client = OAuth2::Client.new(client_id, client_secret, site: site)

access_token = ENV.fetch('ACCESS_TOKEN')
refresh_token = ENV.fetch('REFRESH_TOKEN')

@api = OAuth2::AccessToken.new(client, access_token, refresh_token: refresh_token)

MAXIMUM_RESULTS_PER_PAGE = 100

def get_resources(name, filters = {})
  uri = URI(name)
  filters[:per_page] ||= MAXIMUM_RESULTS_PER_PAGE
  uri.query = URI.encode_www_form(filters)
  response = @api.get(uri.to_s)
  resources = response.parsed[name].map { |r| OpenStruct.new(r) }
  raise 'Multiple pages of results' if resources.length == filters[:per_page]
  resources
end

users = [
  OpenStruct.new(first_name: 'James', url: 'https://api.freeagent.com/v2/users/7474'),
  OpenStruct.new(first_name: 'Chris', url: 'https://api.freeagent.com/v2/users/32469'),
]

results = {}

projects = get_resources('projects', view: 'active')
projects.each do |project|
  results[project.name] = Hash[*users.map { |u| [u.first_name, 0] }.flatten]
  timeslips = get_resources('timeslips', project: project.url, from_date: from_date, to_date: to_date)
  timeslips.group_by(&:user).each do |user_url, ts|
    user = users.find { |u| u.url == user_url }
    total_hours = ts.inject(0) { |total, t| total + BigDecimal.new(t.hours) }
    results[project.name][user.first_name] = total_hours
  end
end

CSV($stdout, col_sep: "\t") do |csv|
  results.each do |project_name, hours_per_user|
    hours_per_user.each do |first_name, hours|
      csv << [from_date.strftime('%B %Y'), project_name, first_name, hours.to_f/24]
    end
  end
end
