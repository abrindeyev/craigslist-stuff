require File.join(File.dirname(__FILE__), '..', 'lib', 'address')
mc = nil

def s(sample_filename)
  File.join(File.dirname(__FILE__), 'samples', sample_filename)
end

describe "#new" do
  context "with mc parameter" do
    it "should return empty object with mc" do
      AddressHarvester.new(nil,mc).should be_an_instance_of AddressHarvester
    end
  end
  context "with local filename" do
    it "should return object reference" do
      post = AddressHarvester.new(s('3574423811.html'),mc)
      post.should_not be_nil
    end
    it "shouldn't have # of bedrooms" do
      AddressHarvester.new(s('removed.html'),mc).have_feature?(:bedrooms).should eql false
    end
    it "should return correct # of bedrooms" do
      AddressHarvester.new(s('3574423811.html'),mc).get_feature(:bedrooms).should eql 2
    end
    it "shoudn't have valid address for simple postings without map and inline address" do
      AddressHarvester.new(s('3598149448.html'),mc).have_full_address?.should eql false
    end
    it "should detect deleted posting" do
      AddressHarvester.new(s('deleted.html'),mc).has_been_removed?.should eql true
    end
    it "should detect removed posting" do
      AddressHarvester.new(s('removed.html'),mc).has_been_removed?.should eql true
    end
    it "should get xstreet0 tag value" do 
      AddressHarvester.new(s('3574423811.html'),mc).get_tag('xstreet0').should eql '120 Granada'
    end
    it "should return city from 'city' tag" do
      AddressHarvester.new(s('3574423811.html'),mc).get_tag('city').should eql 'Mountain View'
    end
    it "should return state from 'region' tag" do
      AddressHarvester.new(s('3574423811.html'),mc).get_tag('region').should == 'Ca'
    end
    it "should not return tag if it skipped in original post" do
      AddressHarvester.new(s('3574419831.html'),mc).get_tag('region').should_not == 'CA'
    end
    it "should detect city from posting with image" do
      AddressHarvester.new(s('3587401701.html'),mc).get_city.should eql 'Fremont'
    end
  end
end

describe "Posting info parser" do
  it "should return posted date when post wasn't updated yet" do
    AddressHarvester.new(s('3574419831.html'),mc).get_posting_update_time.strftime("%Y-%m-%dT%H%M%S%z").should eql '2013-01-26T210400-0800'
  end
  it "should return updated date when post was updated" do
    AddressHarvester.new(s('3602181818.html'),mc).get_posting_update_time.strftime("%Y-%m-%dT%H%M%S%z").should eql '2013-02-07T232900-0800'
  end
  it "should return empty string when post was removed" do
    AddressHarvester.new(s('removed.html'),mc).get_posting_update_time.should eql ''
  end
end

describe "Apartments detector" do
  it "should detect 'Pebble Creek Communities'" do
    AddressHarvester.new(s('3598509706.html'),mc).get_feature(:name).should eql 'Pebble Creek'
  end
  it "should detect 'Woods'" do
    AddressHarvester.new(s('3599422360.html'),mc).get_feature(:name).should eql 'Woods'
  end
  it "should detect 'Creekside Village'" do
    AddressHarvester.new(s('3605593473.html'),mc).get_feature(:name).should eql 'Creekside Village'
  end
  it "should detect 'Rancho Luna' #1" do
    AddressHarvester.new(s('3987415202.html'),mc).get_feature(:name).should eql 'Rancho Luna'
  end
  it "should detect 'Rancho Luna' #2" do
    AddressHarvester.new(s('3987670153.html'),mc).get_feature(:name).should eql 'Rancho Luna'
  end
  it "should detect 'Rancho Luna' #3" do
    AddressHarvester.new(s('3992986304.html'),mc).get_feature(:name).should eql 'Rancho Luna'
  end
  it "should detect 'Rancho Luna' #4" do
    AddressHarvester.new(s('3991905116.html'),mc).get_feature(:name).should eql 'Rancho Luna'
  end
  it "should detect 'Fremont Park'" do
    AddressHarvester.new(s('3982386449.html'),mc).get_feature(:name).should eql 'Fremont Park'
  end
  it "should detect 'Ardenwood Forest'" do
    AddressHarvester.new(s('3978588955.html'),mc).get_feature(:name).should eql 'Ardenwood Forest'
  end
  it "should detect 'Carriage House'" do
    AddressHarvester.new(s('3993236430.html'),mc).get_feature(:name).should eql 'Carriage House'
  end
  it "should detect 'Casa Arroyo'" do
    AddressHarvester.new(s('3993519528.html'),mc).get_feature(:name).should eql 'Casa Arroyo'
  end
  it "should detect 'Suburbian Garden'" do
    AddressHarvester.new(s('3991884178.html'),mc).get_feature(:name).should eql 'Suburbian Garden'
  end
  it "should detect 'Garden Village Apartments'" do
    AddressHarvester.new(s('4028997623.html'),mc).get_feature(:name).should eql 'Garden Village'
  end
  it "should detect 'Royal Pines Apartments'" do
    AddressHarvester.new(s('4232230901.html'),mc).get_feature(:name).should eql 'Royal Pines'
  end
  it "should detect 'Countrywood Apartments'" do
    AddressHarvester.new(s('4222894211.html'),mc).get_feature(:name).should eql 'Countrywood'
  end
end

describe "Score engine" do
  it "should return non-mc score for postings without any address" do
    AddressHarvester.new(s('3598149448.html'),mc).get_score.should_not be_nil
  end
  it "should return digital score for postings without any address" do
    AddressHarvester.new(s('3598149448.html'),mc).get_score.should be_a(Integer)
  end
end

describe "Raw address detector" do
  it "should return '40711 Robin Street, Fremont, California'" do
    AddressHarvester.new(s('3599138803.html'),mc).get_full_address.should eql '40711 Robin Street, Fremont, California'
  end
  it "should return '23 Raintree Court, Hayward, California'" do
    AddressHarvester.new(s('3601613904.html'),mc).get_full_address.should eql '23 Raintree Court, Hayward, California'
  end
  it "should return '38700 Tyson Lane, Fremont, California'" do
    AddressHarvester.new(s('3585854056.html'),mc).get_full_address.should eql '38700 Tyson Lane, Fremont, California'
  end
  it "shouldn't detect full address from fuzzy reverse geocode requests" do
    AddressHarvester.new(s('3584993361.html'),mc).have_full_address?.should be false
  end
  it "should return '39800 Fremont Boulevard, Fremont, California'" do
    AddressHarvester.new(s('3587519103.html'),mc).get_full_address.should eql '39800 Fremont Boulevard, Fremont, California'
  end
  it "should return '5647 Robertson Avenue, Newark, California'" do
    AddressHarvester.new(s('3584363870.html'),mc).get_full_address.should eql '5647 Robertson Avenue, Newark, California'
  end
  it "should return '40640 High Street, Fremont, California'" do
    AddressHarvester.new(s('3587462071.html'),mc).get_full_address.should eql '40640 High Street, Fremont, California'
  end
  it "should return '43314 Jerome Avenue, Fremont, California'" do
    AddressHarvester.new(s('3587303805.html'),mc).get_full_address.should eql '43314 Jerome Avenue, Fremont, California'
  end
  it "should return '4193 Rainbow Terrace, Fremont, California'" do
    AddressHarvester.new(s('3587286246.html'),mc).get_full_address.should eql '4193 Rainbow Terrace, Fremont, California'
  end
  it "should return '31770 Alvarado Boulevard, Union City, California'" do
    AddressHarvester.new(s('3591502030.html'),mc).get_full_address.should eql '31770 Alvarado Boulevard, Union City, California'
  end
  it "should return '4022 Papillon Terrace, Fremont, California'" do
    AddressHarvester.new(s('3573633080.html'),mc).get_full_address.should eql '4022 Papillon Terrace, Fremont, California'
  end
  it "should return '4181 Asimuth Circle, Union City, California'" do
    AddressHarvester.new(s('3619322293.html'),mc).get_full_address.should eql '4181 Asimuth Circle, Union City, California'
  end
  it "should return '38593 Royal Ann Common, Fremont, California'" do
    AddressHarvester.new(s('3626121593.html'),mc).get_full_address.should eql '38593 Royal Ann Common, Fremont, California'
  end
  it "should return '37120 Spruce Street, Newark, California'" do
    AddressHarvester.new(s('3633731850.html'),mc).get_full_address.should eql '37120 Spruce Street, Newark, California'
  end
  it "should return '37155 Aspenwood Common, Fremont, California'" do
    AddressHarvester.new(s('4232384330.html'),mc).get_full_address.should eql '37155 Aspenwood Common, Fremont, California'
  end
  it "should return '42643 Charleston Way, Fremont, California'" do
    AddressHarvester.new(s('4298442714.html'),mc).get_full_address.should eql '42643 Charleston Way, Fremont, California'
  end
  it "should return '34310 Newton Court, Fremont, California'" do
    AddressHarvester.new(s('4298110333.html'),mc).get_full_address.should eql '34310 Newton Court, Fremont, California'
  end
  it "should return 'Serpa Court & Felicio Common, Fremont, California'" do
    AddressHarvester.new(s('4939459448.html'),mc).get_full_address.should eql 'Serpa Court & Felicio Common, Fremont, California'
  end
  it "should return '38662 Country Terrace, Fremont, California'" do 
    AddressHarvester.new(s('5379302252.html'),mc).get_full_address.should eql '38662 Country Terrace, Fremont, California'
  end
  it "should return '34132 Cavendish Place, Fremont, California'" do 
    AddressHarvester.new(s('5381678364.html'),mc).get_full_address.should eql '34132 Cavendish Place, Fremont, California'
  end
  it "should return '615 Balsam Terrace, Fremont, California'" do 
    AddressHarvester.new(s('5922274850.html'),mc).get_full_address.should eql '615 Balsam Terrace, Fremont, California'
  end
  it "should return '37879 3rd Street, Fremont, California'" do 
    AddressHarvester.new(s('4234294131.html'),mc).get_full_address.should eql '37879 3rd Street, Fremont, California'
  end
  it "should return '34529 Mahogany Lane, Union City, California'" do 
    AddressHarvester.new(s('5953880532.html'),mc).get_full_address.should eql '34529 Mahogany Lane, Union City, California'
  end
end

describe "Mapbox address detector" do
  it "should return '4845 Mendota St, Union City, CA 94587, USA'" do
    AddressHarvester.new(s('5693112857.html'),mc).get_full_address.should eql '4845 Mendota Street, Union City, California'
  end
end

describe "Washer/dryer/hookups fuzzy detector" do
  it "should detect washer and dryer #1" do
    AddressHarvester.new(s('3564576923.html'),mc).have_feature?(:wd).should be true
  end
  it "should detect washer and dryer #2" do
    AddressHarvester.new(s('3602181818.html'),mc).have_feature?(:wd).should be true
  end
  it "should detect washer and dryer #3" do
    AddressHarvester.new(s('3612351233.html'),mc).have_feature?(:wd).should be true
  end
  it "should detect washer and dryer #4" do
    AddressHarvester.new(s('3595693913.html'),mc).have_feature?(:wd).should be true
  end
  it "should not detect washer and dryer when hookups are detected" do
    AddressHarvester.new(s('3579783466.html'),mc).have_feature?(:wd).should_not be true
  end
  it "should detect hook ups #1" do
    AddressHarvester.new(s('3593928817.html'),mc).have_feature?(:hookups).should be true
  end
  it "should detect hook ups #2" do
    AddressHarvester.new(s('3597290743.html'),mc).have_feature?(:hookups).should be true
  end
  it "should not detect washer and dryer while coin laundry onsite #1" do
    AddressHarvester.new(s('4003746196.html'),mc).have_feature?(:coin_laundry).should be true
  end
end

describe "Condominiums fuzzy detector" do
  it "should detect condo" do
    AddressHarvester.new(s('3573633080.html'),mc).have_feature?(:condo).should be true
  end
end

describe "Townhouse fuzzy detector" do
  it "should detect townhouse" do
    AddressHarvester.new(s('3597290743.html'),mc).have_feature?(:townhouse).should be true
  end
end

describe "Scam postings detector" do
  it "should not detect image-only posts as scam" do
    AddressHarvester.new(s('3623902742.html'),mc).is_scam?.should_not be true
  end
  it "should not detect scam here #1" do
    AddressHarvester.new(s('3629310553.html'),mc).is_scam?.should_not be true
  end
  it "should not detect scam here #2" do
    AddressHarvester.new(s('3629352252.html'),mc).is_scam?.should_not be true
  end
  it "should not detect scam here #3" do
    AddressHarvester.new(s('3625753185.html'),mc).is_scam?.should_not be true
  end
  it "should detect scam here #1" do
    AddressHarvester.new(s('3629679038.html'),mc).is_scam?.should be true
  end
  it "should detect scam here #2" do
    AddressHarvester.new(s('3628785789.html'),mc).is_scam?.should be true
  end
  it "should detect scam here #3" do
    AddressHarvester.new(s('3628519763.html'),mc).is_scam?.should be true
  end
  it "should detect scam here #4" do
    AddressHarvester.new(s('3627509426.html'),mc).is_scam?.should be true
  end
end

describe "Price detector" do
  it "should detect $1750 in v.20130301 template" do
    AddressHarvester.new(s('3612351233.html'),mc).get_feature(:rent_amount).should eql 1750
  end
  it "should detect $2150 in v.20130807 template" do
    AddressHarvester.new(s('3986833599.html'),mc).get_feature(:rent_amount).should eql 2150
  end
end

describe "Double-pane windows detector" do
  ["DOUBLE PANE WINDOWS", "Double Pane Windows", "Double Paned Windows", "Double pane windows", "Double-Pane Energy Star Windows", "Dual pane windows", "double pane window", "double pane windows", "double paned windows"].each do |v|
    it "should detect '#{v}'" do
      AddressHarvester.any_instance.stub(:get_body) { v }
      AddressHarvester.new(s('empty_posting.html'),mc).have_feature?(:dpw).should be true
    end
  end
end

describe VersionedConfiguration do
  let(:vc) { VersionedConfiguration.new('') }
  before {
    vc.stub(:get_versions_configuration) {
      {
        20120101 => { :a => 1, :b => 2, :c => 3 },
        20120201 => { :a => 2 },
        20120315 => { :b => 1 },
        20121231 => { :a => 9, :b => 9, :c => 9 },
      }
    }    
  }

  it "should return most recent attribute for a 20120101 version" do
    vc.stub(:get_version) { 20120101 }

    vc.get(:a).should eql 1
    vc.get(:b).should eql 2
    vc.get(:c).should eql 3
  end

  it "should return most recent attribute for a 20120102 version" do
    vc.stub(:get_version) { 20120102 }

    vc.get(:a).should eql 1
    vc.get(:b).should eql 2
    vc.get(:c).should eql 3
  end

  it "should return most recent attribute for a 20120201 version" do
    vc.stub(:get_version) { 20120201 }

    vc.get(:a).should eql 2
    vc.get(:b).should eql 2
    vc.get(:c).should eql 3
  end

  it "should return most recent attribute for a 20120715 version" do
    vc.stub(:get_version) { 20120715 }

    vc.get(:a).should eql 2
    vc.get(:b).should eql 1
    vc.get(:c).should eql 3
  end

  it "should return mc for unknown attribute" do
    vc.stub(:get_versions_configuration) { {} }
    vc.stub(:get_version) { 20120715 }

    vc.get(:z).should be_nil
  end

end

describe "Version detector" do
  Dir.foreach(File.join(File.dirname(__FILE__), 'samples')) do |f|
    if f.match(/^[-0-9_T]+.html$/)
      it "should obtain some version from #{f}" do
        AddressHarvester.new(s(f),mc).version.should_not be_nil
      end
    end
  end
end

describe "Price detector" do
  Dir.foreach(File.join(File.dirname(__FILE__), 'samples')) do |f|
    next if f == '5693112857.html'
    if f.match(/^[-0-9_T]+\.html$/)
      it "should obtain rental amount from #{f}" do
        AddressHarvester.new(s(f),mc).get_feature(:rent_amount).should > 0
      end
    end
  end
end

describe "SQFT parser" do
  sqft_excludes = ['3574423811.html', '3597290743.html', '3598149448.html', '3627509426.html', '3628519763.html', '3628785789.html', '3633731850.html', '3987654283.html', '3991884178.html', '4222894211.html', '4831182004.html']
  Dir.foreach(File.join(File.dirname(__FILE__), 'samples')) do |f|
    next if sqft_excludes.include?(f)
    if f.match(/^[-0-9_T]+\.html$/)
      it "should obtain sqft from #{f}" do
        AddressHarvester.new(s(f),mc).get_feature(:sqft).should > 0
      end
    end
  end
end

describe "Attributes parser" do
  it "should parse attributes from version mid-2013" do
    p = AddressHarvester.new(s('3987654283.html'),mc)

    ['BR', 'Ba', 'condo', 'w/d in unit'].each do |a|
      p.has_attribute?(a).should be true
    end
  end
  it "should parse attributes from version dec-2013" do
    p = AddressHarvester.new(s('4232535045.html'),mc)

    ['BR', 'Ba', 'sqft', 'w/d hookups', 'townhouse', 'attached garage'].each do |a|
      p.has_attribute?(a).should be true
    end
    p.get_attribute('BR').should eql 3
    p.get_attribute('Ba').should eql 2.5
    p.get_attribute('sqft').should eql 1600
  end
  it "should parse attributes from version late-dec-2013" do
    p = AddressHarvester.new(s('4252237879.html'),mc)

    p.version.should eql 20131220
    p.get_attribute('BR').should eql 3
    p.get_attribute('Ba').should eql 2.0
    p.get_attribute('sqft').should eql 1000
    p.get_attribute('house').should be true
    p.get_attribute('laundry on site').should be true
    p.get_attribute('street parking').should be true
  end
  it "should parse bedrooms when bathrooms aren't specified from version 20150103" do
    p = AddressHarvester.new(s('4831182004.html'),mc)

    p.version.should eql 20150103
    p.get_attribute('BR').should eql 2
    p.get_attribute('apartment').should be true
  end
end

describe "Blacklist" do
  it "should not detect address while only agency address is in the posting's body" do
    AddressHarvester.new(s('4236571064.html'),mc).have_full_address?.should be true
  end
end

describe "Intersection detector" do
  it "should detect Niles neighborhood" do
    p = AddressHarvester.new(s('5373956774.html'),mc)

    p.have_full_address?.should_not be true
    p.have_feature?(:neighborhood).should be true
    p.get_feature(:neighborhood).should eql 'Niles'
  end
end

describe "Reverse geocode detector" do
  it "should not try to detect center of Fremont as an address where no other means are available" do
    AddressHarvester.new(s('5379384554.html'),mc).get_full_address.should eql ''
  end
end
