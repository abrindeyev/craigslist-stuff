#!/usr/bin/env ruby

require 'rubygems'
require 'open-uri'
require 'rest-client'
require 'uri'
require 'json'
require 'nokogiri'
require 'lib/address'

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

post = AddressHarvester.new(ARGV[0])
unless post.has_full_address? 
  puts "Can't get full address for that posting, giving up!"
  exit -1
end
addr = post.get_full_address
#unless addr.match(/, Fremont/)
#  addr += ', Fremont CA'
#end

#puts "Checking following address: #{addr}"

geocode_url = "http://maps.googleapis.com/maps/api/geocode/json?address=#{ URI.escape(addr) }&sensor=false"
#puts geocode_url
resp = RestClient.get(geocode_url)
geo = JSON.parse(resp.body)
unless geo['status'] == 'OK'
  puts "Geocode failed: #{geo['status']}"
  exit -1
end
puts "Report for address: #{geo['results'][0]['formatted_address']}"
a_lat = geo['results'][0]['geometry']['location']['lat']
a_lng = geo['results'][0]['geometry']['location']['lng']
posting_city = ''
geo['results'][0]['address_components'].each {|h| posting_city = h['short_name'] if h['types'][0] == 'locality' }
#puts "Posting city is: #{posting_city}"
#puts "Coordinates: #{a_lat},#{a_lng}"

#puts "---------------"

# Caching school ratings
r = {}
rdoc = File.read('ratings.html')
rdoc.scan(/getInfoHtml.'[0-9]+', '([^']+)', '([0-9]+)', '([^']+)', '([^']+)', '([^']+)'/).each do |s|
  r[s[0]] = {
    :rating => s[1],
    :street => s[2],
    :city   => s[3],
    :zip    => s[4]
  }
end

doc = Nokogiri::XML(open('ElementaryN9.kml'))
schools = doc.xpath('//xmlns:Placemark').each do |f|
  poly_raw = f.css('coordinates').first.content
  poly = []
  poly_raw.scan(/[0-9\-\.,]+/).each do |point|
    p_lon, p_lat = point.scan(/[^,]+/)[0..1]
    poly << { 'lat' => p_lat.to_f, 'lon' => p_lon.to_f }
  end
  if contains_point?(poly, { 'lat' => a_lat, 'lon' => a_lng})
    sname = f.css('name').first.content
    full_school_name = ''
    r.keys.each {|full_name| full_school_name = full_name if (full_name.match(sname) and r[full_name][:city] == posting_city)}

    #puts "Matched school: #{ full_school_name }, rating = #{ r[full_school_name][:rating] }"
    #puts "School address: #{ r[full_school_name][:street] }"
    unless full_school_name == ''
      post.set_feature(:school_name, full_school_name)
      post.set_feature(:school_rating, r[full_school_name][:rating].to_i)
      post.set_feature(:school_addr, r[full_school_name][:street])
      directions_url = "http://maps.googleapis.com/maps/api/directions/json?origin=#{ URI.escape(addr) }&destination=#{ URI.escape("#{r[full_school_name][:street]}, #{posting_city}, CA") }&sensor=false&mode=driving"
      resp = RestClient.get(directions_url)
      geo2 = JSON.parse(resp.body)
      unless geo2['status'] == 'OK'
        puts "Directions failed: #{geo['status']}"
        exit -1
      end
      puts "Driving to school by car is #{geo2['routes'][0]['legs'][0]['duration']['text']}"
    end
  end
end

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
puts post.get_features.inspect
