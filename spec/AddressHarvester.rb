require File.join(File.dirname(__FILE__), '..', 'lib', 'address')

samples = File.join(File.dirname(__FILE__), 'samples')

describe "Address harvester object" do
  subject { AddressHarvester.new(File.join(samples, '3574423811.html')) }
  it { should_not eq(nil) }
end

describe "Get xstreet0 tag value" do
  subject { AddressHarvester.new(File.join(samples, '3574423811.html')).get_tag('xstreet0') }
  it { should == '120 Granada' }
end

describe "Get city tag value" do
  subject { AddressHarvester.new(File.join(samples, '3574423811.html')).get_tag('city') }
  it { should == 'Mountain View' }
end

describe "Get region tag value" do
  subject { AddressHarvester.new(File.join(samples, '3574423811.html')).get_tag('region') }
  it { should == 'Ca' }
end

describe "Missing region tag" do
  subject { AddressHarvester.new(File.join(samples, '3574419831.html')).get_tag('region') }
  it { should_not == 'CA' }
end

describe "Posting with full address from internal pattern database" do
  subject { AddressHarvester.new(File.join(samples, '3573633080.html')).have_full_address? }
  it { should == true }
end

describe "Posting with full address from body #1" do
  subject { AddressHarvester.new(File.join(samples, '3587519103.html')).have_full_address? }
  it { should == true }
end

describe "Posting with full address from body #2" do
  subject { AddressHarvester.new(File.join(samples, '3584363870.html')).have_full_address? }
  it { should == true }
end

describe "Posting with full address from body #2 have correct address parsed" do
  subject { AddressHarvester.new(File.join(samples, '3584363870.html')).get_full_address }
  it { should == '5647 Robertson Ave, Newark, CA' }
end

describe "Posting with full address from body #3 have correct address parsed" do
  subject { AddressHarvester.new(File.join(samples, '3587462071.html')).get_full_address }
  it { should == '40640 High St., Fremont, CA' }
end

describe "Posting with full address from body #4 with '# A' unit number have correct address parsed" do
  subject { AddressHarvester.new(File.join(samples, '3587303805.html')).get_full_address }
  it { should == '43314 Jerome Ave, Fremont, CA' }
end

describe "Posting with full address from body #5 have correct address parsed" do
  subject { AddressHarvester.new(File.join(samples, '3587286246.html')).get_full_address }
  it { should == '4193 Rainbow Ter, Fremont, CA' }
end

describe "Get full address from matched database entry" do
  subject { AddressHarvester.new(File.join(samples, '3573633080.html')).get_full_address }
  it { should == '4022 Papillon Terrace, Fremont, CA' }
end

describe "Posting with both GPS and tag street address" do
  subject { AddressHarvester.new(File.join(samples, '3585854056.html')).get_full_address }
  it { should == '38700 Tyson Ln, Fremont, California' }
end

describe "Posting with GPS coordinates only" do
  subject { AddressHarvester.new(File.join(samples, '3582870190.html')).get_full_address }
  it { should == '40571 Chapel Way, Fremont, California' }
end

describe "Getting Fremont from image posting" do
  subject { AddressHarvester.new(File.join(samples, '3587401701.html')).get_city }
  it { should == 'Fremiont' }
end

describe "Hayward posting doesn't have valid address" do
  subject { AddressHarvester.new(File.join(samples, '3584993361.html')).have_full_address? }
  it { should == false }
end
