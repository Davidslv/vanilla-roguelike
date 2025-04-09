# game.rb
require_relative "lib/components/position"
require_relative "lib/components/movement"
require_relative "lib/components/render"
require_relative "lib/components/input"
require_relative "lib/entity"
require_relative "lib/systems/movement_system"
require_relative "lib/systems/render_system"
require_relative "lib/systems/input_system"
require_relative "lib/systems/maze_system"
require_relative "lib/world"
require_relative "lib/logger"

# Create world with a reasonable size
world = World.new(width: 20, height: 10)

# Add systems (order matters: maze -> input -> movement -> render)
world.add_system(Systems::MazeSystem.new(world))
world.add_system(Systems::InputSystem.new(world.event_manager))
world.add_system(Systems::MovementSystem.new(world))
world.add_system(Systems::RenderSystem.new(20, 10))

# Start the game
world.run
