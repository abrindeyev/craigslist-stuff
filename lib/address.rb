require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'rest-client'
require 'json'

class AddressHarvester

  def init
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
      'Stevenson Place' => {
        :street => '4141 Stevenson Boulevard',
        :wd => false
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
    @cltags = Hash[*doc.at_xpath("//body/article/section[@class='body']/section[@class='userbody']/section[@class='cltags']").to_s.scan(/<!-- CLTAG (.*?) -->/).flatten.map {|i| a=i.split('='); [a[0], a[1]] }.flatten]
    gps_data = doc.at_xpath("//body/article/section[@class='body']/section[@class='userbody']/div[@id='attributes']/div[@id='leaflet']").to_s
    unless gps_data == '' and @cltags['xstreet0'] =~ /^\d+ [a-zA-Z]+/
      @lat = $1 if gps_data.match(/data-latitude="([-0-9.]+?)"/)
      @lon = $1 if gps_data.match(/data-longitude="([-0-9.]+?)"/)
      revgeocode_url = "http://maps.googleapis.com/maps/api/geocode/json?latlng=#{@lat},#{@lon}&sensor=false"
      resp = RestClient.get(revgeocode_url)
      geo = JSON.parse(resp.body)
      unless geo['status'] == 'OK'
        puts "Geocode failed: #{geo['status']}"
        exit -1
      end
      @formatted_address = geo['results'][0]['formatted_address']
    end

    # Getting rent price
    self.set_feature(:rent_price, $1.to_i) if @title.match(/\$(\d{3,4})/)

    # Getting sq ft
    if @title.match(/(\d{3,4})\s*(?:sq)?ft/)
      self.set_feature(:sqft, $1.to_i)
    elsif @body.match(/([0-9,]{3,6})\s*(?:square foot|sq ?ft|ft)/)
      self.set_feature(:sqft, $1.gsub(/,/,'').to_i)
    end
    if @cltags.include?('city')
      @cltags['city'].gsub(/^\s+/, '')
      @cltags['city'].gsub(/\s+$/, '')
    end
    self.set_feature(:hookups, true) if @body.match(/hookup/)
    self
  end

  def get_tag(tag_name)
    @cltags[tag_name]
  end

  def has_full_address_pvt?
    return false unless @cltags['xstreet0'] =~ /^(\d{1,5}(\ 1\/[234])?[ A-Za-z]+)/ or @formatted_address != ''
  end

  def has_full_address?
    #return false unless @cltags.include?('xstreet0')
    if self.has_full_address_pvt?
      @street_address = @cltags['xstreet0']
      return true
    else
      self.get_full_address
      if @street_address == '' and @formatted_address == ''
        return false
      else
        return true
      end
    end
  end

  def get_full_address
    self.parse unless @cltags
    return @formatted_address if @formatted_address =~ /^\d{3,5}/
    unless self.has_full_address_pvt?
      # Let's begin our gestimates here!

      # 1. Lookup for known database
      @PDB.keys.each do |pattern|
        if @body.scan(pattern).size > 0
          @street_addr = @PDB[pattern][:street] if @body.scan(pattern).size > 0
          @features = @features.merge(@PDB[pattern])
        end
      end

      # 2. Raw address search
      #addrs = @body.scan(/^(?n:(?<address1>(\d{1,5}(\ 1\/[234])?(\x20[A-Z]([a-z])+)+ )|(P\.O\.\ Box\ \d{1,5}))\s{1,2}(?i:(?<address2>(((APT|B LDG|DEPT|FL|HNGR|LOT|PIER|RM|S(LIP|PC|T(E|OP))|TRLR|UNIT)\x20\w{1,5})|(BSMT|FRNT|LBBY|LOWR|OFC|PH|REAR|SIDE|UPPR)\.?)\s{1,2})?)(?<city>[A-Z]([a-z])+(\.?)(\x20[A-Z]([a-z])+){0,2})\, \x20(?<state>A[LKSZRAP]|C[AOT]|D[EC]|F[LM]|G[AU]|HI|I[ADL N]|K[SY]|LA|M[ADEHINOPST]|N[CDEHJMVY]|O[HKR]|P[ARW]|RI|S[CD] |T[NX]|UT|V[AIT]|W[AIVY])\x20(?<zipcode>(?!0{5})\d{5}(-\d {4})?))$/)
      unless @street_addr
        addrs = @body.gsub('<br>',' ').scan(/(\d{1,5} [a-za-z ]+ (?:st|str|ave|avenue|pkwy|parkway|bldv|boulevard|center|circle|drv|dr|drive|junction|lake|place|plaza|rd|road|street|terrace))\s+(fremont|union\s+city|newark),? ca\s+\d{5}/i)
        if addrs.uniq.size > 0
          @cltags['xstreet0'] = addrs.uniq[0][0]
          @cltags['city'] = addrs.uniq[0][1]
          @cltags['region'] = 'CA'
        end
        #puts addrs.uniq.inspect
      end
    end
    return "#{@street_addr =~ /^\d+/ ? @street_addr : @cltags['xstreet0'] }, #{@cltags['city']}, #{@cltags['region']}"
  end

  def get_city
    self.parse unless @cltags
    return self.has_full_address ? @cltags['city'].capitalize : ''
  end

  # Scoring
  # :neighborhood=>"Mission San Jose" +100
  # :sqft=>1050
  # :rent_price=>1825
  #
  #
end
