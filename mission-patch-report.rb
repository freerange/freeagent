require 'bundler/setup'
require 'freeagent_api'
require 'csv'

api = FreeagentAPI.new

invoices = api.get_resources('invoices', view: 'all')
mp_invoices = invoices.select { |i| i.reference.match(/^MISSIONPATCH/) }
contacts = api.get_resources('contacts', view: 'all')
mp_contacts = mp_invoices.map(&:contact).uniq.map { |url| contacts.find { |c| c.url == url } }

CSV($stdout, col_sep: "\t") do |csv|
  mp_contacts.each do |contact|
    contact_id = contact.url.split('/').last
    edit_contact_url = "https://freerange.freeagent.com/contacts/#{contact_id}/edit"
    csv << [edit_contact_url, contact.email, contact.charge_sales_tax]
  end
end
