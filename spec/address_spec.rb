require File.join(File.dirname(__FILE__), '..', 'lib', 'address')
require 'fakeweb'

def s(sample_filename)
  File.join(File.dirname(__FILE__), 'samples', sample_filename)
end

describe "#new" do
  context "with nil parameter" do
    it "should return empty object with nil" do
      AddressHarvester.new(nil).should be_an_instance_of AddressHarvester
    end
  end
  context "with local filename" do
    it "should return object reference" do
      FakeWeb.register_uri(:get, 'http://maps.googleapis.com/maps/api/geocode/json?latlng=37.399619,-122.086022&sensor=false', :response => s('3574423811_reverse_geocode.json'))
      post = AddressHarvester.new(s('3574423811.html'))
      post.should_not be_nil
    end
    it "shouldn't have # of bedrooms" do
      AddressHarvester.new(s('removed.html')).have_feature?(:bedrooms).should eql false
    end
    it "should return correct # of bedrooms" do
      AddressHarvester.new(s('3574423811.html')).get_feature(:bedrooms).should eql 2
    end
    it "shoudn't have valid address for simple postings without map and inline address" do
      AddressHarvester.new(s('3598149448.html')).have_full_address?.should eql false
    end
    it "should detect deleted posting" do
      AddressHarvester.new(s('deleted.html')).has_been_removed?.should eql true
    end
    it "should detect removed posting" do
      AddressHarvester.new(s('removed.html')).has_been_removed?.should eql true
    end
    it "should get xstreet0 tag value" do 
      FakeWeb.register_uri(:get, 'http://maps.googleapis.com/maps/api/geocode/json?latlng=37.399619,-122.086022&sensor=false', :response => s('3574423811_revgeocode.json'))
      AddressHarvester.new(s('3574423811.html')).get_tag('xstreet0').should eql '120 Granada'
    end
    it "should return city from 'city' tag" do
      AddressHarvester.new(s('3574423811.html')).get_tag('city').should eql 'Mountain View'
    end
    it "should return state from 'region' tag" do
      AddressHarvester.new(s('3574423811.html')).get_tag('region').should == 'Ca'
    end
    it "should not return tag if it skipped in original post" do
      AddressHarvester.new(s('3574419831.html')).get_tag('region').should_not == 'CA'
    end
    it "should detect city from posting with image" do
      AddressHarvester.new(s('3587401701.html')).get_city.should eql 'Fremont'
    end
  end
end

describe "Posting info parser" do
  it "should return posted date when post wasn't updated yet" do
    AddressHarvester.new(s('3574419831.html')).get_posting_update_time.should eql '2013-01-26,  9:04PM PST'
  end
  it "should return updated date when post was updated" do
    FakeWeb.register_uri(:get, 'http://maps.googleapis.com/maps/api/geocode/json?latlng=37.602334,-122.056373&sensor=false', :response => s('3602181818_revgeocode.json'))
    AddressHarvester.new(s('3602181818.html')).get_posting_update_time.should eql '2013-02-07, 11:29PM PST'
  end
  it "should return empty string when post was removed" do
    AddressHarvester.new(s('removed.html')).get_posting_update_time.should eql ''
  end
end

describe "Apartments detector" do
  it "should detect 'Pebble Creek Communities'" do
    AddressHarvester.new(s('3598509706.html')).get_feature(:name).should eql 'Pebble Creek'
  end
  it "should detect 'Woods'" do
    AddressHarvester.new(s('3599422360.html')).get_feature(:name).should eql 'Woods'
  end
  it "should detect 'Creekside Village'" do
    AddressHarvester.new(s('3605593473.html')).get_feature(:name).should eql 'Creekside Village'
  end
  it "should detect 'Skylark'" do
    FakeWeb.register_uri(:get, 'http://ads.rentsentinel.com/activity/CLContact.aspx?C=2332&RT=T&Adid=20634371&psid=0&subID=f&ID=13150', :response => s('3590057703_rentsentinel.html'))
    AddressHarvester.new(s('3590057703.html')).get_feature(:name).should eql 'Skylark'
  end
  it "should detect 'Alborada'" do
    FakeWeb.register_uri(:get, 'http://ads.rentsentinel.com/activity/CLContact.aspx?C=2044&RT=T&Adid=20692909&psid=0&subID=f&ID=11978', :response => s('3591325547_rentsentinel.html'))
    AddressHarvester.new(s('3591325547.html')).get_feature(:name).should eql 'Alborada'
  end
  it "should detect 'Rancho Luna' #1" do
    AddressHarvester.new(s('3987415202.html')).get_feature(:name).should eql 'Rancho Luna'
  end
  it "should detect 'Rancho Luna' #2" do
    AddressHarvester.new(s('3987670153.html')).get_feature(:name).should eql 'Rancho Luna'
  end
  it "should detect 'Rancho Luna' #3" do
    AddressHarvester.new(s('3992986304.html')).get_feature(:name).should eql 'Rancho Luna'
  end
  it "should detect 'Rancho Luna' #4" do
    AddressHarvester.new(s('3991905116.html')).get_feature(:name).should eql 'Rancho Luna'
  end
  it "should detect 'Fremont Park'" do
    AddressHarvester.new(s('3982386449.html')).get_feature(:name).should eql 'Fremont Park'
  end
  it "should detect 'Ardenwood Forest'" do
    AddressHarvester.new(s('3978588955.html')).get_feature(:name).should eql 'Ardenwood Forest'
  end
  it "should detect 'Carriage House'" do
    AddressHarvester.new(s('3993236430.html')).get_feature(:name).should eql 'Carriage House'
  end
  it "should detect 'Casa Arroyo'" do
    AddressHarvester.new(s('3993519528.html')).get_feature(:name).should eql 'Casa Arroyo'
  end
  it "should detect 'Suburbian Garden'" do
    AddressHarvester.new(s('3991884178.html')).get_feature(:name).should eql 'Suburbian Garden'
  end
  it "should detect 'Garden Village Apartments'" do
    AddressHarvester.new(s('4028997623.html')).get_feature(:name).should eql 'Garden Village'
  end
  it "should detect 'Royal Pines Apartments'" do
    AddressHarvester.new(s('4232230901.html')).get_feature(:name).should eql 'Royal Pines'
  end
  it "should detect 'Countrywood Apartments'" do
    AddressHarvester.new(s('4222894211.html')).get_feature(:name).should eql 'Countrywood'
  end
  it "should detect 'Mission Peaks II Apartments'" do
    FakeWeb.register_uri(:get, 'http://AptJet.com/ContactUs/?id=337c5382l277094', :response => s('4220012226_landing.html'))
    FakeWeb.register_uri(:get, 'http://aptjet.com/activity/CLContact.aspx?C=5382&RT=T&Adid=32242398&psid=0&subID=f&ID=328939', :response => s('4220012226_aptjet.html'))
    AddressHarvester.new(s('4220012226.html')).get_feature(:name).should eql 'Mission Peaks II'
  end
end

describe "Score engine" do
  it "should return non-nil score for postings without any address" do
    AddressHarvester.new(s('3598149448.html')).get_score.should_not be_nil
  end
  it "should return digital score for postings without any address" do
    AddressHarvester.new(s('3598149448.html')).get_score.should be_a(Fixnum)
  end
end

describe "Raw address detector" do
  it "should return '40711 Robin Street, Fremont, CA'" do
    AddressHarvester.new(s('3599138803.html')).get_full_address.should eql '40711 Robin Street, Fremont, CA'
  end
  it "should return '23 Raintree Court, Hayward, CA'" do
    AddressHarvester.new(s('3601613904.html')).get_full_address.should eql '23 Raintree Court, Hayward, CA'
  end
  it "should return '38700 Tyson Ln, Fremont, California'" do
    FakeWeb.register_uri(:get, 'http://maps.googleapis.com/maps/api/geocode/json?latlng=37.562137,-121.974786&sensor=false', :response => s('3585854056_revgeocode.json'))
    AddressHarvester.new(s('3585854056.html')).get_full_address.should eql '38700 Tyson Ln, Fremont, California'
  end
  it "should return '1001 Beethoven Common, Fremont, CA'" do
    FakeWeb.register_uri(:get, 'http://ads.rentsentinel.com/activity/CLContact.aspx?C=2044&RT=T&Adid=20692909&psid=0&subID=f&ID=11978', :response => s('3591325547_rentsentinel.html'))
    AddressHarvester.new(s('3591325547.html')).get_full_address.should eql '1001 Beethoven Common, Fremont, CA'
  end
  it "should return '40571 Chapel Way, Fremont, California'" do
    FakeWeb.register_uri(:get, 'http://maps.googleapis.com/maps/api/geocode/json?latlng=37.537336,-121.959770&sensor=false', :response => s('3582870190_revgeocode.json'))
    AddressHarvester.new(s('3582870190.html')).get_full_address.should eql '40571 Chapel Way, Fremont, California'
  end
  it "shouldn't detect full address from fuzzy reverse geocode requests" do
    FakeWeb.register_uri(:get, 'http://maps.googleapis.com/maps/api/geocode/json?latlng=37.609532,-122.024371&sensor=false', :response => s('3584993361_revgeocode.json'))
    AddressHarvester.new(s('3584993361.html')).have_full_address?.should be_false
  end
  it "should return '39800 Fremont Blvd., Fremont, CA'" do
    AddressHarvester.new(s('3587519103.html')).get_full_address.should eql '39800 Fremont Blvd., Fremont, CA'
  end
  it "should return '5647 Robertson Ave, Newark, CA'" do
    AddressHarvester.new(s('3584363870.html')).get_full_address.should eql '5647 Robertson Ave, Newark, CA'
  end
  it "should return '40640 High St., Fremont, CA'" do
    AddressHarvester.new(s('3587462071.html')).get_full_address.should eql '40640 High St., Fremont, CA'
  end
  it "should return '43314 Jerome Ave, Fremont, CA'" do
    AddressHarvester.new(s('3587303805.html')).get_full_address.should eql '43314 Jerome Ave, Fremont, CA'
  end
  it "should return '4193 Rainbow Ter, Fremont, CA'" do
    AddressHarvester.new(s('3587286246.html')).get_full_address.should eql '4193 Rainbow Ter, Fremont, CA'
  end
  it "should return '31770 Alvarado Blvd, Union City, CA'" do
    AddressHarvester.new(s('3591502030.html')).get_full_address.should eql '31770 Alvarado Blvd, Union City, CA'
  end
  it "should return '4022 Papillon Terrace, Fremont, CA'" do
    AddressHarvester.new(s('3573633080.html')).get_full_address.should eql '4022 Papillon Terrace, Fremont, CA'
  end
  it "should return '4181 Asimuth Cir., Union City, CA'" do
    AddressHarvester.new(s('3619322293.html')).get_full_address.should eql '4181 Asimuth Cir., Union City, CA'
  end
  it "should return '38593 Royal Ann Cmn, Fremont, CA'" do
    AddressHarvester.new(s('3626121593.html')).get_full_address.should eql '38593 Royal Ann Cmn, Fremont, CA'
  end
  it "should return '37120 Spruce St, Newark, CA'" do
    AddressHarvester.new(s('3633731850.html')).get_full_address.should eql '37120 Spruce St, Newark, CA'
  end
  it "should return '37155 Aspenwood Commons, Fremont CA'" do
    AddressHarvester.new(s('4232384330.html')).get_full_address.should eql '37155 Aspenwood Commons, Fremont, CA'
  end
end

describe "Washer/dryer/hookups fuzzy detector" do
  it "should detect washer and dryer #1" do
    AddressHarvester.new(s('3564576923.html')).have_feature?(:wd).should be_true
  end
  it "should detect washer and dryer #2" do
    FakeWeb.register_uri(:get, 'http://maps.googleapis.com/maps/api/geocode/json?latlng=37.602334,-122.056373&sensor=false', :response => s('3602181818_revgeocode.json'))
    AddressHarvester.new(s('3602181818.html')).have_feature?(:wd).should be_true
  end
  it "should detect washer and dryer #3" do
    AddressHarvester.new(s('3612351233.html')).have_feature?(:wd).should be_true
  end
  it "should detect washer and dryer #4" do
    FakeWeb.register_uri(:get, 'http://maps.googleapis.com/maps/api/geocode/json?latlng=37.603313,-122.071328&sensor=false', :response => s('3595693913_revgeocode.json'))
    AddressHarvester.new(s('3595693913.html')).have_feature?(:wd).should be_true
  end
  it "should detect washer and dryer #5" do
    FakeWeb.register_uri(:get, 'http://maps.googleapis.com/maps/api/geocode/json?latlng=37.517600,-121.928700&sensor=false', :response => s('3987654283_revgeocode.json'))
    AddressHarvester.new(s('3987654283.html')).have_feature?(:wd).should be_true
  end
  it "should not detect washer and dryer when hookups are detected" do
    AddressHarvester.new(s('3579783466.html')).have_feature?(:wd).should_not be_true
  end
  it "should detect hook ups #1" do
    AddressHarvester.new(s('3593928817.html')).have_feature?(:hookups).should be_true
  end
  it "should detect hook ups #2" do
    AddressHarvester.new(s('3597290743.html')).have_feature?(:hookups).should be_true
  end
  it "should not detect washer and dryer while coin laundry onsite #1" do
    AddressHarvester.new(s('4003746196.html')).have_feature?(:coin_laundry).should be_true
  end
end

describe "Condominiums fuzzy detector" do
  it "should detect condo" do
    AddressHarvester.new(s('3573633080.html')).have_feature?(:condo).should be_true
  end
end

describe "Townhouse fuzzy detector" do
  it "should detect townhouse" do
    AddressHarvester.new(s('3597290743.html')).have_feature?(:townhouse).should be_true
  end
end

describe "Scam postings detector" do
  it "should not detect image-only posts as scam" do
    AddressHarvester.new(s('3623902742.html')).is_scam?.should_not be_true
  end
  it "should not detect scam here #1" do
    AddressHarvester.new(s('3629310553.html')).is_scam?.should_not be_true
  end
  it "should not detect scam here #2" do
    FakeWeb.register_uri(:get, 'http://maps.googleapis.com/maps/api/geocode/json?latlng=37.565935,-122.024472&sensor=false', :response => s('3629352252_revgeocode.json'))
    AddressHarvester.new(s('3629352252.html')).is_scam?.should_not be_true
  end
  it "should not detect scam here #3" do
    AddressHarvester.new(s('3625753185.html')).is_scam?.should_not be_true
  end
  it "should detect scam here #1" do
    AddressHarvester.new(s('3629679038.html')).is_scam?.should be_true
  end
  it "should detect scam here #2" do
    AddressHarvester.new(s('3628785789.html')).is_scam?.should be_true
  end
  it "should detect scam here #3" do
    AddressHarvester.new(s('3628519763.html')).is_scam?.should be_true
  end
  it "should detect scam here #4" do
    AddressHarvester.new(s('3627509426.html')).is_scam?.should be_true
  end
end

describe "Price detector" do
  it "should detect $1750 in v.20130301 template" do
    AddressHarvester.new(s('3612351233.html')).get_feature(:rent_price).should eql 1750
  end
  it "should detect $2150 in v.20130807 template" do
    FakeWeb.register_uri(:get, 'http://maps.googleapis.com/maps/api/geocode/json?latlng=37.573500,-122.046900&sensor=false', :response => s('3986833599_revgeocode.json'))
    AddressHarvester.new(s('3986833599.html')).get_feature(:rent_price).should eql 2150
  end
end
