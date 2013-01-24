#!/usr/bin/env ruby

require 'rubygems'
require 'open-uri'
require 'rest-client'
require 'uri'
require 'json'
require 'nokogiri'

def contains_point?(poly, p)
  contains_point = false
  i = -1
  j = poly.size - 1
  while (i += 1) < poly.size
    a_point_on_polygon = poly[i]
    trailing_point_on_polygon = poly[j]
    if point_is_between_the_ys_of_the_line_segment?(p, a_point_on_polygon, trailing_point_on_polygon)
      if ray_crosses_through_line_segment?(p, a_point_on_polygon, trailing_point_on_polygon)
        contains_point = !contains_point
      end
    end
    j = i
  end
  return contains_point
end

def point_is_between_the_ys_of_the_line_segment?(point, a_point_on_polygon, trailing_point_on_polygon)
    (a_point_on_polygon['lon'] <= point['lon'] && point['lon'] < trailing_point_on_polygon['lon']) || (trailing_point_on_polygon['lon'] <= point['lon'] && point['lon'] < a_point_on_polygon['lon'])
end

def ray_crosses_through_line_segment?(point, a_point_on_polygon, trailing_point_on_polygon)
    (point['lat'] < (trailing_point_on_polygon['lat'] - a_point_on_polygon['lat']) * (point['lon'] - a_point_on_polygon['lon']) / (trailing_point_on_polygon['lon'] - a_point_on_polygon['lon']) + a_point_on_polygon['lat'])
end

addr = ARGV[0]
unless addr.match(/, Fremont/)
  addr += ', Fremont CA'
end

puts "Checking following address: #{addr}"

geocode_url = "http://maps.googleapis.com/maps/api/geocode/json?address=#{ URI.escape(addr) }&sensor=false"
#puts geocode_url
resp = RestClient.get(geocode_url)
geo = JSON.parse(resp.body)
unless geo['status'] == 'OK'
  puts "Geocode failed: #{geo['status']}"
  exit -1
end
puts "Canonical address: #{geo['results'][0]['formatted_address']}"
a_lat = geo['results'][0]['geometry']['location']['lat']
a_lng = geo['results'][0]['geometry']['location']['lng']
#puts "Coordinates: #{a_lat},#{a_lng}"

puts "---------------"

# Caching school ratings
r = {}
rdoc = File.read('ratings.html')
rdoc.scan(/getInfoHtml.'[0-9]+', '([^']+)', '([0-9]+)'/).each do |s|
  r[s[0]] = s[1]
end

doc = Nokogiri::XML(open('ElementaryN9.kml'))
schools = doc.xpath('//xmlns:Placemark').each do |f|
  #puts f.css('name').first.content
  poly_raw = f.css('coordinates').first.content
  poly = []
  poly_raw.scan(/[0-9\-\.,]+/).each do |point|
    p_lon, p_lat = point.scan(/[^,]+/)[0..1]
    poly << { 'lat' => p_lat.to_f, 'lon' => p_lon.to_f }
  end
  if contains_point?(poly, { 'lat' => a_lat, 'lon' => a_lng})
    sname = f.css('name').first.content
    puts "Matched school: #{ sname }, rating = #{ r.keys.map{|full_name| r[full_name] if full_name.match(sname)}  }"
  
  end
end

directions_url = "http://maps.googleapis.com/maps/api/directions/json?origin=#{ URI.escape(addr) }&destination=Fremont+BART+station&sensor=false&mode=walking"
resp = RestClient.get(directions_url)
geo = JSON.parse(resp.body)
unless geo['status'] == 'OK'
  puts "Directions failed: #{geo['status']}"
  exit -1
end
puts "Walking to Fremont BART: #{geo['routes'][0]['legs'][0]['duration']['text']}"
