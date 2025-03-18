# Draw System Architecture Improvement Proposal

## Current Implementation Analysis

The existing `draw.rb` module implements a simplified rendering system that directly maps game state to terminal output. Current limitations include:

- Mixing of rendering logic with state update logic (especially in movement)
- Lack of separation between rendering commands and actual display
- Limited flexibility for supporting different output types (e.g., different terminal libraries, graphical interfaces)
- Direct coupling with the game grid and entities
- Backward compatibility layer adds complexity

## Proposed Architecture: Renderer Pattern with MVC Principles

I propose implementing a proper Renderer Pattern that follows Model-View-Controller principles, separating the concerns of rendering, display, and game state.

### Architectural Diagram

```
┌────────────┐     ┌─────────────────────┐     ┌────────────────┐
│            │     │                     │     │                │
│ Game State ├────►│ Rendering Pipeline  ├────►│ Display Output │
│ (Model)    │     │ (Controller)        │     │ (View)         │
│            │     │                     │     │                │
└────────────┘     └─────────────────────┘     └────────────────┘
                           │
                           │
                           ▼
                   ┌────────────────┐    ┌────────────────┐
                   │ Renderer       │    │ Asset Manager  │
                   │ Strategy       ├───►│ (tiles, colors,│
                   │ (ASCII/Unicode)│    │  symbols)      │
                   └────────────────┘    └────────────────┘
```

### Game Flow Diagram

```
┌─────────────┐     ┌─────────────┐     ┌─────────────────┐
│ Game Event  │     │ Game State  │     │ Scene Manager   │
│ (Movement)  ├────►│ Updated     ├────►│                 │
└─────────────┘     └─────────────┘     └────────┬────────┘
                                                 │
                                                 │ Triggers
                                                 ▼
┌────────────────┐     ┌──────────────┐     ┌─────────────┐
│ Terminal       │     │ Renderer     │     │ RenderQueue │
│ Display        │◄────┤ Strategy     │◄────┤ (grid, UI,  │
│                │     │              │     │  entities)   │
└────────────────┘     └──────────────┘     └─────────────┘
```

## Implementation Details

### 1. Rendering Pipeline

```ruby
# Core rendering pipeline
class RenderingPipeline
  def initialize(display_adapter)
    @display_adapter = display_adapter
    @render_queue = []
  end

  def queue_render_command(command)
    @render_queue << command
  end

  def render
    # Clear the display
    @display_adapter.clear

    # Process render queue in order (back-to-front)
    @render_queue.each do |command|
      command.execute(@display_adapter)
    end

    # Display the completed frame
    @display_adapter.display

    # Clear queue for next frame
    @render_queue.clear
  end
end
```

### 2. Render Commands

```ruby
# Abstract render command
class RenderCommand
  def execute(display)
    raise NotImplementedError
  end
end

# Grid render command
class GridRenderCommand < RenderCommand
  def initialize(grid)
    @grid = grid
  end

  def execute(display)
    # Render the base grid
    display.render_grid(@grid)
  end
end

# Entity render command
class EntityRenderCommand < RenderCommand
  def initialize(entity)
    @entity = entity
  end

  def execute(display)
    if @entity.has_component?(:position) && @entity.has_component?(:tile)
      position = @entity.get_component(:position)
      tile = @entity.get_component(:tile)
      display.render_tile(position.row, position.column, tile.tile)
    end
  end
end

# UI element render command
class UIRenderCommand < RenderCommand
  def initialize(ui_element)
    @ui_element = ui_element
  end

  def execute(display)
    display.render_ui(@ui_element)
  end
end
```

### 3. Display Adapters

```ruby
# Abstract display adapter
class DisplayAdapter
  def clear
    raise NotImplementedError
  end

  def render_grid(grid)
    raise NotImplementedError
  end

  def render_tile(row, column, tile)
    raise NotImplementedError
  end

  def render_ui(ui_element)
    raise NotImplementedError
  end

  def display
    raise NotImplementedError
  end
end

# Terminal display adapter
class TerminalDisplayAdapter < DisplayAdapter
  def clear
    system("clear")
  end

  def render_grid(grid)
    @buffer = Array.new(grid.rows) { Array.new(grid.columns, ' ') }

    grid.rows.times do |row|
      grid.columns.times do |col|
        cell = grid[row, col]
        @buffer[row][col] = cell.tile || ' '
      end
    end
  end

  def render_tile(row, column, tile)
    @buffer[row][column] = tile if valid_position?(row, column)
  end

  def render_ui(ui_element)
    # Render UI elements like stats, inventory, etc.
    # Add to separate buffer or to main buffer depending on implementation
  end

  def display
    # Header
    puts "Seed: #{$seed} | Rows: #{@buffer.size} | Columns: #{@buffer.first&.size || 0}"
    puts "-" * 35
    puts "\n"

    # Grid
    @buffer.each_with_index do |row, idx|
      puts row.join('')
    end
  end

  private

  def valid_position?(row, column)
    row >= 0 && row < @buffer.size && column >= 0 && column < @buffer.first.size
  end
end

# Curses display adapter (example of alternative display)
class CursesDisplayAdapter < DisplayAdapter
  # Similar implementation but using the Curses library
end
```

### 4. Scene Manager

```ruby
class SceneManager
  def initialize(renderer)
    @renderer = renderer
    @entities = []
    @grid = nil
    @ui_elements = []
  end

  def set_grid(grid)
    @grid = grid
  end

  def add_entity(entity)
    @entities << entity
  end

  def remove_entity(entity)
    @entities.delete(entity)
  end

  def add_ui_element(element)
    @ui_elements << element
  end

  def render
    # Queue grid first (background)
    @renderer.queue_render_command(GridRenderCommand.new(@grid)) if @grid

    # Queue all entities
    @entities.each do |entity|
      @renderer.queue_render_command(EntityRenderCommand.new(entity))
    end

    # Queue UI elements last (foreground)
    @ui_elements.each do |element|
      @renderer.queue_render_command(UIRenderCommand.new(element))
    end

    # Execute the render
    @renderer.render
  end
end
```

### 5. Integration with Movement System

```ruby
# Decouple movement from rendering
class MovementSystem
  def initialize(grid)
    @grid = grid
    @logger = Vanilla::Logger.instance
  end

  def move(entity, direction)
    # Movement logic (unchanged)

    # Instead of rendering directly, emit an event
    EntityMovedEvent.emit(entity: entity, grid: @grid)
  end
end

# Event system
class EntityMovedEvent
  def self.emit(entity:, grid:)
    EventBus.publish(:entity_moved, entity: entity, grid: grid)
  end
end

# Main game updates scene and triggers render
EventBus.subscribe(:entity_moved) do |event|
  # Update scene with new entity position
  scene_manager.render  # Trigger rendering
end
```

## Benefits

1. **Separation of Concerns** - Clean separation between game state, rendering logic, and display
2. **Flexibility** - Easy to add new display adapters (e.g., Curses, GUI)
3. **Testability** - Each component can be tested in isolation
4. **Maintainability** - Clearer architecture and responsibilities
5. **Performance** - Better control over when rendering occurs
6. **Extensibility** - Easy to add new visual elements or effects

## Migration Plan

1. **Phase 1: Core Rendering Architecture**
   - Implement display adapters and rendering pipeline
   - Keep existing draw.rb as fallback

2. **Phase 2: Dual Implementation**
   - Create wrapper around new rendering system
   - Add feature flag to choose between implementations

3. **Phase 3: Event-Based Integration**
   - Migrate game systems to use events rather than direct rendering
   - Update game loop to use scene manager

4. **Phase 4: Complete Transition**
   - Move to exclusively using new rendering system
   - Remove old draw.rb implementation

This phased approach ensures the game remains playable throughout the migration while moving towards a more robust rendering architecture.