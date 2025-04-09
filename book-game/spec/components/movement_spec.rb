# spec/components/movement_spec.rb
require_relative "../../lib/components/movement"

RSpec.describe Components::Movement do
  it "serializes and deserializes correctly" do
    mov = Components::Movement.new(1, -1)
    expect(Components::Movement.from_h(mov.to_h).dx).to eq(1)
  end
end
