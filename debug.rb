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

ENV['DEBUG'] = 'true'

mc = Mongo::Client.new('mongodb://127.0.0.1:2456/cg')
uc = URLCacher.new(mc)

post = AddressHarvester.new(ARGV[0],mc)
raise "Post has been removed" if post.has_been_removed?

#raise "Full address not detected" unless post.have_full_address?

puts JSON.generate(post.serialize)
