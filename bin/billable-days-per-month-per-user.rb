require 'bundler/setup'
$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))

require 'freeagent_api'
require 'user'
require 'csv'

api = FreeagentAPI.new

users = User.members

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

  timeslips = api.get_resources('timeslips', from_date: from_date, to_date: to_date, reporting_type: 'billable')

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
