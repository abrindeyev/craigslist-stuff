#!/usr/bin/env ruby

require 'rubygems'
require 'open-uri'
require 'rest-client'
require 'uri'
require 'json'
require 'nokogiri'
require 'mongo'
require './lib/address'
require './lib/school'
require './lib/url-cache'

Mongo::Logger.logger.level = ::Logger::FATAL

puts '-------------------------------------------------------'

ENV['DEBUG'] = 'true'

mc = Mongo::Client.new('mongodb://127.0.0.1:27017/cg')
uc = URLCacher.new(mc)

post = AddressHarvester.new(ARGV[0],mc)
puts "ID=" + post.get_id.to_s
raise "Post has been removed" if post.has_been_removed?
puts "Post updated: #{post.get_posting_update_time}"
puts "Post version: #{post.version}"

addr = post.get_full_address
puts "Address was reverse geocoded" if post.have_feature?(:address_was_reverse_geocoded)

geocode_url = "http://maps.googleapis.com/maps/api/geocode/json?address=#{ URI.escape(addr) }&sensor=false"
geo = uc.get_cached_json(geocode_url)
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

  n = ''
  #puts geo.inspect
  geo['results'][0]['address_components'].each {|h| n = h['short_name'] if h['types'][0] == 'neighborhood' }
  #puts "Neighborhood: #{n}"
  post.set_feature(:neighborhood, n)
end
puts "Matched as #{post.get_feature(:name)}" if post.have_feature?(:name)
puts "Posting score: " + post.get_score.to_s
puts "Scoring log:"
post.get_scoring_log.each do |l|
  puts (l[:delta] > 0 ? "+#{l[:delta]}" : l[:delta].to_s) + " " + l[:reason]
end
