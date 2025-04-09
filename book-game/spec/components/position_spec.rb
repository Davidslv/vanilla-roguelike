# spec/components/position_spec.rb
require_relative "../../lib/components/position"

RSpec.describe Components::Position do
  it "serializes and deserializes correctly" do
    pos = Components::Position.new(5, 3)
    expect(Components::Position.from_h(pos.to_h).x).to eq(5)
  end
end
