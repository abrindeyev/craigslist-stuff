#!/usr/bin/env ruby

require 'rubygems'
require 'open-uri'
require 'rest-client'
require 'uri'
require 'json'
require 'nokogiri'
require 'lib/address'
require 'lib/school'

source_url = 'http://sfbay.craigslist.org/search/apa/eby?zoomToPosting=&altView=&query=&srchType=A&minAsk=&maxAsk=2200&bedrooms=2&nh=54'
page = Nokogiri::HTML(open(source_url).read, nil, 'UTF-8')
page.xpath("//body/blockquote[@id='toc_rows']/p[@class='row']/a[@href]").each do |a|
  uri = a['href']
  post = AddressHarvester.new(uri)
  unless post.have_full_address? 
    puts "[---] #{uri}"
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

  puts "[#{ post.get_score.to_s }] #{uri}"
end
