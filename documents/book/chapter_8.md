# Chapter 8: Collision and Boundaries

Our roguelike now boasts a procedurally generated maze, but the player can still walk through walls like a ghost. In this chapter, we'll add collision detection to keep the player on the paths. We'll enhance the `MovementSystem` to check grid cells before moving, create a new `CollisionSystem` to handle entity-to-entity interactions, and enforce both wall collisions and grid boundaries. By the end, your player will be properly constrained to the maze's paths, making exploration feel authentic and challenging. Let's dive in and solidify our dungeon's walls!

## Adding Collision Logic to MovementSystem (Check Grid Cells)

The `MovementSystem` currently moves entities based on their `MovementComponent`, but it doesn't check if the new position is valid. Since our maze is built from wall entities, we can use their positions to determine if a move is blocked. We'll pass the `World` to the `MovementSystem` so it can query all entities and check for walls.

Update `lib/systems/movement_system.rb`:

```ruby
# lib/systems/movement_system.rb
require_relative "../logger"

module Systems
  class MovementSystem
    def initialize(world)
      @world = world # Access to all entities for collision checks
    end

    def process(entities, grid_width, grid_height)
      Logger.debug("MovementSystem processing #{entities.size} entities")

      entities.each do |entity|
        next unless entity.has_component?(Components::Position) &&
                    entity.has_component?(Components::Movement)

        pos = entity.get_component(Components::Position)
        mov = entity.get_component(Components::Movement)

        # Skip if no movement
        if mov.dx == 0 && mov.dy == 0
          Logger.debug("No movement for entity #{entity.id}")
          next
        end

        Logger.debug("Processing movement for entity #{entity.id}: dx=#{mov.dx}, dy=#{mov.dy}")
        Logger.debug("Current position: x=#{pos.x}, y=#{pos.y}")

        # Calculate proposed new position
        new_x = pos.x + mov.dx
        new_y = pos.y + mov.dy
        Logger.debug("Proposed new position: x=#{new_x}, y=#{new_y}")

        # Check grid boundaries
        unless new_x.between?(0, grid_width - 1) && new_y.between?(0, grid_height - 1)
          Logger.debug("Out of bounds: x=#{new_x}, y=#{new_y}, width=#{grid_width}, height=#{grid_height}")
          mov.dx = 0
          mov.dy = 0
          next
        end

        # Check for wall collision
        if wall_at?(new_x, new_y)
          Logger.debug("Wall collision at x=#{new_x}, y=#{new_y}")
          # Reset movement if blocked
          mov.dx = 0
          mov.dy = 0
          next
        end

        # If clear, update position
        pos.x = new_x
        pos.y = new_y
        Logger.debug("Position updated: x=#{pos.x}, y=#{pos.y}")

        # Reset movement after applying
        mov.dx = 0
        mov.dy = 0
      end
    end

    private

    def wall_at?(x, y)
      @world.entities.values.any? do |entity|
        pos = entity.get_component(Components::Position)
        render = entity.get_component(Components::Render)
        pos && pos.x == x && pos.y == y && render && render.character == "#"
      end
    end
  end
end
```

### Detailed Explanation

- **Why Pass `World`?**: The `World` holds all entities, including walls created by the `MazeSystem`. By giving `MovementSystem` access to `@world`, it can check for walls without needing a separate grid reference.
- **Collision Logic**:
  1. **Get Current State**: Fetch the entity's `Position` and `Movement` components.
  2. **Skip if No Movement**: If `dx` and `dy` are both 0, there's no movement to process.
  3. **Propose Move**: Calculate the new position (`new_x`, `new_y`) based on `dx` and `dy`.
  4. **Boundary Check**: Use `between?` to ensure the move stays within the grid (e.g., 0 to 9 for a 10-wide grid).
  5. **Wall Check**: Call `wall_at?` to see if there's a wall entity (identified by `#`) at the new position.
  6. **Apply or Block**: If no wall, update the position; if blocked, reset movement deltas to 0 (no move occurs).
- **wall_at?**: Loops through all entities, checking for one with a `Position` matching (x, y) and a `RenderComponent` with `#`. This is simple but not optimized—later, we could use a spatial hash for larger grids.
- **Logging**: We've added detailed logging to help debug movement issues. This is especially useful for understanding why a player can't move in a certain direction.

This ensures the player can't move into walls or outside the grid, but it only handles movement initiated by the player's `MovementComponent`.

## Creating CollisionSystem for Entity Interactions

The `MovementSystem` now respects walls, but what about future features—like enemies or items? We need a general-purpose `CollisionSystem` to handle entity-to-entity interactions. For now, it'll reinforce wall collisions by listening to the `:entity_moved` event and reverting moves that hit walls. This separates concerns: `MovementSystem` proposes moves, `CollisionSystem` validates them.

Create `lib/systems/collision_system.rb`:

```ruby
# lib/systems/collision_system.rb
require_relative "../event"
require_relative "../logger"

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
          Logger.error("Collision detected at (#{pos.x}, #{pos.y}) - move blocked!")
          # Reset to a safe position (temporary: assumes (1, 1) is clear)
          pos.x = 1
          pos.y = 1
        end
      end
    end

    private

    def wall_at?(x, y)
      @world.entities.values.any? do |entity|
        pos = entity.get_component(Components::Position)
        render = entity.get_component(Components::Render)
        pos && pos.x == x && pos.y == y && render && render.character == "#"
      end
    end
  end
end
```

### Detailed Breakdown

- **Purpose**: Listens for `:entity_moved` events and checks if the new position is valid.
- **Logic**:
  1. **Event Check**: Only processes `:entity_moved` events.
  2. **Find Entity**: Uses the `entity_id` from the event to get the moved entity.
  3. **Collision Test**: Checks if the entity's new position overlaps a wall.
  4. **Revert Move**: If a wall is hit, logs an error and resets the position to (1, 1) (a known safe spot for now). In a full implementation, we'd store the previous position in a component and revert to it.
- **Why Separate?**: This system can later handle enemy collisions, item pickups, or traps, keeping `MovementSystem` focused on movement mechanics.
- **Logging**: We use error logging for collision detection since it should never happen if the `MovementSystem` is working correctly.

For now, `CollisionSystem` is a safety net—`MovementSystem` already blocks most invalid moves, but this ensures nothing slips through and prepares us for more complex interactions.

## Updating the InputSystem for Movement Commands

Let's also update our `InputSystem` to properly integrate with the `MovementSystem`. We'll ensure it sets the movement deltas in the `MovementComponent`.

```ruby
# lib/systems/input_system.rb
require_relative "../event"
require_relative "../logger"

module Systems
  class InputSystem
    def initialize(event_manager)
      @event_manager = event_manager
    end

    def process(entities)
      @event_manager.process do |event|
        next unless event.type == :key_pressed

        key = event.data[:key]
        Logger.debug("Key pressed: #{key}")

        player = entities.find { |e| e.has_component?(Components::Input) }
        if player
          Logger.debug("Player found, processing movement")
          case key
          when "w" then issue_move_command(player, 0, -1)   # Up
          when "s" then issue_move_command(player, 0, 1)    # Down
          when "a" then issue_move_command(player, -1, 0)   # Left
          when "d" then issue_move_command(player, 1, 0)    # Right
          end
        else
          Logger.error("Player not found!")
        end
      end
    end

    private

    def issue_move_command(entity, dx, dy)
      return unless entity.has_component?(Components::Movement)

      movement = entity.get_component(Components::Movement)
      movement.dx = dx
      movement.dy = dy
      Logger.debug("Movement command issued: dx=#{dx}, dy=#{dy}")
    end
  end
end
```

This update ensures that when a player presses a movement key, the proper movement deltas are set in the player's `MovementComponent`. The `MovementSystem` will then use these deltas to calculate the new position while checking for collisions.

## Handling Wall Collisions and Boundaries

We've got two layers of collision handling:
1. **MovementSystem**: Prevents moves into walls proactively by checking before updating the position.
2. **CollisionSystem**: Reacts to `:entity_moved` events, catching any edge cases (e.g., if a system bypasses `MovementSystem`).

Update `game.rb` to integrate the `CollisionSystem`:

```ruby
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
require_relative "lib/systems/collision_system"
require_relative "lib/world"
require_relative "lib/keyboard_handler"
require_relative "lib/event"
require_relative "lib/logger"

world = World.new(width: 20, height: 10)

# Create player entity
player = world.create_entity
player.add_component(Components::Position.new(1, 1))  # Start inside maze
player.add_component(Components::Movement.new)
player.add_component(Components::Render.new("@"))
player.add_component(Components::Input.new)

# Add systems (order matters)
world.add_system(Systems::MazeSystem.new(world))
world.add_system(Systems::InputSystem.new(world.event_manager))
world.add_system(Systems::MovementSystem.new(world))
world.add_system(Systems::CollisionSystem.new(world, world.event_manager))
world.add_system(Systems::RenderSystem.new(20, 10))

# Start the game
world.run
```

### The Critical Game Loop Order

It's essential to understand how the order of systems affects gameplay:

1. **Handle Input First**: The game should process input before running systems, ensuring responsive gameplay.
2. **System Processing Order**:
   - **MazeSystem**: Generates walls first.
   - **InputSystem**: Processes key presses and sets movement deltas.
   - **MovementSystem**: Applies movement, checking for collisions.
   - **CollisionSystem**: Provides an extra safety layer for collision detection.
   - **RenderSystem**: Displays the final state.

This order ensures that player input is immediately reflected in the game state, making gameplay feel responsive and intuitive.

Run `ruby game.rb`, and you'll see your maze with the player at (1, 1). Use `w`, `a`, `s`, `d` to move—now, you'll stop at walls instead of passing through them! Quit with `q`.

## Testing Collision Detection

We should write tests to ensure our collision detection works properly:

```ruby
# spec/systems/movement_system_spec.rb
require_relative "../../lib/systems/movement_system"
require_relative "../../lib/world"
require_relative "../../lib/entity"
require_relative "../../lib/components/position"
require_relative "../../lib/components/movement"
require_relative "../../lib/components/render"

RSpec.describe Systems::MovementSystem do
  it "prevents movement into walls" do
    world = World.new(width: 3, height: 3)

    # Create a wall
    wall = world.create_entity
    wall.add_component(Components::Position.new(1, 0))
    wall.add_component(Components::Render.new("#"))

    # Create a player at (1, 1)
    player = world.create_entity
    player.add_component(Components::Position.new(1, 1))
    player.add_component(Components::Movement.new(0, -1)) # Try to move up into the wall

    # Process movement
    system = Systems::MovementSystem.new(world)
    system.process([player], 3, 3)

    # Player should still be at (1, 1), not (1, 0)
    pos = player.get_component(Components::Position)
    expect(pos.x).to eq(1)
    expect(pos.y).to eq(1)
  end

  it "allows movement to empty spaces" do
    world = World.new(width: 3, height: 3)

    # Create a player at (1, 1)
    player = world.create_entity
    player.add_component(Components::Position.new(1, 1))
    player.add_component(Components::Movement.new(1, 0)) # Try to move right to (2, 1)

    # Process movement
    system = Systems::MovementSystem.new(world)
    system.process([player], 3, 3)

    # Player should now be at (2, 1)
    pos = player.get_component(Components::Position)
    expect(pos.x).to eq(2)
    expect(pos.y).to eq(1)
  end
end
```

This test ensures that:
1. The `MovementSystem` prevents movement into walls
2. It allows movement to empty spaces

## Outcome

By the end of this chapter, you've:

- Enhanced the `MovementSystem` to check for walls and boundaries before moving entities
- Added detailed logging to track movement and collision events
- Created a `CollisionSystem` as a safety net for entity interactions
- Updated the `InputSystem` to properly issue movement commands
- Understood the critical importance of system ordering in the game loop

Your roguelike game now has proper collision detection, making exploration more challenging and authentic. Players must navigate the maze's paths rather than ghosting through walls, which is a key component of roguelike gameplay.

By handling input before running systems and checking for level completion immediately after movement, we've also ensured the game feels responsive and intuitive. The player can now explore the procedurally generated maze, avoiding walls and finding their way to the exit.

In the next chapter, we'll add items and treasures to our dungeon, giving players more to discover as they navigate the maze!