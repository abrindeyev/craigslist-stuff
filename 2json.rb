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

#ENV['DEBUG'] = 'true'

post = AddressHarvester.new(ARGV[0],nil)
raise "Post has been removed" if post.has_been_removed?

#raise "Full address not detected" unless post.have_full_address?

puts JSON.generate(post.serialize)
