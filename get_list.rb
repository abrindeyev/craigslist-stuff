#!/usr/bin/env ruby

require 'rubygems'
require 'open-uri'
require 'rest-client'
require 'uri'
require 'json'
require 'nokogiri'
require 'yaml'
require 'twitter'
require 'date'
require './lib/address'
require './lib/school'

STDOUT.sync = true

google_maps_api_key = File.open("#{ENV['HOME']}/.google_maps_api_key.txt", &:readline)

# neighborhoods: fremont / union city / newark
# housing type:  condo / duplex / house / townhouse
# rent maximum:  $4000
# ft^2 minimum:  1000
source_url = 'https://sfbay.craigslist.org/search/eby/apa?srchType=T&nh=54&housing_type=2&housing_type=4&housing_type=6&housing_type=9&maxAsk=4000&bedrooms=2&minSqft=1000'
page = Nokogiri::HTML(open(source_url).read, nil, 'UTF-8')
#links = page.xpath("//body/section[@id='pagecontainer']/form[@id='searchform']/div[@class='content']/ul[@class='rows']/li[@class='result-row']/a[@href]")
links = page.xpath("//*[@id='sortable-results']/ul/li/a[@href]")
o = YAML.load_file('.settings.yaml')
twi = Twitter::REST::Client.new do |config|
    config.consumer_key       = o['consumer_key']
    config.consumer_secret    = o['consumer_secret']
    config.access_token        = o['oauth_token']
    config.access_token_secret = o['oauth_token_secret']
end
external_ip = open(File.join(File.dirname(__FILE__), '.my_ext_ip_address')).read.chomp

seen_hash_file = File.join(File.dirname(__FILE__), 'seen_db.json')
seen_hash = File.exist?(seen_hash_file) ? JSON.parse(open(seen_hash_file).read) : {}

i_tweeted = false
if links.size == 0
  puts 'Got zero results. Something wrong on Craigslist!'
  exit -1
else
  i = 0
  last_tweet = ''
  links.each do |a|
    failure_detected = false
    uri = a['href']
    #uri = "https://sfbay.craigslist.org#{uri}"
    i = i + 1
    begin
      post = AddressHarvester.new(uri)
    rescue 
      puts "Caught an exception during object creation on #{uri}: #{$!}"
      failure_detected = true
    end
    next if post.nil?
    next if post.has_been_removed?
    next if seen_hash.include?(uri) and seen_hash[uri] == post.get_posting_update_time
    printf("%d. %s ", i, uri)
    posting_update_detected = seen_hash.include?(uri) ? true : false

    # Remember document and save index immediately
    seen_hash[uri] = post.get_posting_update_time
    now = DateTime.now
    censored = {}
    seen_hash.each_pair do |k,v|
      censored[k] = v if v != '' and (now - DateTime.parse(v)) < 30
    end
    File.open(seen_hash_file, 'w') do |f|
      f.write(censored.to_json)
    end
    seen_hash = censored
    next if failure_detected

    # Backup source to dump directory
    post.backup_source_to('/opt/craigslist_dumps')
    if post.have_full_address? 
      addr = post.get_full_address

      geocode_url = "https://maps.googleapis.com/maps/api/geocode/json?address=#{ URI.escape(addr) }&sensor=false&key=#{google_maps_api_key}"
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
      post.set_feature(:neighborhood, n) unless n == ''
    end

    print "[#{ post.get_score.to_s }] "

    receipt = post.get_receipt
    filename = post.get_feature(:posting_uri).match(/\d+\.html/).to_s
    File.open("/opt/craigslist_receipts/#{filename}", 'w') do |f|
      f.write(receipt)
    end
    threshold = 0
    if post.get_score > threshold
      i_tweeted = true
      begin
        tweet = (posting_update_detected ? 'UPDATE: ' : '') + "[#{post.get_score}] $#{post.get_feature(:rent_price)} / " + (post.have_feature?(:bedrooms) ? "#{post.get_feature(:bedrooms)}br / " : '') + (post.have_full_address? ? (post.have_feature?(:name) ? post.get_feature(:name) : post.get_full_address) : '[no address]') + ((post.is_scam? and not posting_update_detected) ? ' #scam' : '')
        if tweet == last_tweet
          puts "duplicate, not tweeting!"
        else
          full_link = "http://#{external_ip}/html/#{filename}"
          # short_link = open("http://clck.ru/--?url="+full_link).read
          # puts short_link
          tweeted = "#{tweet} #{full_link}"
          twi.update(tweeted)
          last_tweet = tweet
        end
      rescue Twitter::Error::Forbidden
        puts "Caught an exception during posting following tweet: [#{tweet}]: #{$!}"
      end
    else
      puts "#{full_link} : score < #{threshold}, not tweeting"
    end
  end
  puts "************ PROCESSED LINKS ************" if i_tweeted
end
