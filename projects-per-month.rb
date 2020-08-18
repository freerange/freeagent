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

@resources = {}

def get_resource(name, url)
  if (resource = @resources[url])
    resource
  else
    response = @api.get(url)
    resource = OpenStruct.new(response.parsed[name])
    @resources[url] = resource
  end
end

number_of_months = Integer(ARGV[0]) rescue 1
reference_date = Date.today << number_of_months

projects = get_resources('projects')
tasks = get_resources('tasks')

results = {}

while reference_date < Date.today do
  month_key = reference_date.strftime('%b %Y')
  year = reference_date.year
  month = reference_date.month
  from_date = Date.new(year, month, 1)
  to_date = Date.new(year, month, -1)

  timeslips = get_resources('timeslips', from_date: from_date, to_date: to_date, reporting_type: 'billable')

  results[month_key] = timeslips.group_by(&:task).map do |task_url, ts|
    task = tasks.find { |t| t.url == task_url }
    next unless task
    project_url = task.project
    project = projects.find { |p| p.url == project_url }
    next unless project
    contact_url = project.contact
    contact = get_resource('contact', contact_url)
    [contact.organisation_name, project.name, task.name].join(' - ')
  end.compact.sort

  reference_date = reference_date >> 1
end

CSV($stdout, col_sep: "\t") do |csv|
  csv << ['Month', 'Project']
  results.each do |month_key, project_names|
    if project_names.empty?
      csv << [month_key]
    else
      project_names.each do |project_name|
        csv << [month_key, project_name]
      end
    end
  end
end
