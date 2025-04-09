# Chapter 5: Rendering the Game World

Our roguelike is taking shape with a player moving on a grid, but it’s still a bit bare-bones. In this chapter, we’ll bring the game world to life by adding a `RenderComponent` to define how entities look, creating a `RenderSystem` to handle console output, and improving our grid rendering. We’ll also refine the game loop to clearly separate clearing the screen, updating the state, and rendering the result. By the end, you’ll see your player moving across a terminal window in a visually distinct way—our dungeon is starting to feel real!

## Designing RenderComponent (Character, Color)

The `RenderComponent` will define an entity’s appearance—its character (e.g., `@` for the player) and, optionally, a color. For now, we’ll stick to simple ASCII characters in the terminal, but we’ll structure it to support color later (e.g., with a gem like `curses` if we expand).

Create `lib/components/render.rb`:

```ruby
# lib/components/render.rb
module Components
  class Render
    attr_accessor :character, :color

    def initialize(character, color = nil)
      @character = character  # e.g., "@", "#", etc.
      @color = color          # Placeholder for future color support (e.g., :red)
    end

    def to_h
      { character: @character, color: @color }
    end

    def self.from_h(hash)
      new(hash[:character], hash[:color])
    end
  end
end
```

- `character`: A single-character string representing the entity on the grid.
- `color`: A placeholder for future enhancements (nil for now, as terminal colors require extra setup).

## Building RenderSystem for Console Output

The `RenderSystem` will handle drawing entities to the console, using their `Position` and `Render` components. For now, it’ll place characters on a grid, but it’s designed to be extensible.

Create `lib/systems/render_system.rb`:

```ruby
# lib/systems/render_system.rb
module Systems
  class RenderSystem
    def initialize(width, height)
      @width = width
      @height = height
    end

    def process(entities)
      # Clear the screen
      system("clear") || system("cls")

      # Build an empty grid
      grid = Array.new(@height) { Array.new(@width) { "." } }

      # Place entities on the grid
      entities.each do |entity|
        next unless entity.has_component?(Components::Position) &&
                    entity.has_component?(Components::Render)

        pos = entity.get_component(Components::Position)
        render = entity.get_component(Components::Render)

        if pos.x.between?(0, @width - 1) && pos.y.between?(0, @height - 1)
          grid[pos.y][pos.x] = render.character
        end
      end

      # Render the grid to the console
      grid.each { |row| puts row.join(" ") }
      puts "\nMove with w (up), a (left), s (down), d (right), or q to quit:"
    end
  end
end
```

This system:
- Clears the screen each frame.
- Builds a grid with dots (`.`) as the background.
- Overwrites grid cells with entity characters based on their positions.
- Prints the grid and a prompt.

## Rendering the Player and Grid

We’ll update the `World` to use the `RenderSystem` instead of handling rendering itself. This keeps responsibilities separate—`World` manages the game loop, while `RenderSystem` handles output. Update `lib/world.rb`:

```ruby
# lib/world.rb
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
      @systems.each { |system| system.process(@entities.values) }
      handle_input
    end
    puts "Goodbye!"
  end

  private

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
- Removed the `render` method from `World`.
- Reordered the loop to process systems (including rendering) before handling input, ensuring the updated state is shown before the next turn.

## Adding a Game Loop with Clear/Update/Render Phases

Our game loop now naturally separates into:
- **Clear**: Handled by `RenderSystem` via `system("clear")`.
- **Update**: Handled by `MovementSystem` processing entity positions.
- **Render**: Handled by `RenderSystem` drawing the grid.

Update `game.rb` to include the new `RenderComponent` and `RenderSystem`:

```ruby
# game.rb
require_relative "lib/components/position"
require_relative "lib/components/movement"
require_relative "lib/components/render"
require_relative "lib/entity"
require_relative "lib/systems/movement_system"
require_relative "lib/systems/render_system"
require_relative "lib/world"

world = World.new(width: 10, height: 5)

# Create player entity
player = world.create_entity
player.add_component(Components::Position.new(0, 0))  # Start at top-left
player.add_component(Components::Movement.new)        # Add movement capability
player.add_component(Components::Render.new("@"))    # Render as "@"

# Add systems (order matters: update before render)
world.add_system(Systems::MovementSystem.new)
world.add_system(Systems::RenderSystem.new(10, 5))

# Start the game
world.run
```

Run `ruby game.rb`, and you’ll see a 10x5 grid with an `@` at (0, 0). Type `w`, `a`, `s`, or `d` and press Enter to move the player one space per turn, or `q` to quit. Each turn clears the screen, updates the player’s position, and renders the new state.

### Updated Project Structure

```
roguelike/
├── Gemfile
├── game.rb
├── lib/
│   ├── components/
│   │   ├── position.rb
│   │   ├── movement.rb
│   │   └── render.rb  (new)
│   ├── systems/
│   │   ├── movement_system.rb
│   │   └── render_system.rb  (new)
│   ├── entity.rb
│   └── world.rb
├── spec/
│   ├── components/
│   │   ├── position_spec.rb
│   │   ├── movement_spec.rb
│   │   └── render_spec.rb  (new, below)
│   ├── systems/
│   │   ├── movement_system_spec.rb
│   │   └── render_system_spec.rb  (new, below)
│   ├── entity_spec.rb
│   ├── world_spec.rb
│   └── game_spec.rb
└── README.md
```

New tests:

- `spec/components/render_spec.rb`:
```ruby
# spec/components/render_spec.rb
require_relative "../../lib/components/render"

RSpec.describe Components::Render do
  it "serializes and deserializes correctly" do
    render = Components::Render.new("@", :red)
    expect(Components::Render.from_h(render.to_h).character).to eq("@")
  end
end
```

- `spec/systems/render_system_spec.rb`:
```ruby
# spec/systems/render_system_spec.rb
require_relative "../../lib/systems/render_system"
require_relative "../../lib/entity"
require_relative "../../lib/components/position"
require_relative "../../lib/components/render"

RSpec.describe Systems::RenderSystem do
  it "renders entities to the grid" do
    entity = Entity.new(1)
      .add_component(Components::Position.new(1, 1))
      .add_component(Components::Render.new("@"))
    system = Systems::RenderSystem.new(3, 3)
    expect { system.process([entity]) }.to output(/\. \. \.\n\. @ \.\n\. \. \./).to_stdout
  end
end
```

Run `bundle exec rspec` to verify everything works. Note: The `RenderSystem` test checks output, which includes the prompt—adjust the regex if needed.

## Outcome

By the end of this chapter, you’ve:
- Designed a `RenderComponent` with character and color properties.
- Built a `RenderSystem` for console output.
- Rendered the player and grid in the terminal.
- Refined the game loop with clear, update, and render phases.

You can now see your player (`@`) moving across a 10x5 grid in the terminal, one turn at a time! This visual feedback makes the game feel more engaging. In the next chapter, we’ll add walls and items to start building the maze. Run `ruby game.rb`, watch your player roam, and let’s keep crafting this roguelike!
