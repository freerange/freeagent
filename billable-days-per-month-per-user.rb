require 'bundler/setup'
require 'oauth2'
require 'dotenv'
require 'csv'

Dotenv.load

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
  OpenStruct.new(first_name: 'Ben', url: 'https://api.freeagent.com/v2/users/580257'),
  OpenStruct.new(first_name: 'Chris L', url: 'https://api.freeagent.com/v2/users/485461'),
  OpenStruct.new(first_name: 'Chris R', url: 'https://api.freeagent.com/v2/users/32469'),
  OpenStruct.new(first_name: 'James', url: 'https://api.freeagent.com/v2/users/7474'),
]

number_of_months = Integer(ARGV[0]) rescue 1
reference_date = Date.today << number_of_months

results = {}

while reference_date < Date.today do
  month_key = reference_date.strftime('%b %Y')
  year = reference_date.year
  month = reference_date.month
  from_date = Date.new(year, month, 1)
  to_date = Date.new(year, month, -1)

  timeslips = get_resources('timeslips', from_date: from_date, to_date: to_date, reporting_type: 'billable')

  results[month_key] = Hash[*users.map { |u| [u.first_name, 0] }.flatten]
  timeslips.group_by(&:user).each do |user_url, ts|
    user = users.find { |u| u.url == user_url }
    next unless user
    total_days = ts.inject(0) { |total, t| total + (BigDecimal.new(t.hours) / BigDecimal.new(8)) }
    results[month_key][user.first_name] = total_days
  end

  reference_date = reference_date >> 1
end

user_keys = users.map(&:first_name)
CSV($stdout, col_sep: "\t") do |csv|
  csv << ['Month', *user_keys]
  results.each do |month_key, days_per_user|
    csv << [month_key, *days_per_user.values_at(*user_keys).map(&:to_f)]
  end
end
