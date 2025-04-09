# Chapter 4: Movement and Positioning

Our ECS foundation is solid, and now it’s time to make our game feel alive. In this chapter, we’ll enhance our movement mechanics by adding a `MovementComponent`, refining our `PositionComponent`, and introducing a grid for spatial awareness. We’ll also write a `MovementSystem` that updates positions based on direction and tie it all together with basic input handling. By the end, you’ll be able to move a player character around a grid using simple keyboard controls—our roguelike is starting to take shape!

## Creating PositionComponent and MovementComponent

Let’s refine our `PositionComponent` to work with a grid and introduce a `MovementComponent` to handle direction.

### PositionComponent

We’ll keep `PositionComponent` as a simple x/y container but ensure it’s grid-friendly. Update `lib/components/position.rb`:

```ruby
# lib/components/position.rb
module Components
  class Position
    attr_accessor :x, :y

    def initialize(x, y)
      @x = x
      @y = y
    end

    def to_h
      { x: @x, y: @y }
    end

    def self.from_h(hash)
      new(hash[:x], hash[:y])
    end
  end
end
```

No major changes yet—it’s still a data container for `x` and `y`. We’ll enforce grid boundaries later via the `World` or a system.

### MovementComponent

The `MovementComponent` will store the intended direction of movement. Create `lib/components/movement.rb`:

```ruby
# lib/components/movement.rb
module Components
  class Movement
    attr_accessor :dx, :dy

    def initialize(dx = 0, dy = 0)
      @dx = dx  # Delta x (horizontal movement)
      @dy = dy  # Delta y (vertical movement)
    end

    def to_h
      { dx: @dx, dy: @dy }
    end

    def self.from_h(hash)
      new(hash[:dx], hash[:dy])
    end
  end
end
```

Here, `dx` and `dy` represent the change in position (e.g., `dx: 1` means move right, `dy: -1` means move up). This component will be updated based on input and processed by the `MovementSystem`.

## Writing MovementSystem with Direction-Based Updates

The `MovementSystem` will now use the `MovementComponent` to update an entity’s `PositionComponent`. Update `lib/systems/movement_system.rb`:

```ruby
# lib/systems/movement_system.rb
module Systems
  class MovementSystem
    def process(entities, grid_width, grid_height)
      entities.each do |entity|
        next unless entity.has_component?(Components::Position) &&
                    entity.has_component?(Components::Movement)

        pos = entity.get_component(Components::Position)
        mov = entity.get_component(Components::Movement)

        # Calculate new position
        new_x = pos.x + mov.dx
        new_y = pos.y + mov.dy

        # Ensure entity stays within grid bounds
        if new_x.between?(0, grid_width - 1) && new_y.between?(0, grid_height - 1)
          pos.x = new_x
          pos.y = new_y
        end

        # Reset movement after applying it
        mov.dx = 0
        mov.dy = 0
      end
    end
  end
end
```

This system:
- Checks for entities with both `Position` and `Movement` components.
- Updates the position based on `dx` and `dy`.
- Enforces grid boundaries (passed as `grid_width` and `grid_height`).
- Resets movement deltas after applying them, so the entity doesn’t keep moving without new input.

## Adding a Simple Grid (Rows, Columns) for Spatial Awareness

To give our game spatial structure, we’ll define a grid with rows and columns in the `World`. Update `lib/world.rb`:

```ruby
# lib/world.rb
require "io/console"  # For non-blocking input

class World
  attr_reader :entities

  def initialize(width: 10, height: 5)
    @entities = {}
    @systems = []
    @next_id = 0
    @width = width
    @height = height
    @running = true
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
      handle_input
      @systems.each { |system| system.process(@entities.values, @width, @height) }
      render
      sleep(0.1)  # Control frame rate
    end
    puts "Goodbye!"
  end

  private

  def render
    system("clear") || system("cls")
    grid = Array.new(@height) { Array.new(@width) { "." } }  # Empty grid with dots
    @entities.values.each do |entity|
      if entity.has_component?(Components::Position)
        pos = entity.get_component(Components::Position)
        grid[pos.y][pos.x] = "@" if pos.y.between?(0, @height - 1) && pos.x.between?(0, @width - 1)
      end
    end
    grid.each { |row| puts row.join(" ") }
  end

  def handle_input
    input = gets.chomp.downcase  # Wait for user input

    case input
    when "w" then move_player(0, -1)  # Up
    when "s" then move_player(0, 1)   # Down
    when "a" then move_player(-1, 0)  # Left
    when "d" then move_player(1, 0)   # Right
    when "q" then @running = false    # Quit
    end
  end

  def move_player(dx, dy)
    player = @entities.values.find { |e| e.has_component?(Components::Movement) }
    if player
      movement = player.get_component(Components::Movement)
      movement.dx = dx
      movement.dy = dy
    end
  end
end
```

Key changes:
- Added `width` and `height` to define the grid (defaulting to 10x5).
- Render now builds a 2D grid, placing the player (`@`) at its position.
- Added basic input handling (see below).

## Handling Basic Input (e.g., Arrow Keys)

Since terminals don’t easily handle arrow keys without extra setup, we’ll use `w` (up), `a` (left), `s` (down), and `d` (right) for simplicity. We’ve added non-blocking input using `STDIN.getch` with `io/console`. The `handle_input` method updates the player’s `MovementComponent` based on key presses, and `q` exits the game.

Update `game.rb` to tie it all together:

```ruby
# game.rb
require_relative "lib/components/position"
require_relative "lib/components/movement"
require_relative "lib/entity"
require_relative "lib/systems/movement_system"
require_relative "lib/world"

world = World.new(width: 10, height: 5)

# Create player entity
player = world.create_entity
player.add_component(Components::Position.new(0, 0))  # Start at top-left
player.add_component(Components::Movement.new)        # Add movement capability

# Add MovementSystem
world.add_system(Systems::MovementSystem.new)

# Start the game
world.run
```

Run `ruby game.rb`, and you’ll see a 10x5 grid with an `@` at (0, 0). Press `w`, `a`, `s`, or `d` to move, and `q` to quit. The player stays within the grid thanks to the `MovementSystem`’s bounds checking.

### Updated Project Structure

```
roguelike/
├── Gemfile
├── game.rb
├── lib/
│   ├── components/
│   │   ├── position.rb
│   │   └── movement.rb  (new)
│   ├── systems/
│   │   └── movement_system.rb
│   ├── entity.rb
│   └── world.rb
├── spec/
│   ├── components/
│   │   ├── position_spec.rb
│   │   └── movement_spec.rb  (new, below)
│   ├── systems/
│   │   └── movement_system_spec.rb
│   ├── entity_spec.rb
│   ├── world_spec.rb
│   └── game_spec.rb
└── README.md
```

New test for `MovementComponent` in `spec/components/movement_spec.rb`:

```ruby
# spec/components/movement_spec.rb
require_relative "../../lib/components/movement"

RSpec.describe Components::Movement do
  it "serializes and deserializes correctly" do
    mov = Components::Movement.new(1, -1)
    expect(Components::Movement.from_h(mov.to_h).dx).to eq(1)
  end
end
```

Update `spec/systems/movement_system_spec.rb` to reflect the new system:

```ruby
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
    system.process([entity], 5, 5)  # 5x5 grid
    expect(entity.get_component(Components::Position).x).to eq(1)
    expect(entity.get_component(Components::Movement).dx).to eq(0)  # Reset after move
  end
end
```

Run `bundle exec rspec` to verify everything works.

## Outcome

By the end of this chapter, you’ve:
- Created `PositionComponent` and `MovementComponent`.
- Written a `MovementSystem` that updates positions based on direction.
- Added a simple grid for spatial awareness.
- Implemented basic input handling with `w`, `a`, `s`, `d`.

You can now move a player character (`@`) around a 10x5 grid! This sets the stage for our roguelike—next, we’ll add walls, items, and collision detection to flesh out the maze. Run `ruby game.rb`, experiment with movement, and get ready for Chapter 5!
