#!/usr/bin/env ruby

require 'rubygems'
require 'open-uri'
require 'rest-client'
require 'uri'
require 'json'
require 'nokogiri'
require './lib/address'
require './lib/school'

post = AddressHarvester.new(ARGV[0])
raise "Post has been removed" if post.has_been_removed?
puts "Post updated: #{post.get_posting_update_time}"
puts "Post version: #{post.version}"
unless post.have_full_address? 
  puts "Can't get full address for that posting, giving up!"
  exit -1
end
addr = post.get_full_address
puts "Address was reverse geocoded" if post.have_feature?(:address_was_reverse_geocoded)

geocode_url = "http://maps.googleapis.com/maps/api/geocode/json?address=#{ URI.escape(addr) }&sensor=false"
resp = RestClient.get(geocode_url)
geo = JSON.parse(resp.body)
unless geo['status'] == 'OK'
  puts "Geocode failed: #{geo['status']}"
  exit -1
end

puts "Report for address: #{geo['results'][0]['formatted_address']}"
a_lat = geo['results'][0]['geometry']['location']['lat']
a_lng = geo['results'][0]['geometry']['location']['lng']

if post.get_city.match(/fremont/i)
  s = SchoolMatcher.new(a_lat, a_lng)
  post.set_feature(:school_name, s.get_school_name)
  post.set_feature(:school_rating, s.get_rating)
  post.set_feature(:school_addr, s.get_school_address)
  directions_url = "http://maps.googleapis.com/maps/api/directions/json?origin=#{ URI.escape(addr) }&destination=#{ URI.escape(s.get_school_address) }&sensor=false&mode=driving"
  resp = RestClient.get(directions_url)
  geo2 = JSON.parse(resp.body)
  unless geo2['status'] == 'OK'
    puts "Directions failed: #{geo['status']}"
    exit -1
  end
  puts "Driving to school by car is #{geo2['routes'][0]['legs'][0]['duration']['text']}"

  n = ''
  #puts geo.inspect
  geo['results'][0]['address_components'].each {|h| n = h['short_name'] if h['types'][0] == 'neighborhood' }
  #puts "Neighborhood: #{n}"
  post.set_feature(:neighborhood, n)

  directions_url = "http://maps.googleapis.com/maps/api/directions/json?origin=#{ URI.escape(addr) }&destination=Fremont+BART+station&sensor=false&mode=walking"
  resp = RestClient.get(directions_url)
  geo2 = JSON.parse(resp.body)
  unless geo2['status'] == 'OK'
    puts "Directions failed: #{geo2['status']}"
    exit -1
  end
  puts "Walking to Fremont BART: #{geo2['routes'][0]['legs'][0]['duration']['text']}"
end
puts "Matched as #{post.get_feature(:name)}" if post.have_feature?(:name)
puts "Posting score: " + post.get_score.to_s
puts "Scoring log:"
post.get_scoring_log.each do |l|
  puts (l[:delta] > 0 ? "+#{l[:delta]}" : l[:delta].to_s) + " " + l[:reason]
end
