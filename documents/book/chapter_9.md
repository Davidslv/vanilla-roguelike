# Chapter 9: Levels and Transitions

Our roguelike has a maze with solid walls, but it’s still confined to a single level. To give it depth, we’ll add multiple levels connected by stairs, with each level freshly generated every time we start the game or move between levels. In this chapter, we’ll introduce a `StairsComponent` for stairs entities, implement level transitions using a `:level_changed` event, and update the `World` to manage the current level and regenerate mazes on the fly. By the end, you’ll be able to move between unique maze levels using stairs marked by `%`, keeping your dungeon crawl unpredictable and exciting. Let’s build a multi-level labyrinth!

## Adding StairsComponent and Stairs Entities

Stairs will be entities that trigger level transitions, marked by the `%` symbol to distinguish them from walls (`#`) and the player (`@`). The `StairsComponent` will define their direction—up or down—by specifying a relative level change.

Create `lib/components/stairs.rb`:

```ruby
# lib/components/stairs.rb
module Components
  class Stairs
    attr_reader :level_delta

    def initialize(level_delta)
      @level_delta = level_delta  # e.g., 1 for down, -1 for up
    end

    def to_h
      { level_delta: @level_delta }
    end

    def self.from_h(hash)
      new(hash[:level_delta])
    end
  end
end
```

### Explanation

- **level_delta**: An integer representing the change in level (e.g., `1` moves from level 0 to 1, `-1` moves from level 1 to 0). This simplifies transitions—rather than storing absolute level numbers, we adjust the current level relative to where we are.
- **Why Relative?**: Since each level is regenerated, absolute numbers aren’t as meaningful. A delta keeps it flexible and avoids needing to predefine a level structure.

We’ll add stairs in the `MazeSystem` later, after setting up level management.

## Implementing Level Transitions with Events (e.g., level_changed)

To switch levels, we’ll:
1. Detect when the player lands on stairs (via `CollisionSystem`).
2. Queue a `:level_changed` event with the level delta.
3. Have `World` regenerate a new maze based on the updated level.

### Updating CollisionSystem

Modify `lib/systems/collision_system.rb` to detect stairs and trigger transitions:

```ruby
# lib/systems/collision_system.rb
require_relative "../event"

module Systems
  class CollisionSystem
    def initialize(world, event_manager)
      @world = world
      @event_manager = event_manager
    end

    def process(entities)
      @event_manager.process do |event|
        next unless event.type == :entity_moved

        entity_id = event.data[:entity_id]
        entity = @world.entities[entity_id]
        next unless entity && entity.has_component?(Components::Position)

        pos = entity.get_component(Components::Position)
        if wall_at?(pos.x, pos.y)
          puts "Hit a wall at (#{pos.x}, #{pos.y})!"
          pos.x = 1  # Temporary safe spot
          pos.y = 1
        elsif stairs_at?(pos.x, pos.y)
          stairs = stairs_at?(pos.x, pos.y)
          delta = stairs.get_component(Components::Stairs).level_delta
          @event_manager.queue(Event.new(:level_changed, { delta: delta }))
        end
      end
    end

    private

    def wall_at?(x, y)
      @world.entities.values.any? do |entity|
        pos = entity.get_component(Components::Position)
        pos && pos.x == x && pos.y == y && entity.has_component?(Components::Render) &&
          entity.get_component(Components::Render).character == "#"
      end
    end

    def stairs_at?(x, y)
      @world.entities.values.find do |entity|
        pos = entity.get_component(Components::Position)
        pos && pos.x == x && pos.y == y && entity.has_component?(Components::Stairs)
      end
    end
  end
end
```

- **stairs_at?**: Returns the stairs entity at (x, y) or `nil`.
- **Event**: Queues `:level_changed` with a `delta` from the stairs’ `level_delta`.

## Managing Multiple Levels in World

Since we’re not storing levels, `World` will track only the current level number and regenerate entities each time it changes. The player entity will persist across levels, but walls and stairs will be recreated.

Update `lib/world.rb`:

```ruby
# lib/world.rb
require_relative "event"

class World
  attr_reader :entities, :event_manager, :width, :height

  def initialize(width: 10, height: 5)
    @width = width
    @height = height
    @current_level = 0  # Start at level 0
    @entities = {}      # Current level’s entities
    @systems = []
    @next_id = 0
    @running = true
    @event_manager = EventManager.new
    generate_level     # Generate initial maze
  end

  def create_entity
    entity = Entity.new(@next_id)
    @entities[@next_id] = entity
    @next_id += 1
    entity
  end

  def add_system(system)
    @systems << system
    self
  end

  def run
    while @running
      @systems.each { |system| system.process(@entities.values) }
      handle_input
      handle_level_change
      @event_manager.clear
    end
    puts "Goodbye!"
  end

  private

  def generate_level
    # Preserve player, clear other entities
    player = @entities.values.find { |e| e.has_component?(Components::Input) }
    @entities.clear
    @entities[player.id] = player if player
    # Reset MazeSystem and regenerate
    @systems.each { |s| s.instance_variable_set(:@generated, false) if s.is_a?(Systems::MazeSystem) }
    @systems.each { |system| system.process(@entities.values) if system.is_a?(Systems::MazeSystem) }
    # Ensure player is at a safe spot
    player&.get_component(Components::Position)&.tap { |pos| pos.x = 1; pos.y = 1 }
  end

  def handle_input
    input = gets.chomp.downcase
    @event_manager.queue(Event.new(:key_pressed, { key: input }))
    @running = false if input == "q"
  end

  def handle_level_change
    @event_manager.process do |event|
      next unless event.type == :level_changed
      @current_level += event.data[:delta]
      @current_level = 0 if @current_level < 0  # Prevent negative levels
      generate_level
    end
  end
end

class EventManager
  def initialize
    @queue = []
  end

  def queue(event)
    @queue << event
  end

  def process
    @queue.dup.each { |event| yield(event) }
  end

  def clear
    @queue.clear
  end
end
```

### Detailed Breakdown

- **@current_level**: Tracks the current level (starts at 0). It increments or decrements with each transition but can’t go below 0.
- **@entities**: Holds only the current level’s entities. We regenerate them each time.
- **generate_level**:
  - Saves the player entity (if it exists) to persist it across levels.
  - Clears all other entities (walls, stairs).
  - Resets `MazeSystem`’s `@generated` flag and runs it to create a new maze.
  - Places the player at (1, 1), a safe default spot (most mazes have paths near the edge).
- **handle_level_change**: Adjusts `@current_level` based on the `delta` and triggers a new maze generation.

### Updating MazeSystem for Stairs

Modify `lib/systems/maze_system.rb` to add stairs based on the current level:

```ruby
# lib/systems/maze_system.rb
require_relative "../grid"
require_relative "../binary_tree_generator"

module Systems
  class MazeSystem
    def initialize(world, generator_class = BinaryTreeGenerator)
      @world = world
      @generator_class = generator_class
      @generated = false
    end

    def process(_entities)
      return if @generated

      grid = Grid.new(@world.width, @world.height)
      grid.generate_maze(@generator_class)

      # Create wall entities
      grid.cells.each_with_index do |row, y|
        row.each_with_index do |cell, x|
          if cell.is_wall
            wall = @world.create_entity
            wall.add_component(Components::Position.new(x, y))
            wall.add_component(Components::Render.new("#"))
          end
        end
      end

      # Add stairs
      add_stairs(grid)

      @generated = true
    end

    private

    def add_stairs(grid)
      path_cells = []
      grid.cells.each_with_index { |row, y| row.each_with_index { |cell, x| path_cells << [x, y] unless cell.is_wall } }

      # Always add stairs down
      down_x, down_y = path_cells.sample
      stairs_down = @world.create_entity
      stairs_down.add_component(Components::Position.new(down_x, down_y))
      stairs_down.add_component(Components::Render.new("%"))
      stairs_down.add_component(Components::Stairs.new(1))  # Down increases level

      # Add stairs up if not on level 0
      if @world.instance_variable_get(:@current_level) > 0
        up_x, up_y = path_cells.sample
        while up_x == down_x && up_y == down_y  # Ensure distinct positions
          up_x, up_y = path_cells.sample
        end
        stairs_up = @world.create_entity
        stairs_up.add_component(Components::Position.new(up_x, up_y))
        stairs_up.add_component(Components::Render.new("%"))
        stairs_up.add_component(Components::Stairs.new(-1))  # Up decreases level
      end
    end
  end
end
```

- **add_stairs**:
  - Adds a "down" stair (`%`) on every level with `level_delta: 1`.
  - Adds an "up" stair on levels > 0 with `level_delta: -1`, ensuring it’s not at the same spot as "down".
- **Dynamic**: Uses `@world`’s current level to decide which stairs to include.

### Integrating Everything

Update `game.rb`:

```ruby
# game.rb
require_relative "lib/components/position"
require_relative "lib/components/movement"
require_relative "lib/components/render"
require_relative "lib/components/input"
require_relative "lib/components/stairs"
require_relative "lib/entity"
require_relative "lib/systems/movement_system"
require_relative "lib/systems/render_system"
require_relative "lib/systems/input_system"
require_relative "lib/systems/maze_system"
require_relative "lib/systems/collision_system"
require_relative "lib/world"

world = World.new(width: 10, height: 5)

# Create player entity
player = world.create_entity
player.add_component(Components::Position.new(1, 1))
player.add_component(Components::Movement.new)
player.add_component(Components::Render.new("@"))
player.add_component(Components::Input.new)

# Add systems
world.add_system(Systems::MazeSystem.new(world))
world.add_system(Systems::InputSystem.new(world.event_manager))
world.add_system(Systems::MovementSystem.new(world))
world.add_system(Systems::CollisionSystem.new(world, world.event_manager))
world.add_system(Systems::RenderSystem.new(10, 5))

# Start the game
world.run
```

Run `ruby game.rb`, and you’ll start on level 0 with a fresh maze, walls (`#`), and a `%` stair down. Move `@` onto `%` to descend to level 1 (a new maze with both up and down stairs). Climb up or down—each level is unique!

### Updated Project Structure

```
roguelike/
├── Gemfile
├── game.rb
├── lib/
│   ├── components/
│   │   ├── position.rb
│   │   ├── movement.rb
│   │   ├── render.rb
│   │   ├── input.rb
│   │   └── stairs.rb  (new)
│   ├── systems/
│   │   ├── movement_system.rb
│   │   ├── render_system.rb
│   │   ├── input_system.rb
│   │   ├── maze_system.rb
│   │   └── collision_system.rb
│   ├── binary_tree_generator.rb
│   ├── entity.rb
│   ├── event.rb
│   ├── grid.rb
│   ├── maze_generator.rb
│   └── world.rb
├── spec/
│   ├── components/
│   │   ├── position_spec.rb
│   │   ├── movement_spec.rb
│   │   ├── render_spec.rb
│   │   ├── input_spec.rb
│   │   └── stairs_spec.rb  (new, below)
│   ├── systems/
│   │   ├── movement_system_spec.rb
│   │   ├── render_system_spec.rb
│   │   ├── input_system_spec.rb
│   │   ├── maze_system_spec.rb
│   │   └── collision_system_spec.rb
│   ├── binary_tree_generator_spec.rb
│   ├── entity_spec.rb
│   ├── event_spec.rb
│   ├── grid_spec.rb
│   ├── maze_generator_spec.rb
│   ├── world_spec.rb
│   └── game_spec.rb
└── README.md
```

### New Test

- `spec/components/stairs_spec.rb`:
```ruby
# spec/components/stairs_spec.rb
require_relative "../../lib/components/stairs"

RSpec.describe Components::Stairs do
  it "stores level delta" do
    stairs = Components::Stairs.new(1)
    expect(stairs.level_delta).to eq(1)
    expect(Components::Stairs.from_h(stairs.to_h).level_delta).to eq(1)
  end
end
```

Run `bundle exec rspec` to verify.

## Outcome

By the end of this chapter, you’ve:
- Added `StairsComponent` and stairs entities marked by `%`.
- Implemented level transitions with `:level_changed` events.
- Managed the current level in `World`, regenerating a new maze each time.

You can now move between freshly generated maze levels! Start on level 0, find `%` to go down, and climb back up on higher levels—each maze is brand new. Walls block your path, and stairs offer adventure. Next, we could add items or enemies to populate these levels. Run `ruby game.rb`, explore your ever-changing dungeon, and let’s keep the journey going!

---

### In-Depth Details for New Engineers

- **Why Regenerate?**: Not storing levels saves memory and keeps the game dynamic—every transition feels like a new challenge. The trade-off is losing continuity (e.g., no returning to a previous layout), but that fits a roguelike’s replayable nature.
- **Level Delta**: Using a relative `level_delta` simplifies logic—`World` just adds it to `@current_level`. We cap at 0 to avoid negative levels, but you could expand this (e.g., a max level).
- **Player Persistence**: Keeping the player entity across levels ensures continuity of identity (e.g., future health or inventory). Resetting to (1, 1) is a placeholder—later, we could spawn near the "up" stair.
- **MazeSystem Reset**: Using `instance_variable_set` to reset `@generated` is a quick fix. A more elegant approach might add a `reset` method to `MazeSystem`, but this works for our turn-based flow.

This keeps the ECS clean and the game unpredictable.