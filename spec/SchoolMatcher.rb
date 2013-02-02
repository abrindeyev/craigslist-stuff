require File.join(File.dirname(__FILE__), '..', 'lib', 'school')

describe "#new" do
  before :each do
    @matcher = SchoolMatcher.new(37.558526, -121.975352)
  end

  it "takes coordinates and returns a SchoolMatcher object" do
    @matcher.should be_an_instance_of SchoolMatcher
  end

  it "initializes and creates caches successfully" do
    @matcher.get_schools.should be_an_instance_of Array
  end

  it "contains 34 school polygons in Fremont district" do
    @matcher.get_schools.size.should eq(33)
  end

  it "matched all schools with ratings" do
    @matcher.get_schools.map{|s| s if s.include?(:rating)}.compact.size.should eq(33)
  end

  it "matched Tule Pond with Parkmont Elementary school" do
    @matcher.get_school_name.should eq('Parkmont Elementary')
  end

  it "provides correct street address for Parkmont Elementary school" do
    @matcher.get_school_address.should eq('2601 Parkside Dr., Fremont, CA 94536')
  end

  it "have Parkmont Elementary school's rating equal 10" do
    @matcher.get_rating.should eq(10)
  end
end
