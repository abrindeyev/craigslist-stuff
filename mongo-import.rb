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
require './lib/mongodb'

puts '-------------------------------------------------------'

mc = MDB.new.client
err_num = 0

Dir.entries(ARGV[0]).each do |filename|
  next if filename == '.' or filename == '..'
  begin
    uc = URLCacher.new(mc)

    post = AddressHarvester.new("#{ARGV[0]}/#{filename}",mc)
    puts "ID=" + post.get_id.to_s
    next if post.has_been_removed?

    post_data = post.serialize
    post_data[:_id] = {posting_id: post.get_id, updated_at: post.get_posting_update_time}
    next if mc[:import_tracking_ids].find({post_id: post.get_id, updated: post.get_posting_update_time}).count == 1
    mc[:postings].replace_one({_id: {posting_id: post.get_id, updated_at: post.get_posting_update_time}},post_data,{:upsert => true})

    if post.have_full_address?
      canonical_address = post_data[:address][:formatted_address]

      begin
        res = mc[:addresses].update_one({_id: canonical_address, postings: {'$ne':post.get_id}},{"$addToSet":{"postings":{posting_id: post.get_id, updated_at: post.get_posting_update_time}}},{:upsert => true})
        mc[:addresses].update_one({_id: canonical_address},{'$inc':{count:1}}) if not res.upserted_id.nil? or res.modified_count == 1
      rescue Mongo::Error::OperationFailure => e
        raise e if e.message !~ /E11000/
      end

      mc[:import_tracking_ids].update_one({_id: {post_id: post.get_id, updated: post.get_posting_update_time}},{processed_on: DateTime.now},{:upsert => true})

      puts "Report for address: #{canonical_address}"
      a_lat = post_data[:address][:point][:coordinates][1]
      a_lng = post_data[:address][:point][:coordinates][0]

      if post.get_city.match(/fremont/i)
        s = SchoolMatcher.new(a_lat, a_lng)
        post.set_feature(:school_name, s.get_school_name)
        post.set_feature(:school_rating, s.get_rating)
        post.set_feature(:school_addr, s.get_school_address)

        updated_post = post.serialize
        mc[:postings].update_one({_id: {posting_id: post.get_id, updated_at: post.get_posting_update_time}},{'$set': {features: updated_post[:features]}},{:upsert => false})

        n = ''
      end
      puts "Posting score: " + post.get_score.to_s
      #puts "Matched as #{post.get_feature(:name)}" if post.have_feature?(:name)
      #puts "Scoring log:"
      #post.get_scoring_log.each do |l|
      #  puts (l[:delta] > 0 ? "+#{l[:delta]}" : l[:delta].to_s) + " " + l[:reason]
      #end
    else
      puts "Post doesn't have a full address"
    end
  rescue SystemExit, Interrupt
    puts "Import cancelled"
    exit 1
  rescue Exception => e 
    err = "#{e.backtrace.first}: #{e.message} (#{e.class})", e.backtrace.drop(1).map{|s| "\t#{s}"}
    mc[:parse_failures].insert_one({_id: Time.now, filename: filename, err: err})
    puts "********** ERROR"
    err_num = err_num + 1
  end
end
mc[:import_tracking_ids].drop()
puts "Import complete, there were #{err_num} parse errors reported"
