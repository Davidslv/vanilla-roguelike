# spec/systems/movement_system_spec.rb
require_relative "../../lib/systems/movement_system"
require_relative "../../lib/entity"
require_relative "../../lib/components/position"
require_relative "../../lib/components/movement"

RSpec.describe Systems::MovementSystem do
  it "moves entities within grid bounds" do
    entity = Entity.new(1)
                   .add_component(Components::Position.new(0, 0))
                   .add_component(Components::Movement.new(1, 0))
    system = Systems::MovementSystem.new
    system.process([entity], 5, 5) # 5x5 grid
    expect(entity.get_component(Components::Position).x).to eq(1)
    expect(entity.get_component(Components::Movement).dx).to eq(0) # Reset after move
  end
end
