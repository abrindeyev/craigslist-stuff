require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'rest-client'
require 'json'
require 'erb'
require 'htmlentities'

class AddressHarvester

  def init

    @agents_blacklist = [
      '33584 Alvarado Niles Rd'
    ]
  
    @PDB = {
      'VILLAS PAPILLON' => {
        :name => 'Villas Papillon',
        :street => '4022 Papillon Terrace',
        :hookups => true,
        :ac => true,
      },
      'Oak Pointe' => {
        :name => 'Oak Pointe',
        :street => '4140 Irvington Ave',
        :wd => false
      },
      'Watermark Place Apartments' => {
        :name => 'Watermark Place',
        :street => '38680 Waterside Cir',
        :wd => true,
      },
      'Fremont Glen' => {
        :name => 'Fremont Glen',
        :street => '889 Mowry Avenue',
        :wd => true,
      },
      '888-727-8177' => {
        :name => 'Heritage Village',
        :street => '38050 Fremont Blvd',
        :wd => true,
      },
      'Heritage Village Apartment Homes' => {
        :name => 'Heritage Village',
        :street => '38050 Fremont Blvd',
        :wd => true,
      },
      'Bridgeport Apartment Homes' => {
        :name => 'Bridgeport',
        :street => '36826 Cherry Street',
        :wd => false
      },
      'Park Villa Apartments' => {
        :name => 'Park Villa',
        :street => '39501 Fremont Blvd',
        :wd => false
      },
      'The Rexford' => {
        :name => 'Rexford',
        :street => '3400 Country Dr',
        :wd => false,
      },
      'Amber Court Apartment Homes' => {
        :name => 'Amber Court',
        :street => '34050 Westchester Terrace',
        :wd => true,
      },
      'Waterstone' => {
        :name => 'Waterstone',
        :street => '39600 Fremont Boulevard',
        :wd => false
      },
      '41777 Grimmer' => {
        :name => 'Colonial Gardens',
        :street => '41777 Grimmer Boulevard',
        :wd => false
      },
      'Lakeview Apartments' => {
        :name => 'Lakeview',
        :street => '4205 Mowry Avenue',
        :wd => false,
      },
      'Pathfinder Village Apartments' => {
        :name => 'Pathfinder Village',
        :street => '39800 Fremont Blvd',
        :wd => false
      },
      'pathfindervillageapts.com' => {
        :name => 'Pathfinder Village',
        :street => '39800 Fremont Blvd.',
        :wd => false,
      },
      '/stevensonplace/?action' => {
        :name => 'Stevenson Place',
        :street => '4141 Stevenson Boulevard',
        :wd => false,
      },
      'Stevenson Place' => {
        :name => 'Stevenson Place',
        :street => '4141 Stevenson Boulevard',
        :wd => false,
      },
      'CAMBRIDGE COURT' => {
        :name => 'Cambridge Court',
        :street => 'Rodney Common',
        :wd => true,
      },
      'Countrywood Apartments' => {
        :name => 'Countrywood',
        :street => '4555 Thornton Ave',
        :wd => false
      },
      '37200 Paseo' => {
        :name => 'Paseo Place',
        :street => '37200 Paseo Padre Pkwy',
        :wd => false,
      },
      'Trinity Townhomes' => {
        :name => 'Trinity Townhomes',
        :street => '39505 Trinity Way',
        :hookups => true,
      },
      'Alborada Apartments' => {
        :name => 'Alborada',
        :street => '1001 Beethoven Common',
        :wd => true,
      },
      '/ca_alboradaapartments/floorplans/' => {
        :name => 'Alborada',
        :street => '1001 Beethoven Common',
        :wd => true,
      },
      '1001 Beethoven Common' => {
        :name => 'Alborada',
        :street => '1001 Beethoven Common',
        :wd => true,
      },
      'Carrington Apartments' => {
        :name => 'Carrington',
        :street => '4875 Mowry Ave',
        :wd => false,
      },
      'Avalon Fremont' => {
        :name => 'Avalon Fremont',
        :street => '39939 Stevenson Common',
        :wd => true,
        :dw => true,
        :ac => true,
      },
      'Full size -- front load LG washer/dryers' => {
        :name => 'Logan Park Apartments',
        :street => '38304 Logan Dr',
        :wd => true,
      },
      'Briarwood' => {
        :name => 'Briarwood',
        :street => '4200 Bay St',
        :wd => false,
      },
      '2500 Medallion Dr' => {
        :name => 'Medallion',
        :street => '2500 Medallion Drive',
        :city => 'Union City',
        :wd => false,
      },
      'The Presidio Apartments' => {
        :name => 'Presidio',
        :street => '2000 Walnut Ave.',
        :wd => true,
        :ac => true,
        :mw => true,
        :dw => true,
      },
      'Skylark Apartments' => {
        :name => 'Skylark',
        :street => '34655 Skylark Dr',
        :city => 'Union City',
      },
      'rancholunasol.com' => {
        :name => 'Rancho Luna',
        :street => '3939 Monroe Avenue',
        :wd => false,
      },
    }
  end

  def initialize(uri)
    self.init
    if uri.match(/^http:\/\//)
      @source = open(uri).read
    else
      @source = File.read(uri)
    end
    @features = {
      :posting_uri => uri
    }
    @score = 0
    @scoring_log = []

    # Verified address of object in posting
    @addr_street = ''
    @addr_city   = ''
    @addr_state  = ''

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
    self.match_against_database if @body != ''
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

  def match_against_database
    @PDB.keys.each do |pattern|
      if @body.scan(pattern).size > 0
        @addr_street = @PDB[pattern][:street]
        @addr_city   = @PDB[pattern].include?(:city) ? @PDB[pattern][:city] : 'Fremont'
        @addr_state  = 'CA'
        @PDB[pattern].each_pair {|k,v| self.set_feature(k,v)}
        break # allow only first match to prevent mixing up attributes from different db entries
      end
    end
  end

  def have_full_address?
    self.get_full_address == '' ? false : true
  end

  def get_full_address
    return @addr_street == '' ? '' : "#{@addr_street}, #{@addr_city}, #{@addr_state}" if @addr_street != ''
    
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

      # 3.1. Raw address search in posting's body
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

  def update_score(val, reason)
    @score += val
    @scoring_log << { :delta => val, :reason => reason }
  end

  def get_score
    self.update_score(-1000, "City is not a Fremont") unless self.get_city == '' or self.get_city == 'Fremont'
    if self.have_feature?(:sqft)
      case self.get_feature(:sqft)
      when 0 .. 799
        self.update_score(-50, "Area too small: < 799 sqft")
      when 800 .. 899
        self.update_score(5, "Area too small: 800..899 sqft")
      when 900 .. 999
        self.update_score(20, "Area is OK: 900..999 sqft")
      when 1000 .. 1099
        self.update_score(30, "Area is ideal: 1,000..1,099 sqft")
      when 1100 .. 1199
        self.update_score(50, "Area is best: 1,100..1,199 sqft")
      when 1200 .. 1299
        self.update_score(5, "Area is large: 1,200..1,299 sqft")
      when 1300 .. 5000
        self.update_score(-100, "Area is too large: > 1,300 sqft")
      end
    end
    if self.have_feature?(:neighborhood)
      case self.get_feature(:neighborhood)
      when 'Mission San Jose', 'Niles'
        self.update_score(100, "Ideal neighborhood: #{ self.get_feature(:neighborhood) }")
      when 'Irvington'
        self.update_score(10, "Good neighborhood: #{ self.get_feature(:neighborhood) }")
      when 'Centerville'
        self.update_score(-40, "Bad neighborhood: #{ self.get_feature(:neighborhood) }")
      end
    end
    if self.have_feature?(:rent_price)
      case self.get_feature(:rent_price)
      when 0 .. 1499
        self.update_score(-100, "Unrealistic rent price: < $1,500") # too good to be true
      when 1500 .. 1599
        self.update_score(-50, "Too low rent price: $1,500..$1,600") # too good to be that low
      when 1600 .. 1799
        self.update_score(5, "Neutral rent price: $1,600..$1,799") # almost neutral
      when 1800 .. 1999
        self.update_score(20, "Good rent price: $1,800..$1,999") # target range
      when 2000 .. 2099
        self.update_score(-25, "Tough rent price: $2,000..$2,099")
      when 2100 .. 2199
        self.update_score(-50, "Too expensive rent price: $2,100..$2,199")
      when 2200 .. 10000
        self.update_score(-200, "Can't afford to rent: > $2,200")
      end
    end
    self.update_score(-500, "Have no washer/dryer in unit") if self.have_feature?(:wd) and self.get_feature(:wd) == false
    self.update_score(100, "Have washer/dryer in unit") if self.have_feature?(:wd) and self.get_feature(:wd) == true
    self.update_score(50, "Have washer/dryer hookups") if self.have_feature?(:hookups) and self.get_feature(:hookups) == true
    self.update_score(-150, "Have coin laundry on-site: no W/D") if @body.match(/coin(?:-op)?\s+(laundry|washer)/i)
    unless self.get_feature(:school_rating).nil?
      self.update_score(10 * self.get_feature(:school_rating), "School: #{self.get_feature(:school_name)}") if self.get_city.match(/fremont/i)
    end
    @score # return final score
  end

  def get_scoring_log
    @scoring_log
  end

  def get_binding
    binding()
  end

  def get_receipt
    t = ERB.new(open(File.join(File.dirname(__FILE__), '..', 'iphone.erb')).read)
    return t.result(post.get_binding)
  end
end
