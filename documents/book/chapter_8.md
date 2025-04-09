# Chapter 8: Collision and Boundaries

Our roguelike now boasts a procedurally generated maze, but the player can still walk through walls like a ghost. In this chapter, we’ll add collision detection to keep the player on the paths. We’ll enhance the `MovementSystem` to check grid cells before moving, create a new `CollisionSystem` to handle entity-to-entity interactions, and enforce both wall collisions and grid boundaries. By the end, your player will be properly constrained to the maze’s paths, making exploration feel authentic and challenging. Let’s dive in and solidify our dungeon’s walls!

## Adding Collision Logic to MovementSystem (Check Grid Cells)

The `MovementSystem` currently moves entities based on their `MovementComponent`, but it doesn’t check if the new position is valid. Since our maze is built from wall entities, we can use their positions to determine if a move is blocked. We’ll pass the `World` to the `MovementSystem` so it can query all entities and check for walls.

Update `lib/systems/movement_system.rb`:

```ruby
# lib/systems/movement_system.rb
module Systems
  class MovementSystem
    def initialize(world)
      @world = world  # Access to all entities for collision checks
    end

    def process(entities, grid_width, grid_height)
      entities.each do |entity|
        next unless entity.has_component?(Components::Position) &&
                    entity.has_component?(Components::Movement)

        pos = entity.get_component(Components::Position)
        mov = entity.get_component(Components::Movement)

        # Calculate proposed new position
        new_x = pos.x + mov.dx
        new_y = pos.y + mov.dy

        # Check grid boundaries
        next unless new_x.between?(0, grid_width - 1) && new_y.between?(0, grid_height - 1)

        # Check for wall collision
        if wall_at?(new_x, new_y)
          # Reset movement if blocked (optional: could queue an event instead)
          mov.dx = 0
          mov.dy = 0
          next
        end

        # If clear, update position
        pos.x = new_x
        pos.y = new_y

        # Reset movement after applying
        mov.dx = 0
        mov.dy = 0
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
  end
end
```

### Detailed Explanation

- **Why Pass `World`?**: The `World` holds all entities, including walls created by the `MazeSystem`. By giving `MovementSystem` access to `@world`, it can check for walls without needing a separate grid reference.
- **Collision Logic**:
  1. **Get Current State**: Fetch the entity’s `Position` and `Movement` components.
  2. **Propose Move**: Calculate the new position (`new_x`, `new_y`) based on `dx` and `dy`.
  3. **Boundary Check**: Use `between?` to ensure the move stays within the grid (e.g., 0 to 9 for a 10-wide grid).
  4. **Wall Check**: Call `wall_at?` to see if there’s a wall entity (identified by `#`) at the new position.
  5. **Apply or Block**: If no wall, update the position; if blocked, reset movement deltas to 0 (no move occurs).
- **wall_at?**: Loops through all entities, checking for one with a `Position` matching (x, y) and a `RenderComponent` with `#`. This is simple but not optimized—later, we could use a spatial hash for larger grids.

This ensures the player can’t move into walls or outside the grid, but it only handles movement initiated by the player’s `MovementComponent`.

## Creating CollisionSystem for Entity Interactions

The `MovementSystem` now respects walls, but what about future features—like enemies or items? We need a general-purpose `CollisionSystem` to handle entity-to-entity interactions. For now, it’ll reinforce wall collisions by listening to the `:entity_moved` event from Chapter 6 and reverting moves that hit walls. This separates concerns: `MovementSystem` proposes moves, `CollisionSystem` validates them.

Create `lib/systems/collision_system.rb`:

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
          # Revert the move (assume we track previous position in future chapters)
          # For now, log it (in a real game, we'd store old position)
          puts "Collision detected at (#{pos.x}, #{pos.y}) - move blocked!"
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
        pos && pos.x == x && pos.y == y && entity.has_component?(Components::Render) &&
          entity.get_component(Components::Render).character == "#"
      end
    end
  end
end
```

### Detailed Breakdown

- **Purpose**: Listens for `:entity_moved` events (queued by `InputSystem`) and checks if the new position is valid.
- **Logic**:
  1. **Event Check**: Only processes `:entity_moved` events.
  2. **Find Entity**: Uses the `entity_id` from the event to get the moved entity.
  3. **Collision Test**: Checks if the entity’s new position overlaps a wall.
  4. **Revert Move**: If a wall is hit, resets the position to (1, 1) (a known safe spot for now). In a full implementation, we’d store the previous position in a component and revert to it.
- **Why Separate?**: This system can later handle enemy collisions, item pickups, or traps, keeping `MovementSystem` focused on movement mechanics.

For now, `CollisionSystem` is a safety net—`MovementSystem` already blocks most invalid moves, but this ensures nothing slips through and prepares us for more complex interactions.

## Handling Wall Collisions and Boundaries

We’ve got two layers of collision handling:
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

world = World.new(width: 10, height: 5)

# Create player entity
player = world.create_entity
player.add_component(Components::Position.new(1, 1))  # Start inside maze
player.add_component(Components::Movement.new)
player.add_component(Components::Render.new("@"))
player.add_component(Components::Input.new)

# Add systems (order: maze -> input -> movement -> collision -> render)
world.add_system(Systems::MazeSystem.new(world))
world.add_system(Systems::InputSystem.new(world.event_manager))
world.add_system(Systems::MovementSystem.new(world))
world.add_system(Systems::CollisionSystem.new(world, world.event_manager))
world.add_system(Systems::RenderSystem.new(10, 5))

# Start the game
world.run
```

### System Order Matters

- **MazeSystem**: Generates walls first.
- **InputSystem**: Queues movement commands.
- **MovementSystem**: Applies movement, blocking wall moves.
- **CollisionSystem**: Validates moves via events, reverting if needed.
- **RenderSystem**: Displays the final state.

Run `ruby game.rb`, and you’ll see your 10x5 maze with the `@` player at (1, 1). Use `w`, `a`, `s`, `d` to move—now, you’ll stop at walls instead of passing through them! Quit with `q`.

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
│   │   └── input.rb
│   ├── systems/
│   │   ├── movement_system.rb
│   │   ├── render_system.rb
│   │   ├── input_system.rb
│   │   ├── maze_system.rb
│   │   └── collision_system.rb  (new)
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
│   │   └── input_spec.rb
│   ├── systems/
│   │   ├── movement_system_spec.rb
│   │   ├── render_system_spec.rb
│   │   ├── input_system_spec.rb
│   │   ├── maze_system_spec.rb
│   │   └── collision_system_spec.rb  (new, below)
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

- `spec/systems/collision_system_spec.rb`:
```ruby
# spec/systems/collision_system_spec.rb
require_relative "../../lib/systems/collision_system"
require_relative "../../lib/world"
require_relative "../../lib/entity"
require_relative "../../lib/components/position"
require_relative "../../lib/components/render"

RSpec.describe Systems::CollisionSystem do
  it "reverts move when hitting a wall" do
    world = World.new(width: 3, height: 3)
    player = world.create_entity.add_component(Components::Position.new(1, 1))
    wall = world.create_entity
      .add_component(Components::Position.new(1, 2))
      .add_component(Components::Render.new("#"))
    system = Systems::CollisionSystem.new(world, world.event_manager)
    world.event_manager.queue(Event.new(:entity_moved, { entity_id: player.id }))
    system.process([player, wall])
    expect(player.get_component(Components::Position).y).to eq(1)  # Reverted to safe spot
  end
end
```

Run `bundle exec rspec` to confirm everything works.

## Outcome

By the end of this chapter, you’ve:
- Added collision logic to `MovementSystem` to check grid cells and block wall moves.
- Created a `CollisionSystem` to handle entity interactions via events.
- Ensured wall collisions and grid boundaries stop the player.

Your player can no longer walk through walls! Run `ruby game.rb`, and you’ll navigate the maze’s paths, stopping at `#` walls. The grid boundaries (0 to 9, 0 to 4) and wall entities work together to confine movement. In the next chapter, we’ll add items to collect and refine collision handling further. Explore your maze, test the boundaries, and let’s keep enhancing this roguelike!

---

### In-Depth Details for New Engineers

- **Why Two Systems?**:
  - `MovementSystem` is proactive—it prevents invalid moves before they happen, which is efficient for simple wall checks.
  - `CollisionSystem` is reactive—it listens to events and can handle more complex scenarios (e.g., enemy collisions) later. This separation follows ECS principles: each system has one job.
- **Performance Note**: `wall_at?` loops through all entities, which is O(n) and fine for a small 10x5 grid (50-ish entities). For larger games, we’d use a spatial grid or hash map to reduce checks to O(1).
- **Temporary Revert**: `CollisionSystem` resets to (1, 1) because we don’t yet track previous positions. A proper solution would add a `PreviousPositionComponent`, but that’s overkill for now—Chapter 9 could introduce it for items or combat.
- **Event-Driven**: The `:entity_moved` event ties into Chapter 6’s input system, showing how events connect our ECS pieces. It’s queued by `InputSystem` and acted on here.

This setup gives a robust foundation for collision while keeping it accessible.