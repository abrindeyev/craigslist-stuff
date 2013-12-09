#!/usr/bin/env ruby

require 'rubygems'
require 'open-uri'
require 'uri'
require 'json'
require 'nokogiri'
require './lib/address'
require './lib/school'

STDOUT.sync = true

stats = {}

d = '/Users/abr/Downloads/craigslist_dumps'
i = 0
Dir.foreach(d) do |f|
  next unless f.match(/^\d+\.html/)
  failure_detected = false
  uri = "#{d}/#{f}"
  begin
    post = AddressHarvester.new(uri)
    i = i + 1
    puts i
  rescue 
    puts "Caught an exception during object creation on #{uri}: #{$!}"
    failure_detected = true
  end
  next if post.nil?
  next if post.has_been_removed?
  post.get_attributes.each_pair do |k,v|
    stats[k] = 0 unless stats.has_key?(k)
    stats[k] += 1
  end
end

s = stats.keys.sort {|x,y| stats[y] <=> stats[x]}
s.each {|o| puts "#{o}: #{stats[o]}"}