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

mc = Mongo::Client.new('mongodb://127.0.0.1:27017/cg')

Dir.entries(ARGV[0]).each do |filename|
  next if filename == '.' or filename == '..'
  post_id=filename.scan(/([0-9]+).html$/).flatten
  puts post_id.inspect
  begin
    #next if mc[:not_worth].find({_id: post_id[0]}).count == 1

    uc = URLCacher.new(mc)

    post = AddressHarvester.new("#{ARGV[0]}/#{filename}",mc)
    puts "ID=" + post.get_id.to_s
    next if post.has_been_removed?

    post_data = post.serialize
    post_data[:_id] = {posting_id: post.get_id, updated_at: post.get_posting_update_time}
    mc[:postings].replace_one({_id: {posting_id: post.get_id, updated_at: post.get_posting_update_time}},post_data,{:upsert => true})

    if post.have_full_address?
      canonical_address = post_data[:address][:formatted_address]

      begin
        mc[:addresses].update_one({_id: canonical_address, postings: {'$ne':post.get_id}},{"$addToSet":{"postings":post.get_id},'$inc':{count:1}},{:upsert => true})
      rescue Mongo::Error::OperationFailure => e
        raise e if e.message !~ /E11000/
      end

      mc[:seen_db].update_one({_id: {post_id: post.get_id, updated: post.get_posting_update_time}},{processed_on: DateTime.now},{:upsert => true})

      puts "Report for address: #{canonical_address}"
      a_lat = post_data[:address][:lat]
      a_lng = post_data[:address][:lon]

      if post.get_city.match(/fremont/i)
        s = SchoolMatcher.new(a_lat, a_lng)
        post.set_feature(:school_name, s.get_school_name)
        post.set_feature(:school_rating, s.get_rating)
        post.set_feature(:school_addr, s.get_school_address)
        #directions_url = "http://maps.googleapis.com/maps/api/directions/json?origin=#{ URI.escape(addr) }&destination=#{ URI.escape(s.get_school_address) }&sensor=false&mode=driving"
        #geo2 = uc.get_cached_json(directions_url)
        #unless geo2['status'] == 'OK'
        #  puts "Directions failed: #{geo['status']}"
        #  exit 1
        #end
        #puts "Driving to school by car is #{geo2['routes'][0]['legs'][0]['duration']['text']}"

        n = ''
        #puts geo.inspect

        #directions_url = "http://maps.googleapis.com/maps/api/directions/json?origin=#{ URI.escape(addr) }&destination=Fremont+BART+station&sensor=false&mode=walking"
        #geo2 = uc.get_cached_json(directions_url)
        #unless geo2['status'] == 'OK'
        #  puts "Directions failed: #{geo2['status']}"
        #  exit -1
        #end
        #puts "Walking to Fremont BART: #{geo2['routes'][0]['legs'][0]['duration']['text']}"
      end
      puts "Matched as #{post.get_feature(:name)}" if post.have_feature?(:name)
      puts "Posting score: " + post.get_score.to_s
      puts "Scoring log:"
      post.get_scoring_log.each do |l|
        puts (l[:delta] > 0 ? "+#{l[:delta]}" : l[:delta].to_s) + " " + l[:reason]
      end
    else
      puts "Post doesn't have a full address"
    end
  rescue SystemExit, Interrupt
    exit 1
  rescue Exception => e 
    mc[:parse_failures].insert_one({_id: Time.now, filename: filename, reason: e.to_s})
  end
end
