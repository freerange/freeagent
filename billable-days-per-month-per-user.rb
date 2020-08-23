require 'bundler/setup'
require 'freeagent_api'
require 'csv'

@api = FreeagentAPI.new

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

start_date = Date.parse(ARGV[0]) rescue Date.today
end_date = Date.parse(ARGV[1]) rescue Date.today
report_date = start_date

results = {}

while report_date < end_date do
  month_key = report_date.strftime('%b %Y')
  year = report_date.year
  month = report_date.month
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

  report_date = report_date >> 1
end

user_keys = users.map(&:first_name)
CSV($stdout, col_sep: "\t") do |csv|
  csv << ['Month', *user_keys]
  results.each do |month_key, days_per_user|
    csv << [month_key, *days_per_user.values_at(*user_keys).map(&:to_f)]
  end
end
