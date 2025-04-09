# spec/components/input_spec.rb
require_relative "../../lib/components/input"

RSpec.describe Components::Input do
  it "serializes and deserializes" do
    input = Components::Input.new
    expect(Components::Input.from_h(input.to_h)).to be_a(Components::Input)
  end
end
