# spec/systems/maze_system_spec.rb
require_relative "../../lib/systems/maze_system"
require_relative "../../lib/world"
require_relative "../../lib/entity"
require_relative "../../lib/components/position"
require_relative "../../lib/components/render"
require_relative "../../lib/binary_tree_generator"

RSpec.describe Systems::MazeSystem do
  it "populates world with wall entities only once" do
    world = World.new(width: 3, height: 3)
    system = Systems::MazeSystem.new(world, BinaryTreeGenerator)
    system.process([])
    wall_count = world.entities.values.count { |e| e.has_component?(Components::Render) && e.get_component(Components::Render).character == "#" }
    expect(wall_count).to be > 0
    system.process([]) # Run again
    expect(world.entities.size).to eq(wall_count) # No new entities added
  end
end
