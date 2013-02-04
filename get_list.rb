#!/usr/bin/env ruby

require 'rubygems'
require 'open-uri'
require 'rest-client'
require 'uri'
require 'json'
require 'nokogiri'
require 'lib/address'
require 'lib/school'

STDOUT.sync = true

source_url = 'http://sfbay.craigslist.org/search/apa/eby?zoomToPosting=&altView=&query=&srchType=A&minAsk=&maxAsk=2200&bedrooms=2&nh=54'
page = Nokogiri::HTML(open(source_url).read, nil, 'UTF-8')
links = page.xpath("//body/blockquote[@id='toc_rows']/p[@class='row']/a[@href]")
last_seen_file = File.join(File.dirname(__FILE__), '.last_seen_posting')
last_seen_posting_uri = File.exist?(last_seen_file) ? open(last_seen_file).read : ''
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
  links.each do |a|
    i = i + 1
    uri = a['href']
    break if uri == last_seen_posting_uri
    printf("%d. %s ", i, uri)
    post = AddressHarvester.new(uri)
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

    puts "[#{ post.get_score.to_s }]"
  end
end
