# spec/systems/input_system_spec.rb
require_relative "../../lib/systems/input_system"
require_relative "../../lib/entity"
require_relative "../../lib/components/input"
require_relative "../../lib/components/movement"
require_relative "../../lib/world"

RSpec.describe Systems::InputSystem do
  it "updates movement component on key press" do
    world = World.new
    entity = Entity.new(1)
                   .add_component(Components::Input.new)
                   .add_component(Components::Movement.new)
    system = Systems::InputSystem.new(world.event_manager)
    world.event_manager.queue(Event.new(:key_pressed, { key: "d" }))
    system.process([entity])
    expect(entity.get_component(Components::Movement).dx).to eq(1)
  end
end
