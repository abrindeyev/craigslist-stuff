require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'rest-client'
require 'json'

class AddressHarvester

  def init

    @agents_blacklist = [
      '33584 Alvarado Niles Rd'
    ]
  
    @PDB = {
      'VILLAS PAPILLON' => {
        :street => '4022 Papillon Terrace',
        :hookups => true,
        :ac => true,
        :name => 'Villas Papillon Condominiums and Townhouses',
      },
      'Oak Pointe' => {
        :street => '4140 Irvington Ave',
        :wd => false
      },
      'Watermark Place Apartments' => {
        :street => '38680 Waterside Cir',
        :wd => true,
        :name => 'Watermark Place'
      },
      'Fremont Glen' => {
        :street => '889 Mowry Avenue',
        :wd => true,
        :name => 'Fremont Glen'
      },
      '888-727-8177' => {
        :street => '38050 Fremont Blvd',
        :wd => true,
        :name => 'Heritage Village',
      },
      'Heritage Village Apartment Homes' => {
        :street => '38050 Fremont Blvd',
        :wd => true,
        :name => 'Heritage Village',
      },
      'Bridgeport Apartment Homes' => {
        :street => '36826 Cherry Street',
        :wd => false
      },
      'Park Villa Apartments' => {
        :street => '39501 Fremont Blvd',
        :wd => false
      },
      'The Rexford' => {
        :street => '3400 Country Dr',
        :wd => false
      },
      'Amber Court Apartment Homes' => {
        :street => '34050 Westchester Terrace',
        :wd => true,
        :name => 'Amber Court',
      },
      'Waterstone' => {
        :street => '39600 Fremont Boulevard',
        :wd => false
      },
      '41777 Grimmer' => {
        :street => '41777 Grimmer Boulevard',
        :wd => false
      },
      'Lakeview Apartments' => {
        :street => '4205 Mowry Avenue',
        :wd => false
      },
      'Pathfinder Village Apartments' => {
        :street => '39800 Fremont Blvd',
        :wd => false
      },
      '/stevensonplace/?action' => {
        :street => '4141 Stevenson Boulevard',
        :wd => false,
        :name => 'Stevenson Place'
      },
      'Stevenson Place' => {
        :street => '4141 Stevenson Boulevard',
        :wd => false,
        :name => 'Stevenson Place'
      },
      'CAMBRIDGE COURT' => {
        :street => 'Rodney Common',
        :wd => true,
        :name => 'Cambridge Court',
      },
      'Countrywood Apartments' => {
        :street => '4555 Thornton Ave',
        :wd => false
      },
      '37200 Paseo' => {
        :street => '37200 Paseo Padre Pkwy',
        :wd => false
      },
      'Trinity Townhomes' => {
        :street => '39505 Trinity Way',
        :hookups => true,
        :name => 'Trinity Townhomes',
      },
      'Alborada Apartments' => {
        :street => '1001 Beethoven Common',
        :wd => true,
        :name => 'Alborada'
      },
      '1001 Beethoven Common' => {
        :street => '1001 Beethoven Common',
        :wd => true,
        :name => 'Alborada'
      },
      'Carrington Apartments' => {
        :street => '4875 Mowry Ave',
        :wd => false
      },
      'Avalon Fremont' => {
        :street => '39939 Stevenson Common',
        :wd => true,
        :dw => true,
        :ac => true,
        :name => 'Avalon Fremont'
      },
      'Full size -- front load LG washer/dryers' => {
        :street => '38304 Logan Dr',
        :name => 'Logan Park Apartments',
        :wd => true,
      },
      'Briarwood' => {
        :name => 'Briarwood at Central Park',
        :street => '4200 Bay St',
        :wd => false,
      },
      '2500 Medallion Dr' => {
        :name => 'Medallion Apartments',
        :street => '2500 Medallion Drive',
        :city => 'Union City',
        :wd => false,
      },
      'pathfindervillageapts.com' => {
        :name => 'Pathfinder Village Apartments',
        :street => '39800 Fremont Blvd.',
        :wd => false,
      },
      'The Presidio Apartments' => {
        :name => 'Presidio Apartments',
        :street => '2000 Walnut Ave.',
        :wd => true,
        :ac => true,
        :mw => true,
        :dw => true,
      },
      'Skylark Apartments' => {
        :name => 'Skylark Apartments',
        :street => '34655 Skylark Dr',
        :city => 'Union City',
      },
    }
  end

  def initialize(source)
    self.init
    if source.match(/^http:\/\//)
      @source = open(source).read
    else
      @source = File.read(source)
    end
    @features = {}
    self.parse
    self
  end

  def have_feature?(f)
    @features.include?(f)
  end

  def get_feature(f)
    @features.include?(f) ? @features[f] : ''
  end

  def get_features
    @features
  end

  def set_feature(feature, value)
    @features[feature] = value
  end

  def parse
    doc = Nokogiri::HTML(@source, nil, 'UTF-8')
    @title = doc.at_xpath("//body/article/section[@class='body']/h2[@class='postingtitle']/text()").to_s
    @body = doc.at_xpath("//body/article/section[@class='body']/section[@class='userbody']/section[@id='postingbody']").to_s
    @cltags = Hash[*doc.at_xpath("//body/article/section[@class='body']/section[@class='userbody']/section[@class='cltags']").to_s.scan(/<!-- CLTAG\s+?([^>]+?)\s+?-->/).flatten.map {|i| a=i.split('='); [a[0], a[1]] }.flatten]

    # Trying to get GPS coordinates and reverse-geocode them through Google Maps API
    gps_data = doc.at_xpath("//body/article/section[@class='body']/section[@class='userbody']/div[@id='attributes']/div[@id='leaflet']").to_s
    unless gps_data == ''
      @lat = $1 if gps_data.match(/data-latitude="([-0-9.]+?)"/)
      @lon = $1 if gps_data.match(/data-longitude="([-0-9.]+?)"/)
      if @lat and @lon
        revgeocode_url = "http://maps.googleapis.com/maps/api/geocode/json?latlng=#{@lat},#{@lon}&sensor=false"
        resp = RestClient.get(revgeocode_url)
        geo = JSON.parse(resp.body)
        @reverse_geocoded_address_components = Hash[*geo['results'][0]['address_components'].map {|el| [el['types'][0], el['long_name']] }.flatten] if geo['status'] == 'OK' 
      end
    end

    # Getting rent price
    self.set_feature(:rent_price, $1.to_i) if @title.match(/\$(\d{3,4})/)

    # Getting sq ft
    if @title.match(/(\d{3,4})\s*(?:sq)?ft/)
      self.set_feature(:sqft, $1.to_i)
    elsif @body.match(/([0-9,]{3,6})\s*(?:square foot|sq ?ft|ft)/)
      self.set_feature(:sqft, $1.gsub(/,/,'').to_i)
    end
    self.set_feature(:hookups, true) if @body.match(/hookup/)
    self
  end

  def get_tag(tag_name)
    return @cltags.include?(tag_name) ? @cltags[tag_name].strip.squeeze(' ').split(/ /).map{|i| i.capitalize}.join(' ') : ''
  end

  def have_full_address?
    self.get_full_address == '' ? false : true
  end

  def get_full_address
    @addr_street = ''
    @addr_city   = ''
    @addr_state  = ''
    
    if (self.get_tag('xstreet0').match(/^\d{3,5} [A-Z0-9]/) and self.get_tag('city') != '' and self.get_tag('region') != '')
      # 1. we have full address in Craigslist tags. Let's use it!
      @addr_street = self.get_tag('xstreet0')
      @addr_city   = self.get_tag('city')
      @addr_state  = self.get_tag('region')
    elsif not @reverse_geocoded_address_components.nil? and @reverse_geocoded_address_components.include?('street_number') and not @reverse_geocoded_address_components['street_number'].nil?
      # 2. posting have no address specified in tags but have a map with GPS coordinates
      #    Let's use reverse geocoded data which is provided by Google Maps API
      @addr_street = "#{ @reverse_geocoded_address_components['street_number'].gsub(/-.*$/,'') } #{ @reverse_geocoded_address_components['route'] }"
      @addr_city   = @reverse_geocoded_address_components['locality']
      @addr_state  = @reverse_geocoded_address_components['administrative_area_level_1']
    else
      # 3. Begin our gestimates

      # 3.1. Lookup for known pattern in `database'
      @PDB.keys.each do |pattern|
        if @body.scan(pattern).size > 0
          @addr_street = @PDB[pattern][:street]
          @addr_city   = @PDB[pattern][:city] ? @PDB[pattern][:city] : 'Fremont'
          @addr_state  = 'CA'
          @features = @features.merge(@PDB[pattern])
        end
      end

      # 3.2. Raw address search in posting's body
      if @addr_street == ''
        addrs = @body.gsub('<br>',' ').scan(/(\d{1,5} [0-9A-Za-z ]{3,30} (?:st|str|ave|av|avenue|pkwy|parkway|blvd|boulevard|center|circle|drv|dr|drive|junction|lake|place|plaza|rd|road|street|terrace|ter|way)\.?)\s*(?:(?:unit|#)\s*.{1,6}?)?,?\s+(fremont|union\s+city|newark),?\s*?(?:CA|California)(?:\s+\d{5})?/i)
        if addrs.uniq.size > 0
          black_list = Hash[*@agents_blacklist.map {|i|  [i, 1] }.flatten]
          addrs.uniq.each do |a|
            if not black_list.include?(a[0])
              @addr_street = a[0]
              @addr_city   = a[1]
              @addr_state  = 'CA'
            end
          end
        end
      end
    end

    return @addr_street == '' ? '' : "#{@addr_street}, #{@addr_city}, #{@addr_state}"
  end

  def get_city
    self.parse unless @cltags
    return self.have_full_address? ? @addr_city.capitalize : ''
  end

  def get_score
    score = 0
    score -= 1000 unless self.get_city == 'Fremont'
    if self.have_feature?(:sqft)
      case self.get_feature(:sqft)
      when 0 .. 799
        score -= 50 # too small
      when 800 .. 899
        score += 5  # slightly better than now
      when 900 .. 999
        score += 20 # it's ok
      when 1000 .. 1099
        score += 30 # ideal
      when 1100 .. 1199
        score += 50 # best
      when 1200 .. 1300
        score += 5  # maintanance cost start to rise
      when 1300 .. 5000
        score -= 50 # too large
      end
    end
    if self.have_feature?(:neighborhood)
      case self.get_feature(:neighborhood)
      when 'Mission San Jose', 'Niles'
        score += 100
      when 'Irvington'
        score += 10
      when 'Centerville'
        score -= 40
      when 'Central Downtown'
        score += 10
      end
    end
    if self.have_feature?(:rent_price)
      case self.get_feature(:rent_price)
      when 0 .. 1499
        score -= 100 # too good to be true
      when 1500 .. 1599
        score -= 50  # too good to be that low 
      when 1600 .. 1799
        score += 5   # neutral (almost)
      when 1800 .. 1999
        score += 20  # target range
      when 2000 .. 2099
        score -= 25  # tough
      when 2100 .. 2199
        score -= 50  # too expensive
      when 2200 .. 10000
        score -= 200 # can't afford
      end
    end
    score -= 500 if self.have_feature?(:wd) and self.get_feature(:wd) == false
    score += 100 if self.have_feature?(:wd) and self.get_feature(:wd) == true
    score += 50 if self.have_feature?(:hookups) and self.get_feature(:hookups) == true
    score -= 150 if @body.match(/coin(?:-op)?\s+(laundry|washer)/i)
    unless self.get_feature(:school_rating).nil?
      score += 10 * self.get_feature(:school_rating) if self.get_city.match(/fremont/i)
    end
    score # return final score
  end
  # Scoring
  # :neighborhood=>"Mission San Jose" +100
  # :sqft=>1050
  # :rent_price=>1825
  #
  #
end
