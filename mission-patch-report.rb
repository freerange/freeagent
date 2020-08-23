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
  page = 1
  resources = []
  filters[:per_page] = MAXIMUM_RESULTS_PER_PAGE
  loop do
    uri = URI(name)
    filters[:page] = page
    uri.query = URI.encode_www_form(filters)
    response = @api.get(uri.to_s)
    next_resources = response.parsed[name].map { |r| OpenStruct.new(r) }
    resources += next_resources
    break unless next_resources.length == filters[:per_page]
    page += 1
  end
  resources
end

invoices = get_resources('invoices', view: 'all')
mp_invoices = invoices.select { |i| i.reference.match(/^MISSIONPATCH/) }
contacts = get_resources('contacts', view: 'all')
mp_contacts = mp_invoices.map(&:contact).uniq.map { |url| contacts.find { |c| c.url == url } }

CSV($stdout, col_sep: "\t") do |csv|
  mp_contacts.each do |contact|
    contact_id = contact.url.split('/').last
    edit_contact_url = "https://freerange.freeagent.com/contacts/#{contact_id}/edit"
    csv << [edit_contact_url, contact.email, contact.charge_sales_tax]
  end
end
