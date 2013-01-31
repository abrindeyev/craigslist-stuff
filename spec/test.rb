RSpec::Matchers.define :contain do |element|
  match do |container|
    container.include? element
  end
end

describe Array do
  it "contains its elements" do
    [1, 2, 3, "four"].should contain "four"
  end
end
