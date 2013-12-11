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
      '33584 Alvarado Niles Rd',
      '41111 Mission Blvd.',
      '22693 Hesperian Blvd Ste 100',
      '43341 Mission Blvd.',
    ]
  
    @PDB = {
      'Roberts Lane' => {
        :street => '41240 Roberts Avenue',
        :matchers => ['Roberts Lane'],
        :uri => 'http://www.RentRobertsLane.com',
        :features => {
          :wd => true,
          :ac => true,
          :dw => true,
          :mw => true,
        },
      },
      'Paragon Fremont' => {
        :street => '3700 Beacon Ave',
        :matchers => ['Paragon in Fremont CA', 'liveatparagon.com'],
        :features => {
          :wd => true,
          :ac => true,
        },
      },
      'Villas Papillon' => {
        :street => '4022 Papillon Terrace',
        :matchers => ['VILLAS PAPILLON', '510-490-7833'],
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
      'Archstone Fremont' => {
        :street => '39410 Civic Center Dr',
        :uri => 'http://www.equityapartments.com/abrochure.aspx?PropertyID=4072&s_cid=1001&ILSid=93',
        :matchers => ['866-217-0031'],
        :rentsentinel_key => 'Archstone Fremont Center',
        :features => {
          :wd => true,
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
        :matchers => ['888-727-8177', 'Heritage Village Apartment Homes', 'Heritage Village Apartments'],
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
        :uri => 'http://www.therexford-fremont.com/',
        :matchers => ['The Rexford'],
        :features => {
          :mw => true,
          :dw => true,
          :dpw => true,
        },
      },
      'Amber Court' => {
        :street => '34050 Westchester Terrace',
        :uri => 'http://woodmontrentals.com/amber-court-apartments',
        :matchers => ['Amber Court', '34050 Westchester Terr'],
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
        :uri => 'http://www.pathfindervillageapts.com',
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
        :url => 'www.countrywoodapts.com',
        :matchers => ['Countrywood Apartments', 'countrywoodapts.com', '888-774-3140'],
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
        :matchers => ['Briarwood', '510-657-6322'],
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
        :rentsentinel_key => 'Skylark',
        :features => {},
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
          :mw => true,
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
        :matchers => ['Woods Apartment Homes', 'The Woods', '40640 High St'],
        :features => {
          :wd => true,
        },
      },
      'Garden Village' => {
        :street => '36707 San Pedro Drive',
        :matchers => ['Garden Village Apartments'],
        :features => {
          :wd => false,
          :dw => true,
        },
      },
      'Marbaya' => {
        :street => '36000 Fremont Boulevard',
        :uri => 'http://kcmapts.com/Marbaya',
        :matchers => ['Marbaya'],
        :features => {
        },
      },
      'Creekside Village' => {
        :street => '2999 Sequoia Terrace',
        :uri => 'http://www.sheaapartments.com/apartments/creekside-village/',
        :matchers => ['Creekside Village'],
        :features => {
          :wd => true,
          :dw => true,
        },
      },
      'Eaves Fremont' => {
        :street => '231 Woodcreek Commons',
        :uri => 'http://www.eavesbyavalon.com/california/union-city-apartments/eaves-union-city/',
        :rentsentinel_key => 'eaves Fremont',
        :features => {
          :wd => true,
          :dw => true,
        },
      },
      'Eaves Union City' => {
        :street => '2175 Decoto Road',
        :city => 'Union City',
        :uri => 'http://www.eavesbyavalon.com/california/union-city-apartments/eaves-union-city/',
        :rentsentinel_key => 'eaves Union City',
        :features => {
          :wd => false,
          :dw => true,
        },
      },
      'Hastings Terrace' => {
        :street => '38660 Hastings Street',
        :uri => 'http://www.hastingsterrace.com',
        :matchers => ['HASTINGS TERRACE APTS', '38660 Hastings St'],
        :features => {
          :wd => false,
          :dw => true,
          :ac => true,
        },
      },
      'Durham Greens' => {
        :street => '43555 Grimmer Blvd',
        :matchers => ['Durham Greens'],
        :features => {
          :wd => false,
        },
      },
      'Rancho Luna' => {
        :street => '3939 Monroe Ave',
        :matchers => ['www.RanchoLunaSol.com', 'www.RanchoLunaApts.com', 'www.rancholunaapts.com', 'rancholunasol.com', 'RANCHO LUNA', 'Rancho Luna'],
        :features => {
          :wd => false,
          :ac => true,
          :dw => true,
        },
      },
      'Fremont Park' => {
        :street => '4737 Thornton Avenue',
        :matchers => ['Fremont Park Apartments'],
        :features => {
          :wd => false,
          :ac => true,
          :dw => true,
        },
      },
      'Ardenwood Forest' => {
        :street => '5016 Paseo Padre Pkwy',
        :matchers => ['Ardenwood Forest Condominiums', '888-334-0161'],
        :features => {
          :wd => true,
          :ac => false,
          :dw => true,
          :mw => true,
        },
      },
      'Carriage House' => {
        :street => '3900 Monroe Avenue',
        :matchers => ['CARRIAGE HOUSE', 'www.rentcarriagehouse.com'],
        :features => {
          :wd => false,
          :ac => true,
          :dw => true,
        },
      },
      'Casa Arroyo' => {
        :street => '405 Rancho Arroyo Pkwy',
        :matchers => ['CASA ARROYO', '510-793-8710'],
        :features => {
          :wd => false,
          :dw => true,
        },
      },
      'Suburbian Garden' => {
        :street => '3750 Tamayo Street',
        :matchers => ['Suburbian Garden'],
        :features => {
          :wd => false,
          :dw => true,
          :mw => true,
        },
      },
      'Crossroads Village' => {
        :street => '39438 Stratton Common',
        :matchers => ['Crossroads Village'],
        :features => {
          :wd => false,
        },
      },
      'Royal Pines' => {
        :street => '1440 Mowry Avenue',
        :matchers => ['Royal Pines Apts', '510-793-6878'],
        :features => {
          :wd => false,
          :dw => true,
        }
      }
    }
  end

  def initialize(uri)
    return nil if uri.nil? or uri == ''
    self.init
    if uri.match(/^http:\/\//)
      @source = open(uri).read
    else
      @source = File.read(uri.gsub(/^file:\/\//, ''))
    end
    @source = @source.force_encoding("ISO-8859-1").encode("utf-8", 'replace' => nil) if @source.respond_to?('force_encoding') and @source.respond_to?('encoding')
    @attributes = nil
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

    @doc = Nokogiri::HTML(@source, nil, 'UTF-8')
    @vc = VersionedConfiguration.new(@doc)

    if @source.match(/This posting has been flagged for removal|This posting has been deleted by its author/)
      @post_has_been_removed = true
    else
      @post_has_been_removed = false
      self.parse
    end
    self
  end

  def has_been_removed?
    @post_has_been_removed
  end

  def have_feature?(f)
    @features.include?(f)
  end

  def get_feature(f)
    @features.include?(f) ? @features[f] : nil
  end

  def get_features
    @features
  end

  def set_feature(feature, value)
    @features[feature] = value
  end

  def parse
    @title = get_title()
    @body = get_body()
    @attributes = get_attributes()
    @cltags = get_cltags()
    @posting_info = Hash[*@source.scan(/(Posted|Edited):\s+<date>(.+)<\/date>/).flatten]

    # ----------------------------------------------------------------------------------
    # Getting data for full mailing address (@addr_* variables)
    #
    # 1. Most reliable method -> matching against our own database of patterns
    # 1.1. Tracking of RentSentinel.com postings
    rentsentinel_links = @doc.search('a[@href]').map { |a| a['href'] if a['href'].match(/^http:\/\/ads.rentsentinel.com\/activity\/CLContact.aspx/) }.compact
    if rentsentinel_links.size > 0
      # rentsentinel.com form detected by address
      begin
        rsdoc = Nokogiri::HTML(open(rentsentinel_links[0]).read)
        apartments_name = rsdoc.at_xpath("//body/form/div[@id='contact_container']/div[@id='contact_mainform']/div[@id='divBody']/div[@id='contact_leftcolumn']/h2/text()").to_s.gsub(/^(?:\r|\n| )*/,'').gsub(/(?:\r|\n| )*$/,'')
      rescue
        apartments_name = ''
      end
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
    # 1.1a. Tracking of AptJet.com postings
    aptjet_links = @body.scan(/http:\/\/aptjet.com\/ContactUs\/\?id=[0-9a-z]{1,15}/i)
    if aptjet_links.size > 0
      begin
        rsdoc = open(aptjet_links[0]).read
        redirect_links = rsdoc.scan(/http:\/\/aptjet.com\/activity\/CLContact\.aspx\?[A-Za-z0-9&=]+/i)
        rsdoc = Nokogiri::HTML(open(redirect_links[0]).read)
        apartments_name = rsdoc.at_xpath("//body/form/div[@id='contact_container']/div[@id='contact_mainform']/div[@id='divBody']/div[@id='contact_leftcolumn']/h2/text()").to_s.gsub(/^(?:\r|\n| )*/,'').gsub(/(?:\r|\n| )*$/,'')
      rescue
        apartments_name = ''
      end
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
      addrs = @body.gsub('<br>',' ').gsub("\n",' ').scan(/(\d{1,5}\s+[0-9A-Za-z ]{3,30}\s+(?:st|str|ave|av|avenue|pkwy|parkway|blvd|boulevard|center|circle|cir|commons?|cmn|court|drv|dr|drive|junction|lake|place|plaza|rd|road|street|terrace|ter|way)\.?)\s*(?:(?:apt\.?|unit|#)\s*[A-Za-z0-9]{1,6}?)?,?\s+(fremont|union\s+city|newark|hayward)\s*,?\s*?(?:CA|California)?(?:\s+\d{5})?/i)
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
      gps_data = @doc.at_xpath("//body/article/section[@class='body']/section[@class='userbody']/div[@id='attributes']/div[@id='leaflet']").to_s
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
    if self.has_attribute?('BR')
      self.set_feature(:bedrooms, self.get_attribute('BR'))
    else
      self.set_feature(:bedrooms, $1.to_i) if @title.match(/ (\d)br /)
    end

    # Getting sq ft
    if self.has_attribute?('sqft')
        self.set_feature(:sqft, self.get_attribute('sqft'))
    else
      if @title.match(/(\d{3,4})\s*(?:sq)?ft/)
        self.set_feature(:sqft, $1.to_i)
      elsif @body.match(/([0-9,]{3,6})\s*(?:square foot|sq ?ft|ft)/)
        self.set_feature(:sqft, $1.gsub(/,/,'').to_i)
      end
    end

    if self.has_attribute?('w/d hookups')
      self.set_feature(:hookups, true)
    elsif self.has_attribute?('w/d in unit')
      self.set_feature(:wd, true)
    elsif self.has_attribute?('laundry on site') or self.has_attribute?('laundry in bldg')
        self.set_feature(:coin_laundry, true)
    else
      if @body.match(/hook ?up/i)
        self.set_feature(:hookups, true) if not self.have_feature?(:wd)
      elsif @body.match(/coin(?:-+op(?:erated)*)?\s+(laundry|washer)/i)
        self.set_feature(:coin_laundry, true)
      else
        self.set_feature(:wd, true) if @body.match(/(full\s+size|premium)\s+(washer|dryer)|\bwasher\s*(\/|\&|,|and)\s*dryer|w\/d in unit/i) if self.get_feature(:wd).nil?
      end
    end
    
    if self.has_attribute?('condo') or self.has_attribute?('duplex')
      self.set_feature(:condo, true)
    else
      self.set_feature(:condo, true) if @body.match(/\bcondo/i)
    end

    if self.has_attribute?('townhouse')
      self.set_feature(:townhouse, true)
    else
      self.set_feature(:townhouse, true) if @body.match(/town ?(house|home)/i)
    end
    self.set_feature(:mw, true) if @body.match(/microwave/i)
    self.set_feature(:dpw, true) if @body.match(/(double|dual)[ -]+paned?\s+(energy\s+star\s+)?windows?/i)
    self
  end

  def has_attribute?(attr_name)
    @attributes.has_key?(attr_name)
  end

  def get_attribute(attr_name)
    self.has_attribute?(attr_name) ? @attributes[attr_name] : nil
  end

  def get_attributes
    return @attributes unless @attributes.nil?
    v = self.version
    return {} if v.nil?
    if v < 20130701
      @attributes = {} # atrributes were introduced by Craigslist somewhere in the middle 2013
    else
      @attributes = parse_attributes(@doc.xpath(@vc.get(:attributes_xpath)).to_a)
    end
    @attributes
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
      self.set_feature(:address_was_reverse_geocoded, true)
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
        self.update_score(-100, "Living space is too small: < 799 sqft")
      when 800 .. 999
        self.update_score(-50, "Living space is too small: 800..999 sqft")
      when 1000 .. 1099
        self.update_score(10, "Living space is acceptable: 1,000..1,099 sqft")
      when 1100 .. 1199
        self.update_score(50, "Living space is current: 1,100..1,199 sqft")
      when 1200 .. 1499
        self.update_score(100, "Living space is ideal: 1,200..1,499 sqft")
      when 1500 .. 5000
        self.update_score(-100, "Living space is too large: > 1,500 sqft")
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
        self.update_score(-100, "Unrealistic rent price: < $1,499") # too good to be true
      when 1500 .. 1799
        self.update_score(-50, "Too low rent price: $1,500..$1,799") # too good to be that low
      when 1800 .. 1949
        self.update_score(5, "Neutral rent price: $1,800..$1,949") # almost neutral
      when 1950 .. 2109
        self.update_score(30, "Ideal rent: $1,950..$2,109") # target range
      when 2110 .. 2399
        self.update_score(-50, "Expensive rent: $2,110..$2,399")
      when 2400 .. 10000
        self.update_score(-150, "Can't afford to rent: >$2,400")
      end
    end
    self.update_score(-500, "Has no washer/dryer in unit") if self.have_feature?(:wd) and self.get_feature(:wd) == false
    self.update_score(100, "Has washer/dryer in unit") if self.have_feature?(:wd) and self.get_feature(:wd) == true
    self.update_score(50, "Has washer/dryer hookups") if self.have_feature?(:hookups) and self.get_feature(:hookups) == true
    self.update_score(-150, "Have coin laundry on-site: no W/D") if self.have_feature?(:coin_laundry)
    self.update_score(+10, "No pets requirement") if @body.match(/no\s+pets/i)
    self.update_score(+25, "No smoking requirement") if self.has_attribute?('no smoking') or @body.match(/no\s+(smoke|smoking|smokers)/i)
    self.update_score(-300, "Offers month to month lease") if @body.match(/month(?: |-)+to(?: |-)+month/i)
    unless self.get_feature(:school_rating).nil?
      self.update_score((self.get_feature(:school_rating) - 5) * 20, "School: #{self.get_feature(:school_name)} (#{self.get_feature(:school_rating)})") if self.get_city.match(/fremont/i)
    end
    self.update_score(10, "Have microwave") if self.have_feature?(:mw)
    self.update_score(20, "Condominium / duplex") if self.have_feature?(:condo)
    self.update_score(30, "Townhouse") if self.have_feature?(:townhouse)
    self.update_score(50, "Separate house") if self.has_attribute?('house')
    self.update_score(25, "Has double-pane windows") if self.have_feature?(:dpw)
    self.update_score(-200, "Is furnished") if self.has_attribute?('furnished')
    self.update_score(-250, "Apartment complex") if self.has_attribute?('apartment')

    # Parking
    self.update_score(-50, "Parking is on a street") if self.has_attribute?('off-street parking') or self.has_attribute?('street parking')
    self.update_score(10, "Has detached garage / carport") if self.has_attribute?('carport') or self.has_attribute?('detached garage')
    self.update_score(50, "Has attached garage") if self.has_attribute?('attached garage')

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
    return if @merged_complex == name
    raise "merge_attributes_from_db() already merged while merging [#{name}] after [#{@merged_complex}]" if @merged_complex != ''
    @addr_street = complex[:street]
    @addr_city   = complex.include?(:city) ? complex[:city] : 'Fremont'
    @addr_state  = 'CA'
    self.set_feature(:name, name)
    self.set_feature(:uri, complex[:uri]) if complex.include?(:uri)
    complex[:features].each_pair {|k,v| self.set_feature(k,v)}
    @merged_complex = name
  end

  def get_posting_update_time
    return '' if @posting_info.nil?
    if @posting_info.include?('Posted')
      return @posting_info.has_key?('Edited') ? @posting_info['Edited'] : @posting_info['Posted']
    else
      return ''
    end
  end

  def is_scam?
    # we'll catch most legitimate postings here
    return false if self.have_full_address?

    # scammers hate to leave phone numbers
    # lazy people don't post property addresses
    # but almost always post their cells or emails asking to contact them
    return false if @body.match(/\(?\s*?\d{3}\s*?\)?[. -]*?\d{3}[. -]*?\d{2}[. -]*?\d{2}/)
    return false if @body.match(/[a-zA-Z0-9._]+?@[a-zA-Z0-9.]+?\.[a-zA-Z0-9]{2,5}/)

    # scammers always post in plain-text
    # but some agents use tools like vFlyer marketing
    # which puts entire posting as image file hosted elsewhere
    return false if @body.match(/<img /i)

    # All guessings fails. It's probably a scam now
    return true
  end

  def version
    @vc.get_version
  end

  private

  def get_title
    @doc.at_xpath(@vc.get(:title_xpath)).to_s
  end

  def get_body
    @doc.at_xpath(@vc.get(:body_xpath)).to_s
  end

  def get_cltags
    Hash[*@doc.at_xpath(@vc.get(:cltags_xpath)).to_s.scan(/<!-- CLTAG\s+?([^>]+?)\s+?-->/).flatten.map {|i| a=i.split('='); [a[0], a[1]] }.flatten]
  end

  def parse_attributes(a)
    attrs = {}

    b = []
    a.each do |el|
      s = el.to_s.gsub(/^\s*/, '').gsub(/[\s\n]+\/?$/, '') 
      b << s if s != ''
    end

    # Special case: number of bedrooms
    if b.size > 1 and b[0].match(/(\d)/) and b[1].match(/^BR/)
      attrs['BR'] = b[0].to_i
      b.shift(2)
    end

    # Special case: number of bathrooms
    if b.size > 1 and b[0].match(/(\d(\.\d)?)/) and b[1] == 'Ba'
      attrs['Ba'] = b[0].to_f
      b.shift(2)
    end

    # Special case: square footage
    if b.size > 2 and b[0].match(/(\d+)/) and b[1] == 'ft' and b[2] == '2'
      attrs['sqft'] = b[0].to_i
      b.shift(3)
    end

    # General processing: all other attributes are considered boolean
    b.each { |attr| attrs[attr] = true }

    attrs
  end

end

class VersionedConfiguration

  @@source = nil
  @@VERSIONS = {
    20130101 => {
      :title_xpath => "//body/article/section[@class='body']/h2[@class='postingtitle']",
      :body_xpath => "//body/article/section[@class='body']/section[@class='userbody']/section[@id='postingbody']",
      :attributes_xpath => "/html/body/article/section[@class='body']/section[@class='userbody']/div[@id='attributes']/div[@class='basics']/p/*/text()|/html/body/article/section[@class='body']/section[@class='userbody']/div[@id='attributes']/div[@class='basics']/p/text()",
      :cltags_xpath => "//body/article/section[@class='body']/section[@class='userbody']/section[@class='cltags']",
    },
    20130903 => {
      :attributes_xpath => "/html/body/article/section[@class='body']/section[@class='userbody']/div[@class='mapAndAttrs']/div[@class='attributes']/p[@class='attrgroup']/span[@class='attrbubble']/*/text()|/html/body/article/section[@class='body']/section[@class='userbody']/div[@class='mapAndAttrs']/div[@class='attributes']/p[@class='attrgroup']/span[@class='attrbubble']/text()",
    }
  }

  def initialize(parsed_source)
    @@source = parsed_source
  end

  def get_version
    return @version unless @version.nil?
    @@source.xpath("//p[@class='postinginfo']").each do |l|
      if m = l.to_s.gsub(/<[^>]>/, '').match(/Posted: .*(\d{4}-\d{1,2}-\d{1,2}),/)
        @version = $1.gsub('-', '').to_i
        return @version
      end
    end
    # All guesses failed - version is nil
    return nil
  end

  def get_versions_configuration
    @@VERSIONS
  end

  def get(attribute)
    cv = self.get_version
    return nil if cv.nil?
    versions = self.get_versions_configuration
    conf_candidates_versions = versions.keys.keep_if {|v| v <= cv and versions[v].has_key?(attribute) }.sort.reverse
    conf_candidates_versions.empty? ? nil : versions[conf_candidates_versions.first][attribute]
  end

end