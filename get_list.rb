#!/usr/bin/env ruby

require 'rubygems'
require 'open-uri'
require 'rest-client'
require 'uri'
require 'json'
require 'nokogiri'
require 'lib/address'

source_url = 'http://sfbay.craigslist.org/search/apa/eby?zoomToPosting=&altView=&query=&srchType=A&minAsk=&maxAsk=2200&bedrooms=2&nh=54'
page = Nokogiri::HTML(open(source_url).read, nil, 'UTF-8')
page.xpath("//body/blockquote[@id='toc_rows']/p[@class='row']/a[@href]").each do |a|
  posting_url = a['href']
end
