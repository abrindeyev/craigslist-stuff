require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'rest-client'
require 'json'

class SchoolMatcher

  @@schools = nil

  def initialize(lat, lon)
    unless @@schools
      # Caching school ratings
      east_bay_school_ratings = {} # keys are school's full name
      rdoc = File.read((File.join(File.dirname(__FILE__), '..', 'ratings.html')))
      rdoc.scan(/getInfoHtml.'[0-9]+', '([^']+)', '([0-9]+)', '([^']+)', '([^']+)', '([^']+)'/).each do |s|
        east_bay_school_ratings[s[0]] = {
          :rating => s[1],
          :street => s[2],
          :city   => s[3],
          :zip    => s[4]
        }
      end

      # Caching Fremont Elementary schools in an array
      @@schools = []
      doc = Nokogiri::XML(open(File.join(File.dirname(__FILE__), '..', 'ElementaryN9.kml')))

      # iterate through schools, save school's short name and polygon
      doc.xpath('//xmlns:Placemark').each do |f|
        poly_raw = f.css('coordinates').first.content
        poly = []
        poly_raw.scan(/[0-9\-\.,]+/).each do |point|
          p_lon, p_lat = point.scan(/[^,]+/)[0..1]
          poly << { 'lat' => p_lat.to_f, 'lon' => p_lon.to_f }
        end
        short_name = f.css('name').first.content
        @@schools << { :poly => poly, :short_name => short_name }
      end

      # merging school rating's data and schoold polygons
      s = []
      @@schools.each do |school|
        # iterate through East Bay Schools rating list and try to match Fremont school full and short names
        east_bay_school_ratings.keys.each do |fn|
          if fn.match(school[:short_name]) and east_bay_school_ratings[fn][:city].match(/Fremont/i)
            s << school.merge(east_bay_school_ratings[fn])
          end
        end
      end
      @@schools = s
    end
    @point = { 'lat' => lat, 'lon' => lon }

    # Trying to match point to polygon
    @@schools.each do |s|
      if contains_point?(s[:poly], @point)
        @my_school = s
        return s[:short_name]
      end
    end

    self
  end

  def get_schools
    @@schools
  end

  def get_school_name
    return @my_school ? @my_school[:short_name] : nil
  end

  def get_school_address
    return @my_school ? "#{@my_school[:street]}, #{@my_school[:city]}, CA #{@my_school[:zip]}" : nil
  end

  def get_rating
    return @my_school ? @my_school[:rating].to_i : nil
  end

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

end
