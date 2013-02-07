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
      'Villas Papillon' => {
        :street => '4022 Papillon Terrace',
        :matchers => ['VILLAS PAPILLON'],
        :features => {
          :hookups => true,
          :ac => true,
        },
      },
      'Oak Pointe' => {
        :street => '4140 Irvington Ave',
        :matchers => ['Oak Pointe'],
        :features => {
          :wd => false,
        },
      },
      'Watermark Place' => {
        :street => '38680 Waterside Cir',
        :uri => 'http://www.watermarkplace.com',
        :matchers => ['Watermark Place Apartments'],
        :rentsentinel_key => 'Watermark Place',
        :features => {
          :wd => true,
        },
      },
      'Fremont Glen' => {
        :street => '889 Mowry Avenue',
        :matchers => ['Fremont Glen'],
        :features => {
          :wd => true,
        },
      },
      'Heritage Village' => {
        :street => '38050 Fremont Blvd',
        :matchers => ['888-727-8177', 'Heritage Village Apartment Homes'],
        :rentsentinel_key => 'Heritage Village Apartments',
        :features => {
          :wd => true,
        },
      },
      'Bridgeport' => {
        :street => '36826 Cherry Street',
        :matchers => ['Bridgeport Apartment Homes'],
        :features => {
          :wd => false,
        },
      },
      'Park Villa' => {
        :street => '39501 Fremont Blvd',
        :matchers => ['Park Villa Apartments'],
        :features => {
          :wd => false,
        },
      },
      'Rexford' => {
        :street => '3400 Country Dr',
        :matchers => ['The Rexford'],
        :features => {
          :wd => false,
        },
      },
      'Amber Court' => {
        :street => '34050 Westchester Terrace',
        :matchers => ['Amber Court Apartment Homes'],
        :features => {
          :wd => true,
        },
      },
      'Waterstone' => {
        :street => '39600 Fremont Boulevard',
        :matchers => ['Waterstone'],
        :features => {
          :wd => false,
        },
      },
      'Colonial Gardens' => {
        :street => '41777 Grimmer Boulevard',
        :uri => 'http://www.woodmontrentals.com/colonial-gardens-apartments/',
        :rentsentinel_key => 'Colonial Gardens Apartments',
        :matchers => ['41777 Grimmer'],
        :features => {
          :wd => false,
        },
      },
      'Lakeview' => {
        :street => '4205 Mowry Avenue',
        :matchers => ['Lakeview Apartments'],
        :features => {
          :wd => false,
        },
      },
      'Pathfinder Village' => {
        :street => '39800 Fremont Blvd',
        :matchers => ['Pathfinder Village Apartments', 'pathfindervillageapts.com'],
        :features => {
          :wd => false,
        },
      },
      'Stevenson Place' => {
        :street => '4141 Stevenson Boulevard',
        :matchers => ['Stevenson Place', '/stevensonplace/?action'],
        :features => {
          :wd => false,
        },
      },
      'Cambridge Court' => {
        :street => 'Rodney Common',
        :matchers => ['CAMBRIDGE COURT'],
        :features => {
          :wd => true,
        },
      },
      'Countrywood' => {
        :street => '4555 Thornton Ave',
        :matchers => ['Countrywood Apartments'],
        :rentsentinel_key => 'Countrywood Apartment Homes',
        :features => {
          :wd => false,
        },
      },
      'Paseo Place' => {
        :street => '37200 Paseo Padre Pkwy',
        :matchers => ['37200 Paseo'],
        :features => {
          :wd => false,
        },
      },
      'Trinity Townhomes' => {
        :street => '39505 Trinity Way',
        :matchers => ['Trinity Townhomes'],
        :features => {
          :hookups => true,
        },
      },
      'Alborada' => {
        :street => '1001 Beethoven Common',
        :matchers => ['Alborada Apartments', '/ca_alboradaapartments/floorplans/', '1001 Beethoven Common'],
        :rentsentinel_key => ['Alborada', 'Alborada Apartments'],
        :features => {
          :wd => true,
        },
      },
      'Carrington' => {
        :street => '4875 Mowry Ave',
        :matchers => ['Carrington Apartments'],
        :features => {
          :wd => false,
        },
      },
      'Avalon Fremont' => {
        :street => '39939 Stevenson Common',
        :matchers => ['Avalon Fremont'],
        :features => {
          :wd => true,
          :dw => true,
          :ac => true,
        },
      },
      'Avalon Union City' => {
        :street => '24 Union Square',
        :city => 'Union City',
        :uri => 'http://www.avaloncommunities.com/california/union-city-apartments/avalon-union-city/',
        :rentsentinel_key => 'Avalon Union City',
        :features => {
          :wd => true,
          :dw => true,
          :ac => true,
        },
      },
      'Logan Park Apartments' => {
        :street => '38304 Logan Dr',
        :matchers => ['Full size -- front load LG washer/dryers'],
        :features => {
          :wd => true,
        },
      },
      'Briarwood' => {
        :street => '4200 Bay St',
        :matchers => ['Briarwood'],
        :features => {
          :wd => false,
        },
      },
      'Medallion' => {
        :street => '2500 Medallion Drive',
        :city => 'Union City',
        :matchers => ['2500 Medallion Dr'],
        :features => {
          :wd => false,
        },
      },
      'Presidio' => {
        :street => '2000 Walnut Ave.',
        :matchers => ['The Presidio Apartments'],
        :features => {
          :wd => true,
          :ac => true,
          :mw => true,
          :dw => true,
        },
      },
      'Skylark' => {
        :street => '34655 Skylark Dr',
        :city => 'Union City',
        :matchers => ['Skylark Apartments'],
        :features => {},
      },
      'Rancho Luna' => {
        :street => '3939 Monroe Avenue',
        :matchers => ['rancholunasol.com'],
        :features => {
          :wd => false,
        },
      },
      'Pebble Creek' => {
        :street => '40777 High Street, Fremont, CA 94538',
        :uri => 'http://www.pebblecreekcommunities.com',
        :matchers => ['Pebble Creek Communities', '510-651-9080'],
        :features => {
          :dw => true,
          :mw => true,
          :ac => true,
        },
      },
      'Monte Merano' => {
        :street => '39149 Guardino Drive',
        :matchers => ['Monte Merano'],
        :features => {
          :wd => true,
        },
      },
      'Logan Park' => {
        :street => '38200 Logan Drive',
        :matchers => ['Logan Park Apartments'],
        :features => {
          :wd => false,
        },
      },
      'Mission Peaks I' => {
        :street => '1401 Red Hawk Circle',
        :rentsentinel_key => 'Mission Peaks I',
        :features => {
          :wd => true,
        },
      },
      'Mission Peaks II' => {
        :street => '39451 Gallaudet Drive',
        :rentsentinel_key => 'Mission Peaks II',
        :features => {
          :wd => true,
        },
      },
      'Parkside' => {
        :street => '1501 Decoto Road',
        :city => 'Union City',
        :rentsentinel_key => 'Parkside',
        :features => {
          :dw => true,
          :ac => true,
        },
      },
      'Verandas' => {
        :street => '33 Union Square',
        :city => 'Union City',
        :uri => 'http://www.breproperties.com/california/union-city-apartments/verandas/sfo1108#/Community-Overview',
        :rentsentinel_key => 'Verandas',
        :features => {
          :dw => true,
          :ac => true,
          :wd => true,
        },
      },
      'Pepper Tree' => {
        :street => '37767 Fremont Blvd.',
        :uri => 'http://thepeppertreeapartments.com',
        :matchers => ['Pepper Tree Apartments'],
        :features => {
          :wd => false,
        },
      },
      'Boulevard' => {
        :street => '40001 Fremont Boulevard',
        :uri => 'http://www.essexapartmenthomes.com/apartment/boulevard-apartment-homes-fremont-ca-8i04lx170701',
        :matchers => ['Boulevard Apartment Homes'],
        :features => {
        },
      },
      'Arbordale Gardens' => {
        :street => '42010 Blacow Rd',
        :uri => 'http://arbordalegardens.com',
        :matchers => ['Arbordale Gardens'],
        :features => {
          :wd => false,
          :dw => true,
          :parking_lots => 1,
        },
      },
      'Woods' => {
        :street => '40640 High St.',
        :uri => 'http://www.essexapartmenthomes.com/apartment/the-woods-fremont-ca-5ti800170664',
        :matchers => ['Woods Apartment Homes'],
        :features => {
          :wd => true,
        },
      },
    }
  end

  def initialize(uri)
    return nil if uri.nil? or uri == ''
    self.init
    if uri.match(/^http:\/\//)
      @source = open(uri).read
    else
      @source = File.read(uri)
    end
    @features = {
      :posting_uri => uri
    }
    @merged_complex = ''
    @score = nil
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
    @cltags = Hash[*doc.at_xpath("//body/article/section[@class='body']/section[@class='userbody']/section[@class='cltags']").to_s.scan(/<!-- CLTAG\s+?([^>]+?)\s+?-->/).flatten.map {|i| a=i.split('='); [a[0], a[1]] }.flatten]

    # ----------------------------------------------------------------------------------
    # Getting data for full mailing address (@addr_* variables)
    #
    # 1. Most reliable method -> matching against our own database of patterns
    # 1.1. Tracking of RentSentinel.com postings
    rentsentinel_links = doc.search('a[@href]').map { |a| a['href'] if a['href'].match(/^http:\/\/ads.rentsentinel.com\/activity\/CLContact.aspx/) }.compact
    if rentsentinel_links.size > 0
      # rentsentinel.com form detected by address
      rsdoc = Nokogiri::HTML(open(rentsentinel_links[0]).read)
      apartments_name = rsdoc.at_xpath("//body/form/div[@id='contact_container']/div[@id='contact_mainform']/div[@id='divBody']/div[@id='contact_leftcolumn']/h2/text()").to_s.gsub(/^(?:\r|\n| )*/,'').gsub(/(?:\r|\n| )*$/,'')
      if apartments_name != ''
        # trying to find a match in our database
        @PDB.each_pair do |name, complex|
          if complex.include?(:rentsentinel_key)
            matchers = complex[:rentsentinel_key].kind_of?(String) ? [ complex[:rentsentinel_key] ] : complex[:rentsentinel_key]
            matchers.each do |pattern|
              self.merge_attributes_from_db(name, complex) if pattern == apartments_name
            end
          end
        end
      end
    end

    # 1.2. Looking for known patterns in posting's body
    self.match_against_database if @body != '' if @addr_street == ''

    # 2. Looking for raw mailing addresses in posting's body
    if @addr_street == ''
      addrs = @body.gsub('<br>',' ').scan(/(\d{1,5} [0-9A-Za-z ]{3,30} (?:st|str|ave|av|avenue|pkwy|parkway|blvd|boulevard|center|circle|drv|dr|drive|junction|lake|place|plaza|rd|road|street|terrace|ter|way)\.?)\s*(?:(?:apt\.?|unit|#)\s*.{1,6}?)?,?\s+(fremont|union\s+city|newark),?\s*?(?:CA|California)(?:\s+\d{5})?/i)
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

    # 3. Trying to get GPS coordinates and reverse-geocode them through Google Maps API
    if @addr_street == ''
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
    end
    # ----------------------------------------------------------------------------------

    # Getting rent price
    self.set_feature(:rent_price, $1.to_i) if @title.match(/\$(\d{3,4})/)

    # Getting # of bedrooms
    self.set_feature(:bedrooms, $1.to_i) if @title.match(/ (\d)br /)

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
    @PDB.each_pair do |name, complex|
      if complex.include?(:matchers)
        complex[:matchers].each do |pattern|
          self.merge_attributes_from_db(name, complex) if @body.scan(pattern).size > 0
        end
      end
    end
  end

  def get_state
    @addr_state.length == 2 ? @addr_state.upcase : @addr_state.capitalize
  end

  def have_full_address?
    self.get_full_address == '' ? false : true
  end

  def get_full_address
    # returning full mailing address if it was previously parsed inside parse()
    return @addr_street == '' ? '' : "#{@addr_street}, #{@addr_city}, #{self.get_state}" if @addr_street != ''
    
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
    end

    # return empty string if all gestimates failed
    return @addr_street == '' ? '' : "#{@addr_street}, #{@addr_city}, #{self.get_state}"
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
    return @score unless @score.nil?
    @score = 0
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
      when 'Mission San Jose', 'Niles', 'Parkmont'
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
      when 2000 .. 10000
        self.update_score(-150, "Can't afford to rent: $2,000..$10,000")
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
    return t.result(self.get_binding)
  end

  def get_filename
    return self.have_feature?(:posting_uri) ? self.get_feature(:posting_uri).match(/\d+\.html/).to_s : nil
  end

  def backup_source_to(dir)
    return false unless File.exists?(dir)
    File.open(File.join(dir, self.get_filename), 'w') do |f|
      f.write(@source)
    end
  end

  def merge_attributes_from_db(name, complex)
    raise "merge_attributes_from_db() already merged while merging [#{name}] after [#{@merged_complex}]" if @merged_complex != ''
    @addr_street = complex[:street]
    @addr_city   = complex.include?(:city) ? complex[:city] : 'Fremont'
    @addr_state  = 'CA'
    self.set_feature(:name, name)
    self.set_feature(:uri, complex[:uri]) if complex.include?(:uri)
    complex[:features].each_pair {|k,v| self.set_feature(k,v)}
    @merged_complex = name
  end

end
