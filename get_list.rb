#!/usr/bin/env ruby

require 'rubygems'
require 'open-uri'
require 'rest-client'
require 'uri'
require 'json'
require 'nokogiri'
require 'yaml'
require 'twitter'
require 'lib/address'
require 'lib/school'

STDOUT.sync = true

source_url = 'http://sfbay.craigslist.org/search/apa/eby?zoomToPosting=&altView=&query=&srchType=A&minAsk=&maxAsk=2200&bedrooms=2&nh=54'
page = Nokogiri::HTML(open(source_url).read, nil, 'UTF-8')
links = page.xpath("//body/blockquote[@id='toc_rows']/p[@class='row']/a[@href]")
o = YAML.load_file('.settings.yaml')
Twitter.configure do |config|
    config.consumer_key = o['consumer_key']
    config.consumer_secret = o['consumer_secret']
    config.oauth_token = o['oauth_token']
    config.oauth_token_secret = o['oauth_token_secret']
end
external_ip = open(File.join(File.dirname(__FILE__), '.my_ext_ip_address')).read
last_seen_file = File.join(File.dirname(__FILE__), '.last_seen_posting')
last_seen_posting_uri = File.exist?(last_seen_file) ? open(last_seen_file).read.gsub(/\n/,'') : ''
if links.size == 0
  puts 'Got zero results. Something wrong on Craigslist!'
  exit -1
else
  started_at_posting_uri = links.first['href']
  # remember current position in file before processing
  # that help not to process same postings in case of 
  # fatal error in any of that again and again
  open(last_seen_file, 'w') do |f|
      f << started_at_posting_uri
  end
  i = 0
  last_tweet = ''
  links.each do |a|
    i = i + 1
    uri = a['href']
    break if uri == last_seen_posting_uri
    printf("%d. %s ", i, uri)
    post = AddressHarvester.new(uri)
    next if post.has_been_removed?
    post.backup_source_to('/var/lib/craiglist_dumps')
    unless post.have_full_address? 
      puts "[---]"
      next
    end
    addr = post.get_full_address

    geocode_url = "http://maps.googleapis.com/maps/api/geocode/json?address=#{ URI.escape(addr) }&sensor=false"
    resp = RestClient.get(geocode_url)
    geo = JSON.parse(resp.body)
    unless geo['status'] == 'OK'
      puts "#{uri} : geocode failed: #{geo['status']}"
      next
    end
    a_lat = geo['results'][0]['geometry']['location']['lat']
    a_lng = geo['results'][0]['geometry']['location']['lng']

    s = SchoolMatcher.new(a_lat, a_lng)
    post.set_feature(:school_name, s.get_school_name)
    post.set_feature(:school_rating, s.get_rating)
    post.set_feature(:school_addr, s.get_school_address)

    n = ''
    geo['results'][0]['address_components'].each {|h| n = h['short_name'] if h['types'][0] == 'neighborhood' }
    post.set_feature(:neighborhood, n)

    print "[#{ post.get_score.to_s }] "

    receipt = post.get_receipt
    filename = post.get_feature(:posting_uri).match(/\d+\.html/).to_s
    File.open("/var/www/html/#{filename}", 'w') do |f|
      f.write(receipt)
    end
    begin
      tweet = "[#{post.get_score}] $#{post.get_feature(:rent_price)} / " + (post.have_feature?(:bedrooms) ? "#{post.get_feature(:bedrooms)}br / " : '') + (post.have_feature?(:name) ? post.get_feature(:name) : post.get_full_address)
      if tweet == last_tweet
        puts "duplicate, not tweeting!"
      else
        full_link = "http://#{external_ip}/#{filename}"
        short_link = open("http://clck.ru/--?url="+full_link).read
        puts short_link
        tweeted = "#{tweet} #{short_link}"
        Twitter.update(tweeted)
        last_tweet = tweet
      end
    rescue Twitter::Error::Forbidden
      puts "Caught an exception during posting following tweet: [#{tweet}]: #{$!}"
    end
  end
end
