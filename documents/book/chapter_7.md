# Chapter 7: Generating Mazes

Our roguelike has a player moving on a grid with responsive input, but it's still an open field. To make it a true dungeon crawler, we need a maze—walls to navigate, paths to explore, and a sense of mystery. In this chapter, we'll build a robust maze generation system by designing a `Grid` class with `Cell` objects, creating a flexible framework for maze algorithms (starting with the Binary Tree algorithm), and integrating it into our ECS `World` via a `MazeSystem`. We'll also implement a `PathGuarantor` to ensure our mazes are always completable, and make sure new mazes are generated for each level. By the end, you'll be able to explore a procedurally generated maze, with the flexibility to swap in different maze algorithms later. Let's dive into the details and craft a dungeon step-by-step!

## Designing a Grid Class with Cell Objects

Before we generate a maze, we need a structure to represent it. The `Grid` class will act as our canvas—a 2D array of `Cell` objects where each cell can be a wall or a path. This separation keeps maze generation logic independent of our ECS `World`, making it reusable and easier to test.

### The Cell Class

A `Cell` is the smallest unit of our maze. For now, it only needs to track whether it's a wall or a path, but we'll design it to be extensible for future features (e.g., items, traps).

Here's the initial `lib/grid.rb`:

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
  - `to_s` is a helper method for debugging, returning `#` for walls and `.` for paths (matching our `RenderSystem`'s output).
- **Grid**:
  - `width` and `height` define the maze's dimensions (e.g., 10x5).
  - `@cells` is a 2D array where `@cells[y][x]` gives the cell at position (x, y). Ruby arrays are indexed from 0, so `@cells[0][0]` is the top-left corner.
  - `at(x, y)` prevents crashes by checking bounds. For example, `at(-1, 0)` returns `nil` instead of raising an error.

This structure is simple but powerful—it's a blank slate ready for maze generation.

## Implementing a Flexible Maze Algorithm Framework

Maze generation is where the magic happens. We want our game to create a new maze each time it starts, adding replayability. There are many algorithms—Binary Tree, Recursive Backtracking, Prim's, etc.—each with unique characteristics. To keep our code flexible, we'll define a pluggable system where any algorithm can be used, starting with Binary Tree as our first example.

### Why Binary Tree?

The Binary Tree algorithm is beginner-friendly because:
- It's fast and simple: For each cell, it decides to connect to either the north or west neighbor (or neither at edges).
- It guarantees a perfect maze (no loops, one solution from any start to end).
- It's biased (favoring northwest passages), which gives it a distinct "feel" we can recognize.

We'll implement it as a separate class, then make it pluggable into `Grid`.

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

This is an abstract base class—any maze algorithm will inherit from it and implement `generate`. The `@grid` instance variable gives access to the `Grid` we're shaping.

### Implementing BinaryTreeGenerator

Create `lib/binary_tree_generator.rb`:

```ruby
# lib/binary_tree_generator.rb
require_relative "maze_generator"

class BinaryTreeGenerator < MazeGenerator
  def generate
    # Step 1: Fill everything with walls initially
    @grid.cells.each { |row| row.each { |cell| cell.is_wall = true } }

    # Step 2: Create outer walls
    (0...@grid.width).each do |x|
      @grid.at(x, 0).is_wall = true
      @grid.at(x, @grid.height - 1).is_wall = true
    end
    (0...@grid.height).each do |y|
      @grid.at(0, y).is_wall = true
      @grid.at(@grid.width - 1, y).is_wall = true
    end

    # Step 3: Create a proper maze using binary tree algorithm
    (1...@grid.height - 1).step(2) do |y|
      (1...@grid.width - 1).step(2) do |x|
        # Carve the current cell
        @grid.at(x, y).is_wall = false

        # Randomly choose to carve north or east
        if y > 1 && (x == @grid.width - 2 || rand < 0.5)
          # Carve north
          @grid.at(x, y - 1).is_wall = false
        elsif x < @grid.width - 2
          # Carve east
          @grid.at(x + 1, y).is_wall = false
        end
      end
    end

    # Step 4: Ensure start and end points are clear
    @grid.at(1, 1).is_wall = false # Start point
    @grid.at(@grid.width - 2, @grid.height - 2).is_wall = false # End point
  end
end
```

#### How Binary Tree Works

1. **Initialize**: Start with all cells as walls
2. **Create Outer Walls**: Ensure the border of the maze is solid
3. **Binary Tree Algorithm**:
   - Visit each cell in a grid, stepping by 2 to create corridors
   - Carve the current cell as a path
   - Randomly choose to carve north or east
   - This creates a maze with a bias toward the northeast
4. **Set Start and End Points**: Ensure the player's starting position and the stairs are clear

This creates a maze with a northeast bias. It's not the most complex maze, but it's quick and simple to implement.

## Ensuring Mazes are Always Completable with PathGuarantor

One major limitation of many maze algorithms (including Binary Tree) is that they don't always guarantee a path from the start to the end, which is essential for our roguelike. To solve this, we'll implement a `PathGuarantor` class that checks if a path exists and creates one if necessary.

Create `lib/path_guarantor.rb`:

```ruby
# lib/path_guarantor.rb
class PathGuarantor
  def initialize(grid)
    @grid = grid
    @visited = Array.new(@grid.height) { Array.new(@grid.width, false) }
    @path_found = false
  end

  def ensure_path(start_x, start_y, end_x, end_y)
    # Check if a path exists
    @path_found = false
    @visited = Array.new(@grid.height) { Array.new(@grid.width, false) }

    if find_path(start_x, start_y, end_x, end_y)
      return true # Path already exists
    end

    # No path found, create one
    create_path(start_x, start_y, end_x, end_y)
    true
  end

  private

  def find_path(x, y, target_x, target_y)
    # Check if out of bounds or wall or already visited
    return false if x < 0 || x >= @grid.width || y < 0 || y >= @grid.height
    return false if @grid.at(x, y).is_wall
    return false if @visited[y][x]

    # Mark as visited
    @visited[y][x] = true

    # Check if reached target
    if x == target_x && y == target_y
      @path_found = true
      return true
    end

    # Try all four directions
    return true if find_path(x + 1, y, target_x, target_y)
    return true if find_path(x - 1, y, target_x, target_y)
    return true if find_path(x, y + 1, target_x, target_y)
    return true if find_path(x, y - 1, target_x, target_y)

    false
  end

  def create_path(start_x, start_y, end_x, end_y)
    # Create a direct path by carving through walls
    current_x = start_x
    current_y = start_y

    while current_x != end_x || current_y != end_y
      # Move horizontally first
      if current_x < end_x
        current_x += 1
      elsif current_x > end_x
        current_x -= 1
      # Then move vertically
      elsif current_y < end_y
        current_y += 1
      elsif current_y > end_y
        current_y -= 1
      end

      # Carve path
      @grid.at(current_x, current_y).is_wall = false
    end
  end
end
```

#### How PathGuarantor Works

1. **Check for Existing Path**: Uses a depth-first search algorithm to see if there's already a path from start to finish
2. **Create Path if Needed**: If no path exists, carves a direct path from start to end, ensuring the maze is solvable
3. **Simple Path Creation**: Moves horizontally first, then vertically, to create a straightforward path

This guarantor is crucial for gameplay—it ensures that players can always reach the exit, regardless of which maze algorithm we use.

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
1. Generate a new maze for each level.
2. Use the `PathGuarantor` to ensure the maze is completable.
3. Create entities for each wall cell with `Position` and `Render` components.

Create `lib/systems/maze_system.rb`:

```ruby
# lib/systems/maze_system.rb
require_relative "../grid"
require_relative "../binary_tree_generator"
require_relative "../path_guarantor"
require_relative "../logger"

module Systems
  class MazeSystem
    def initialize(world, generator_class = BinaryTreeGenerator)
      @world = world
      @generator_class = generator_class
      @generated = false
      @level = 1
    end

    def process(_entities)
      # Only regenerate maze if it's a new level or hasn't been generated yet
      if @level == @world.current_level && @generated
        return
      end

      Logger.debug("Generating maze for level #{@world.current_level}")
      @level = @world.current_level
      @generated = false

      # Step 1: Generate the maze
      grid = Grid.new(@world.width, @world.height)
      grid.generate_maze(@generator_class)

      # Step 2: Ensure there's a path from start to end
      Logger.debug("Ensuring path exists from start to end")
      guarantor = PathGuarantor.new(grid)
      guarantor.ensure_path(1, 1, @world.width - 2, @world.height - 2)

      # Step 3: Create wall entities
      grid.cells.each_with_index do |row, y|
        row.each_with_index do |cell, x|
          next unless cell.is_wall

          wall = @world.create_entity
          wall.add_component(Components::Position.new(x, y))
          wall.add_component(Components::Render.new("#"))
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
  - `@level` tracks the current level to detect when a new level is started.
- **Process**:
  - Checks if a new level has been started or if the maze hasn't been generated yet.
  - Creates a `Grid` matching the `World`'s size.
  - Calls `generate_maze` with the chosen generator.
  - Uses `PathGuarantor` to ensure there's a path from start to end.
  - Loops through each cell; if it's a wall, creates an entity with:
    - `PositionComponent`: Places it at (x, y).
    - `RenderComponent`: Displays it as `#`.

This implementation ensures that:
1. A new maze is generated for each level
2. Each maze is guaranteed to be completable
3. The maze generation is independent of the rest of the game logic

## Adding RenderComponent to Walls

Walls use the existing `RenderComponent` with `#` as their character. This matches our grid's `to_s` convention (`#` for walls, `.` for paths). The `RenderSystem` already handles any entity with `Position` and `Render` components, so no changes are needed there. Paths remain empty (`.`) in the background grid, as we only create entities for walls.

## Updating the World Class for Level Progression

To support level progression and maze regeneration, we need to update the `World` class to track the current level and make it accessible to systems:

```ruby
# lib/world.rb (update to expose current_level)
class World
  attr_reader :entities, :systems, :event_manager, :width, :height, :current_level

  def initialize(width: 10, height: 5)
    @entities = {}
    @systems = []
    @next_id = 0
    @width = width
    @height = height
    @running = true
    @event_manager = EventManager.new
    @current_level = 1
    @keyboard = KeyboardHandler.new
  end

  # ... rest of the class ...
end
```

With this change, the `MazeSystem` can detect when the level changes and generate a new maze accordingly.

## Integrating into the Game

Now let's update our main game file to include the maze system:

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
require_relative "lib/keyboard_handler"
require_relative "lib/event"
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
```

In this setup, we add the `MazeSystem` first so it runs before other systems, ensuring the maze is generated before the player moves or the screen is rendered.

## Testing Our Maze Generation

Our maze generation code needs thorough testing to ensure it works as expected. Here's a test for the `PathGuarantor`:

```ruby
# spec/path_guarantor_spec.rb
require_relative '../lib/grid'
require_relative '../lib/path_guarantor'

describe PathGuarantor do
  let(:grid) { Grid.new(10, 10) }
  let(:guarantor) { PathGuarantor.new(grid) }

  before do
    # Make all cells walls
    grid.cells.each { |row| row.each { |cell| cell.is_wall = true } }
  end

  describe "#ensure_path" do
    it "creates a path when none exists" do
      # Before: No path exists
      start_x, start_y = 1, 1
      end_x, end_y = 8, 8

      # Make start and end points not walls
      grid.at(start_x, start_y).is_wall = false
      grid.at(end_x, end_y).is_wall = false

      # Before guarantor, there's no path (all other cells are walls)
      # Apply path guarantor
      guarantor.ensure_path(start_x, start_y, end_x, end_y)

      # After: There should be a path
      # Check if we can reach end from start
      path_exists = path_exists?(grid, start_x, start_y, end_x, end_y)
      expect(path_exists).to be true
    end
  end

  private

  # Helper to check if a path exists
  def path_exists?(grid, start_x, start_y, end_x, end_y)
    visited = Array.new(grid.height) { Array.new(grid.width, false) }
    queue = [[start_x, start_y]]
    visited[start_y][start_x] = true

    while !queue.empty?
      x, y = queue.shift

      return true if x == end_x && y == end_y

      # Try all four directions
      [[x+1, y], [x-1, y], [x, y+1], [x, y-1]].each do |nx, ny|
        next if nx < 0 || nx >= grid.width || ny < 0 || ny >= grid.height
        next if grid.at(nx, ny).is_wall
        next if visited[ny][nx]

        visited[ny][nx] = true
        queue << [nx, ny]
      end
    end

    false
  end
end
```

This test ensures that our `PathGuarantor` correctly creates a path when none exists, which is crucial for game playability.

## Outcome

In this chapter, we've:

- Built a `Grid` class to represent our maze structure
- Created a flexible framework for maze generation algorithms
- Implemented the Binary Tree algorithm as our first generator
- Added a `PathGuarantor` to ensure mazes are always completable
- Created a `MazeSystem` that integrates with our ECS architecture
- Updated the `World` class to support level progression
- Ensured new mazes are generated for each level

With these components in place, our roguelike now has procedurally generated mazes that are guaranteed to be solvable. Players can explore different layouts each time they start the game or advance to a new level, adding significant replay value.

In the next chapter, we'll add items and treasures to our dungeon, giving players more to discover as they navigate the maze!