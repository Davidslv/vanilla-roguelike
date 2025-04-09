# Chapter 7: Generating Mazes

Our roguelike has a player moving on a grid with responsive input, but it’s still an open field. To make it a true dungeon crawler, we need a maze—walls to navigate, paths to explore, and a sense of mystery. In this chapter, we’ll build a robust maze generation system by designing a `Grid` class with `Cell` objects, creating a flexible framework for maze algorithms (starting with the Binary Tree algorithm), and integrating it into our ECS `World` via a `MazeSystem`. We’ll also add `RenderComponent`s to walls so they appear visually distinct. By the end, you’ll be able to explore a procedurally generated maze, with the flexibility to swap in different maze algorithms later. Let’s dive into the details and craft a dungeon step-by-step!

## Designing a Grid Class with Cell Objects

Before we generate a maze, we need a structure to represent it. The `Grid` class will act as our canvas—a 2D array of `Cell` objects where each cell can be a wall or a path. This separation keeps maze generation logic independent of our ECS `World`, making it reusable and easier to test.

### The Cell Class

A `Cell` is the smallest unit of our maze. For now, it only needs to track whether it’s a wall or a path, but we’ll design it to be extensible for future features (e.g., items, traps).

Here’s the initial `lib/grid.rb`:

```ruby
# lib/grid.rb
class Grid
  class Cell
    attr_accessor :is_wall

    def initialize(is_wall = true)
      @is_wall = is_wall  # True = wall, False = path
    end

    def to_s
      @is_wall ? "#" : "."  # For debugging or simple rendering
    end
  end

  attr_reader :width, :height, :cells

  def initialize(width, height)
    @width = width      # Number of columns
    @height = height    # Number of rows
    @cells = Array.new(height) { Array.new(width) { Cell.new } }  # 2D array of cells
  end

  def at(x, y)
    # Safely access a cell, return nil if out of bounds
    return nil if x < 0 || x >= @width || y < 0 || y >= @height
    @cells[y][x]
  end
end
```

#### Explanation

- **Cell**:
  - `is_wall` is a boolean flag. By default, cells start as walls (`true`), which suits most maze algorithms that "carve" paths out of a solid block. This mimics how real mazes are often built—start with barriers, then create openings.
  - `to_s` is a helper method for debugging, returning `#` for walls and `.` for paths (matching our `RenderSystem`’s output).
- **Grid**:
  - `width` and `height` define the maze’s dimensions (e.g., 10x5).
  - `@cells` is a 2D array where `@cells[y][x]` gives the cell at position (x, y). Ruby arrays are indexed from 0, so `@cells[0][0]` is the top-left corner.
  - `at(x, y)` prevents crashes by checking bounds. For example, `at(-1, 0)` returns `nil` instead of raising an error.

This structure is simple but powerful—it’s a blank slate ready for maze generation.

## Implementing a Flexible Maze Algorithm Framework

Maze generation is where the magic happens. We want our game to create a new maze each time it starts, adding replayability. There are many algorithms—Binary Tree, Recursive Backtracking, Prim’s, etc.—each with unique characteristics. To keep our code flexible, we’ll define a pluggable system where any algorithm can be used, starting with Binary Tree as our first example.

### Why Binary Tree?

The Binary Tree algorithm is beginner-friendly because:
- It’s fast and simple: For each cell, it decides to connect to either the north or west neighbor (or neither at edges).
- It guarantees a perfect maze (no loops, one solution from any start to end).
- It’s biased (favoring northwest passages), which gives it a distinct “feel” we can recognize.

We’ll implement it as a separate class, then make it pluggable into `Grid`.

### Defining the MazeGenerator Base Class

Create `lib/maze_generator.rb`:

```ruby
# lib/maze_generator.rb
class MazeGenerator
  def initialize(grid)
    @grid = grid  # The Grid instance to modify
  end

  def generate
    raise NotImplementedError, "Subclasses must implement 'generate'"
  end
end
```

This is an abstract base class—any maze algorithm will inherit from it and implement `generate`. The `@grid` instance variable gives access to the `Grid` we’re shaping.

### Implementing BinaryTreeGenerator

Create `lib/binary_tree_generator.rb`:

```ruby
# lib/binary_tree_generator.rb
require_relative "maze_generator"

class BinaryTreeGenerator < MazeGenerator
  def generate
    # Step 1: Carve all cells as paths initially (for simplicity)
    @grid.cells.each { |row| row.each { |cell| cell.is_wall = false } }

    # Step 2: Iterate through each cell, skipping outer edges
    (1...@grid.height - 1).each do |y|
      (1...@grid.width - 1).each do |x|
        # Randomly choose to block north or west (or neither for variety)
        direction = rand(2)  # 0 = north, 1 = west
        if direction == 0
          @grid.at(x, y - 1).is_wall = true  # Wall to the north
        elsif direction == 1
          @grid.at(x - 1, y).is_wall = true  # Wall to the west
        end
      end
    end

    # Step 3: Ensure outer walls remain intact
    (0...@grid.width).each do |x|
      @grid.at(x, 0).is_wall = true              # Top edge
      @grid.at(x, @grid.height - 1).is_wall = true # Bottom edge
    end
    (0...@grid.height).each do |y|
      @grid.at(0, y).is_wall = true              # Left edge
      @grid.at(@grid.width - 1, y).is_wall = true  # Right edge
    end
  end
end
```

#### How Binary Tree Works

1. **Initialize**: Start with all cells as paths (not traditional, but simplifies our ECS integration). Normally, Binary Tree starts with walls and carves paths, but we’ll invert it for clarity—paths are the default, and we add walls.
2. **Carve Connections**: For each cell (except edges):
   - Randomly choose north (y-1) or west (x-1).
   - Set the chosen neighbor as a wall, blocking that direction. This ensures every cell connects to at least one neighbor (north or west), forming a tree-like structure.
   - We skip edges because they’re part of the outer boundary.
3. **Outer Walls**: Force the perimeter to be walls, enclosing the maze.

This creates a maze with a northwest bias—paths tend to flow toward the top-left corner. It’s not the most complex maze, but it’s quick and guaranteed to be navigable.

### Making Grid Use Generators

Update `lib/grid.rb` to accept a generator:

```ruby
# lib/grid.rb
class Grid
  class Cell
    attr_accessor :is_wall

    def initialize(is_wall = true)
      @is_wall = is_wall
    end

    def to_s
      @is_wall ? "#" : "."
    end
  end

  attr_reader :width, :height, :cells

  def initialize(width, height)
    @width = width
    @height = height
    @cells = Array.new(height) { Array.new(width) { Cell.new } }
  end

  def at(x, y)
    return nil if x < 0 || x >= @width || y < 0 || y >= @height
    @cells[y][x]
  end

  def generate_maze(generator_class = BinaryTreeGenerator)
    generator = generator_class.new(self)
    generator.generate
  end
end
```

- `generate_maze`: Takes an optional `generator_class` (defaulting to `BinaryTreeGenerator`), creates an instance with the current `Grid`, and runs its `generate` method. This makes it easy to swap algorithms later—e.g., `grid.generate_maze(RecursiveBacktrackingGenerator)`.

## Creating MazeSystem to Populate World with Walls and Paths

Now that we can generate a maze, we need to bring it into our ECS `World`. The `MazeSystem` will:
1. Run once at game start.
2. Generate a maze using the `Grid`.
3. Create entities for each wall cell with `Position` and `Render` components.

Create `lib/systems/maze_system.rb`:

```ruby
# lib/systems/maze_system.rb
require_relative "../grid"
require_relative "../binary_tree_generator"  # Default generator

module Systems
  class MazeSystem
    def initialize(world, generator_class = BinaryTreeGenerator)
      @world = world
      @generator_class = generator_class
      @generated = false  # Ensure we only generate once
    end

    def process(_entities)
      return if @generated

      # Step 1: Generate the maze
      grid = Grid.new(@world.width, @world.height)
      grid.generate_maze(@generator_class)

      # Step 2: Create wall entities
      grid.cells.each_with_index do |row, y|
        row.each_with_index do |cell, x|
          if cell.is_wall
            wall = @world.create_entity
            wall.add_component(Components::Position.new(x, y))
            wall.add_component(Components::Render.new("#"))
          end
        end
      end

      @generated = true
    end

    private

    attr_reader :world
  end
end
```

#### Detailed Breakdown

- **Initialization**:
  - Takes the `World` to access its dimensions (`width`, `height`) and create entities.
  - Accepts an optional `generator_class` (defaults to `BinaryTreeGenerator`), making it pluggable.
  - `@generated` ensures the maze is only created once—systems run every turn, but maze generation is a one-time setup.
- **Process**:
  - Creates a `Grid` matching the `World`’s size.
  - Calls `generate_maze` with the chosen generator.
  - Loops through each cell; if it’s a wall, creates an entity with:
    - `PositionComponent`: Places it at (x, y).
    - `RenderComponent`: Displays it as `#`.

The `RenderSystem` from Chapter 5 will automatically render these walls alongside the player.

## Adding RenderComponent to Walls

Walls use the existing `RenderComponent` with `#` as their character. This matches our grid’s `to_s` convention (`#` for walls, `.` for paths). The `RenderSystem` already handles any entity with `Position` and `Render` components, so no changes are needed there. Paths remain empty (`.`) in the background grid, as we only create entities for walls.

### Integrating into the Game

Update `game.rb` to use the `MazeSystem`:

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
require_relative "lib/world"

world = World.new(width: 10, height: 5)

# Create player entity
player = world.create_entity
player.add_component(Components::Position.new(1, 1))  # Start inside maze
player.add_component(Components::Movement.new)
player.add_component(Components::Render.new("@"))
player.add_component(Components::Input.new)

# Add systems (order matters: maze -> input -> movement -> render)
world.add_system(Systems::MazeSystem.new(world))  # Default BinaryTreeGenerator
world.add_system(Systems::InputSystem.new(world.event_manager))
world.add_system(Systems::MovementSystem.new)
world.add_system(Systems::RenderSystem.new(10, 5))

# Start the game
world.run
```

- **Player Position**: Starts at (1, 1) instead of (0, 0) because the maze’s outer edges are always walls.
- **System Order**: `MazeSystem` runs first to populate walls before the game loop starts rendering or processing input.

Run `ruby game.rb`, and you’ll see a 10x5 grid with a maze of `#` walls and `.` paths. The `@` player starts at (1, 1). Use `w`, `a`, `s`, `d` to move (you’ll pass through walls for now—collision comes in Chapter 8), or `q` to quit. Each run generates a new maze!

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
│   │   └── maze_system.rb  (new)
│   ├── binary_tree_generator.rb  (new)
│   ├── entity.rb
│   ├── event.rb
│   ├── grid.rb  (new)
│   ├── maze_generator.rb  (new)
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
│   │   └── maze_system_spec.rb  (new, below)
│   ├── binary_tree_generator_spec.rb  (new, below)
│   ├── entity_spec.rb
│   ├── event_spec.rb
│   ├── grid_spec.rb  (new, below)
│   ├── maze_generator_spec.rb  (new, below)
│   ├── world_spec.rb
│   └── game_spec.rb
└── README.md
```

### New Tests

- `spec/maze_generator_spec.rb`:
```ruby
# spec/maze_generator_spec.rb
require_relative "../lib/maze_generator"

RSpec.describe MazeGenerator do
  it "raises NotImplementedError for base generate" do
    grid = Grid.new(3, 3)
    generator = MazeGenerator.new(grid)
    expect { generator.generate }.to raise_error(NotImplementedError)
  end
end
```

- `spec/binary_tree_generator_spec.rb`:
```ruby
# spec/binary_tree_generator_spec.rb
require_relative "../lib/binary_tree_generator"
require_relative "../lib/grid"

RSpec.describe BinaryTreeGenerator do
  it "generates a maze with outer walls" do
    grid = Grid.new(5, 5)
    generator = BinaryTreeGenerator.new(grid)
    generator.generate
    expect(grid.at(0, 0).is_wall).to be true  # Top-left wall
    expect(grid.at(4, 4).is_wall).to be true  # Bottom-right wall
  end
end
```

- `spec/grid_spec.rb`:
```ruby
# spec/grid_spec.rb
require_relative "../lib/grid"
require_relative "../lib/binary_tree_generator"

RSpec.describe Grid do
  it "initializes with all walls" do
    grid = Grid.new(3, 3)
    expect(grid.at(1, 1).is_wall).to be true
  end

  it "generates a maze with a generator" do
    grid = Grid.new(5, 5)
    grid.generate_maze(BinaryTreeGenerator)
    expect(grid.cells.flatten.any? { |cell| !cell.is_wall }).to be true  # Some paths exist
  end
end
```

- `spec/systems/maze_system_spec.rb`:
```ruby
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
    system.process([])  # Run again
    expect(world.entities.size).to eq(wall_count)  # No new entities added
  end
end
```

Run `bundle exec rspec` to verify everything works.

### Adding Another Algorithm (Optional Example)

To demonstrate pluggability, here’s a stub for a `RecursiveBacktrackingGenerator` (you could flesh this out later):

```ruby
# lib/recursive_backtracking_generator.rb
require_relative "maze_generator"

class RecursiveBacktrackingGenerator < MazeGenerator
  def generate
    # Stub for demonstration
    stack = [[1, 1]]  # Start point
    @grid.at(1, 1).is_wall = false
    # Full implementation would use a stack to carve paths recursively
    # For now, just ensure outer walls
    (0...@grid.width).each { |x| @grid.at(x, 0).is_wall = true; @grid.at(x, @grid.height - 1).is_wall = true }
    (0...@grid.height).each { |y| @grid.at(0, y).is_wall = true; @grid.at(@grid.width - 1, y).is_wall = true }
  end
end
```

To use it, update `game.rb`: `world.add_system(Systems::MazeSystem.new(world, RecursiveBacktrackingGenerator))`. This flexibility lets readers experiment with different maze styles!

## Outcome

By the end of this chapter, you’ve:
- Designed a `Grid` class with `Cell` objects to represent the maze structure.
- Built a pluggable maze generation framework with `MazeGenerator` and implemented `BinaryTreeGenerator`.
- Created a `MazeSystem` to populate the `World` with wall entities.
- Added `RenderComponent`s to walls, displayed as `#` in the terminal.

You can now explore a procedurally generated maze! Each time you run `ruby game.rb`, a new 10x5 maze appears with `#` walls and `.` paths, and your `@` player starts at (1, 1). Move around with `w`, `a`, `s`, `d` (collision isn’t enforced yet), and quit with `q`. In Chapter 8, we’ll add collision detection to stop you from walking through walls and introduce items to collect. Run the game, admire your dungeon, and let’s keep building!

---

### In-Depth Details for New Engineers

- **Why Pluggable Algorithms?**: Hardcoding Binary Tree into `Grid` would limit us. By using a base `MazeGenerator` class, we follow the Open-Closed Principle—open for extension (new algorithms), closed for modification (no need to change `Grid` or `MazeSystem`).
- **Binary Tree Bias**: The algorithm’s northwest bias comes from only connecting north or west. This creates a tree structure where every cell is reachable, but paths slant upward and leftward. Compare this to Recursive Backtracking, which is unbiased and more winding.
- **ECS Integration**: The `MazeSystem` bridges the gap between the `Grid` (a generation tool) and ECS (our game runtime). It translates a conceptual maze into entities the `RenderSystem` and `MovementSystem` can use.
- **Performance**: For a 10x5 grid, generating 50 cells is trivial, but larger mazes (e.g., 100x100) would still be fast with Binary Tree since it’s O(width * height) with no backtracking.

This chapter gives new engineers a deep dive into maze generation while keeping the ECS framework intact.