# spec/entity_spec.rb
require_relative "../lib/entity"
require_relative "../lib/components/position"

RSpec.describe Entity do
  it "adds and retrieves components" do
    entity = Entity.new(1)
    pos = Components::Position.new(2, 4)
    entity.add_component(pos)
    expect(entity.get_component(Components::Position)).to eq(pos)
  end
end
