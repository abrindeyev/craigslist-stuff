require File.join(File.dirname(__FILE__), '..', 'lib', 'address')
require 'fakeweb'

samples = File.join(File.dirname(__FILE__), 'samples')

describe "#new" do
  context "with nil parameter" do
    it "should return empty object with nil" do
      AddressHarvester.new(nil).should be_an_instance_of AddressHarvester
    end
  end
  context "with local filename" do
    it "should return object reference" do
      FakeWeb.register_uri(:get, 'http://maps.googleapis.com/maps/api/geocode/json?latlng=37.399619,-122.086022&sensor=false', :response => File.join(File.dirname(__FILE__), 'samples', '3574423811_reverse_geocode.json'))
      post = AddressHarvester.new(File.join(samples, '3574423811.html'))
      post.should_not be_nil
    end
    it "shouldn't have # of bedrooms" do
      AddressHarvester.new(File.join(samples, 'removed.html')).have_feature?(:bedrooms).should eql false
    end
    it "should return correct # of bedrooms" do
      AddressHarvester.new(File.join(samples, '3574423811.html')).get_feature(:bedrooms).should eql 2
    end
    it "shoudn't have valid address for simple postings without map and inline address" do
      AddressHarvester.new(File.join(samples, '3598149448.html')).have_full_address?.should eql false
    end
    it "should detect removed posting" do
      AddressHarvester.new(File.join(samples, 'removed.html')).has_been_removed?.should eql true
    end
    it "should get xstreet0 tag value" do 
      FakeWeb.register_uri(:get, 'http://maps.googleapis.com/maps/api/geocode/json?latlng=37.399619,-122.086022&sensor=false', :response => File.join(File.dirname(__FILE__), 'samples', '3574423811_revgeocode.json'))
      AddressHarvester.new(File.join(samples, '3574423811.html')).get_tag('xstreet0').should eql '120 Granada'
    end
    it "should return city from 'city' tag" do
      AddressHarvester.new(File.join(samples, '3574423811.html')).get_tag('city').should eql 'Mountain View'
    end
    it "should return state from 'region' tag" do
      AddressHarvester.new(File.join(samples, '3574423811.html')).get_tag('region').should == 'Ca'
    end
    it "should not return tag if it skipped in original post" do
      AddressHarvester.new(File.join(samples, '3574419831.html')).get_tag('region').should_not == 'CA'
    end
    it "should detect city from posting with image" do
      AddressHarvester.new(File.join(samples, '3587401701.html')).get_city.should eql 'Fremont'
    end
  end
end

describe "Apartments detector" do
  it "should detect 'Pebble Creek Communities'" do
    AddressHarvester.new(File.join(samples, '3598509706.html')).get_feature(:name).should eql 'Pebble Creek'
  end
  it "should detect 'Woods'" do
    AddressHarvester.new(File.join(samples, '3599422360.html')).get_feature(:name).should eql 'Woods'
  end
  it "should detect 'Creekside Village'" do
    AddressHarvester.new(File.join(samples, '3605593473.html')).get_feature(:name).should eql 'Creekside Village'
  end
  it "should detect 'Skylark'" do
    FakeWeb.register_uri(:get, 'http://ads.rentsentinel.com/activity/CLContact.aspx?C=2332&RT=T&Adid=20634371&psid=0&subID=f&ID=13150', :response => File.join(File.dirname(__FILE__), 'samples', '3590057703_rentsentinel.html'))
    AddressHarvester.new(File.join(samples, '3590057703.html')).get_feature(:name).should eql 'Skylark'
  end
  it "should detect 'Alborada'" do
    FakeWeb.register_uri(:get, 'http://ads.rentsentinel.com/activity/CLContact.aspx?C=2044&RT=T&Adid=20692909&psid=0&subID=f&ID=11978', :response => File.join(File.dirname(__FILE__), 'samples', '3591325547_rentsentinel.html'))
    AddressHarvester.new(File.join(samples, '3591325547.html')).get_feature(:name).should eql 'Alborada'
  end
end

describe "Score engine" do
  it "should return non-nil score for postings without any address" do
    AddressHarvester.new(File.join(samples, '3598149448.html')).get_score.should_not be_nil
  end
  it "should return digital score for postings without any address" do
    AddressHarvester.new(File.join(samples, '3598149448.html')).get_score.should be_a(Fixnum)
  end
end

describe "Raw address detector" do
  it "should return '40711 Robin Street, Fremont, CA'" do
    AddressHarvester.new(File.join(samples, '3599138803.html')).get_full_address.should eql '40711 Robin Street, Fremont, CA'
  end
  it "should return '23 Raintree Court, Hayward, CA'" do
    AddressHarvester.new(File.join(samples, '3601613904.html')).get_full_address.should eql '23 Raintree Court, Hayward, CA'
  end
  it "should return '38700 Tyson Ln, Fremont, California'" do
    FakeWeb.register_uri(:get, 'http://maps.googleapis.com/maps/api/geocode/json?latlng=37.562137,-121.974786&sensor=false', :response => File.join(File.dirname(__FILE__), 'samples', '3585854056_revgeocode.json'))
    AddressHarvester.new(File.join(samples, '3585854056.html')).get_full_address.should eql '38700 Tyson Ln, Fremont, California'
  end
  it "should return '1001 Beethoven Common, Fremont, CA'" do
    FakeWeb.register_uri(:get, 'http://ads.rentsentinel.com/activity/CLContact.aspx?C=2044&RT=T&Adid=20692909&psid=0&subID=f&ID=11978', :response => File.join(File.dirname(__FILE__), 'samples', '3591325547_rentsentinel.html'))
    AddressHarvester.new(File.join(samples, '3591325547.html')).get_full_address.should eql '1001 Beethoven Common, Fremont, CA'
  end
  it "should return '40571 Chapel Way, Fremont, California'" do
    FakeWeb.register_uri(:get, 'http://maps.googleapis.com/maps/api/geocode/json?latlng=37.537336,-121.959770&sensor=false', :response => File.join(File.dirname(__FILE__), 'samples', '3582870190_revgeocode.json'))
    AddressHarvester.new(File.join(samples, '3582870190.html')).get_full_address.should eql '40571 Chapel Way, Fremont, California'
  end
  it "shouldn't detect full address from fuzzy reverse geocode requests" do
    FakeWeb.register_uri(:get, 'http://maps.googleapis.com/maps/api/geocode/json?latlng=37.609532,-122.024371&sensor=false', :response => File.join(File.dirname(__FILE__), 'samples', '3584993361_revgeocode.json'))
    AddressHarvester.new(File.join(samples, '3584993361.html')).have_full_address?.should be_false
  end
  it "should return '4022 Papillon Terrace, Fremont, CA'" do
    AddressHarvester.new(File.join(samples, '3573633080.html')).get_full_address.should eql '4022 Papillon Terrace, Fremont, CA'
  end
  it "should return '39800 Fremont Blvd., Fremont, CA'" do
    AddressHarvester.new(File.join(samples, '3587519103.html')).get_full_address.should eql '39800 Fremont Blvd., Fremont, CA'
  end
  it "should return '5647 Robertson Ave, Newark, CA'" do
    AddressHarvester.new(File.join(samples, '3584363870.html')).get_full_address.should eql '5647 Robertson Ave, Newark, CA'
  end
  it "should return '40640 High St., Fremont, CA'" do
    AddressHarvester.new(File.join(samples, '3587462071.html')).get_full_address.should eql '40640 High St., Fremont, CA'
  end
  it "should return '43314 Jerome Ave, Fremont, CA'" do
    AddressHarvester.new(File.join(samples, '3587303805.html')).get_full_address.should eql '43314 Jerome Ave, Fremont, CA'
  end
  it "should return '4193 Rainbow Ter, Fremont, CA'" do
    AddressHarvester.new(File.join(samples, '3587286246.html')).get_full_address.should eql '4193 Rainbow Ter, Fremont, CA'
  end
  it "should return '31770 Alvarado Blvd, Union City, CA'" do
    AddressHarvester.new(File.join(samples, '3591502030.html')).get_full_address.should eql '31770 Alvarado Blvd, Union City, CA'
  end
  it "should return '4022 Papillon Terrace, Fremont, CA'" do
    AddressHarvester.new(File.join(samples, '3573633080.html')).get_full_address.should eql '4022 Papillon Terrace, Fremont, CA'
  end
end
