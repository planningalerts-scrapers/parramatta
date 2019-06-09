require 'scraperwiki'
require 'mechanize'

class Hash
  def has_blank?
    self.values.any?{|v| v.nil? || v.length == 0}
  end
end

base_url = "http://eplanning.parracity.nsw.gov.au/Pages/XC.Track/SearchApplication.aspx"

# meaning of t parameter
# %23427 - Development Applications
# %23437 - Constuction Certificates
# %23434,%23435 - Complying Development Certificates
# %23475 - Building Certificates
# %23440 - Tree Applications
url = base_url + "?d=last14days&t=%23437,%23437,%23434,%23435,%23475,%23440"

agent = Mechanize.new
page = agent.get(url)

results = page.search('div.result')

results.each do |result|
  info_url = base_url + "?" + result.search('a.search')[0]['href'].strip.split("?")[1]
  detail_page = agent.get(info_url);

  council_reference = detail_page.search('h2').text.split("\n")[0].strip
  description = detail_page.search("div#b_ctl00_ctMain_info_app").text.split("Status:")[0].strip.split.join(" ")
  date_received = detail_page.search("div#b_ctl00_ctMain_info_app").text.split("Lodged: ")[1].split[0]
  date_received = Date.parse(date_received.to_s)
  address = detail_page.search("div#b_ctl00_ctMain_info_prop").text.split("\n")[0].squeeze(' ') rescue nil

  record = {
    'council_reference' => council_reference,
    'description'       => description,
    'date_received'     => date_received.to_s,
    'address'           => address,
    'date_scraped'      => Date.today.to_s,
    'info_url'          => info_url
  }

  unless record.has_blank?
    puts "Saving record " + record['council_reference'] + ", " + record['address']
#       puts record
    ScraperWiki.save_sqlite(['council_reference'], record)
  else
    puts "Something not right here: #{record}"
  end
end
