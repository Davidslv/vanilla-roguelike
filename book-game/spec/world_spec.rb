# spec/world_spec.rb
require_relative "../lib/world"
require_relative "../lib/components/position"

RSpec.describe World do
  it "creates entities with unique IDs" do
    world = World.new
    e1 = world.create_entity
    e2 = world.create_entity
    expect(e1.id).to eq(0)
    expect(e2.id).to eq(1)
  end
end
