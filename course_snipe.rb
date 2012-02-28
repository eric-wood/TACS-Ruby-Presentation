# By Eric Wood for his presentation on Ruby for the Texas A&M Computing Society
# Do as you wish with this, stay out of trouble...

require 'net/http'
require 'nokogiri'

if ARGV.size != 3
  puts "Usage: ruby course_snipe.rb <course crn number> <fall/spring/summer> <year>" 
  puts "Example: ruby course_snipe.rb 17077 spring 2012"
end

# TAMU does these little code thingies to specify terms.
# The format is as follows: <year><code>1
# For example, Spring 2012 would be 201211
seasons = {
  "spring" => 1,
  "summer" => 2,
  "fall"   => 3
}

# Read in our command line arguments!
crn    = ARGV[0]
season = ARGV[1]
year   = ARGV[2]
term   = "#{year}#{seasons[season.downcase]}1"

# UGH hack central over here...
# Here's the issue: Ruby doesn't have its own set of trusted CA certs
# so we need to point it to where those are; in this case they're from the
# macports "curl-ca-bundle" package; you can google where to find the equivalent
# for your platform of choice, just change this path to match your system.
# Once again, I am REALLY sorry this had to happen...HTTPS is not easy...
ca_file = "/opt/local/share/curl/curl-ca-bundle.crt"

uri = URI("https://compass-ssb.tamu.edu/pls/PROD/bwykschd.p_disp_detail_sched?term_in=#{term}&crn_in=#{crn}")

# Get the page...
https = Net::HTTP.new(uri.host, 443)
https.use_ssl = true
https.verify_mode = OpenSSL::SSL::VERIFY_PEER
https.ca_file = ca_file
response = https.request_get(uri.request_uri)

case response
when Net::HTTPSuccess, Net::HTTPRedirection
  # Success! Parse the results...
  # Introducing our good friend Nokogiri, the HTML/XML parser
  doc = Nokogiri::HTML(response.body)
  course_info = doc.css("th.ddlabel").children.first.text
  puts course_info

  # It is late, I'm tired...I don't wanna hear about it...
  matches   = response.body.scan(/<TD CLASS="dddefault">([0-9]+)<\/TD>/)
  capacity  = matches[0].first.to_i
  actual    = matches[1].first.to_i
  remaining = capacity - actual

  puts "Capacity:  #{capacity}\nActual:    #{actual}\nRemaining: #{remaining}"
else
  puts "SOMETHING TERRIBLE HAS HAPPENED: #{response.value}"
end
