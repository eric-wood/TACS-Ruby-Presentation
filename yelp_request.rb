# Some context: this is an excerpt from my final project for CSCE 470
# This is used to scrape data from Yelp...and it *will* get you banned
# if you run it long enough, as Yelp is very sensitive when it comes to
# their data and this script violates their terms of service many times
# over. This script is simply a wrapper that allows other scripts
# to easily scrape data from Yelp.
#
# I'm not responsible for any shenanigans this causes. You've been warned.
#

require 'nokogiri'
require 'net/http'

# NOTE: This code does not exist.
# Carry on, Nothing to see here.

class YelpRequest
  def self.search(loc_id)
    loc = Location.find_by_id(loc_id)
    
    if loc
      # Any rules for escaping incoming strings can go here
      escape = lambda do |s|
        if s
          s.gsub!('&', 'and') # This little guy is quite a troublemaker...
          s = CGI.escape(s)   # THIS MUST BE THE LAST ONE, MK?
          s                   # Keep in mind the last value is what gets used...
        end
      end

      name    = escape.call(loc.name)
      address = escape.call(loc.address)

      url =  "http://www.yelp.com/search?"
      url += "find_desc=#{name}&"
      url += "find_loc=#{address}&ns=1"
      
      resp = self.get(url)
      doc = Nokogiri::HTML.parse(resp)

      # Can we assume the first link is the result we want?
      # Maybe? Remind me to test this by hand later...

      # They made this easy...results are labeled!
      nodes = doc.css("#bizTitleLink0")

      if nodes.count > 0 # hey, you never know
        page = "http://yelp.com/#{nodes.first['href']}"
      end

      return page
    end
  end

  # In this case URL points to the Yelp results page.
  # We'll just be returning a hash of scraped data.
  def self.details(url)
    resp = self.get(url)

    if resp
      doc = Nokogiri::HTML.parse(resp)

      results = Hash.new

      # Meow.
      results[:cats] = doc.css('#cat_display a').map { |cat| cat.text.strip }

      # Ngrams. I swear I heard this term in class before ;)
      results[:ngrams] = doc.css('a.ngram').map { |ngram| ngram.text.strip }

      return results
    end

    puts "No results :("
  end

  def self.get(url, attempt=10)
    return nil unless attempt >= 0

    puts "Requesting (#{10 - attempt + 1}): #{url}"

    uri = URI(url)

    # These are not the droids you're looking for...
    req = Net::HTTP::Get.new(uri.request_uri)
    req['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_2) AppleWebKit/535.7 (KHTML, like Gecko) Chrome/16.0.912.41 Safari/535.7'

    resp = Net::HTTP.start(uri.host, uri.port) do |http|
      http.request(req)
    end
    
    code = resp.code.to_i
    if(code == 200)
      return resp.body
    elsif(code == 303 || code == 301)
      puts "303 => redirecting..."
      self.get(resp['Location'])
    else
      puts "Failed: response code => #{code}"
      # Will I regret this decision? At the very least it will give up...
      self.get(url, attempt-1)
    end
  end
end
