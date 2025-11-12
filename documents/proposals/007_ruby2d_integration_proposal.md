# Proposal 007: Ruby2D Integration

## Overview

Explore the feasibility of integrating [Ruby2D](https://www.ruby2d.com) as an alternative rendering backend to replace or supplement the current terminal-based renderer. Ruby2D is a cross-platform 2D graphics library built on SDL2 that would enable graphical rendering instead of ASCII terminal output.

## Current State

### Existing Rendering Architecture

The game currently uses a **terminal-based renderer** with the following architecture:

1. **Renderer Abstraction**: `Vanilla::Renderers::Renderer` base class defines the interface
2. **TerminalRenderer**: Current implementation using ASCII art and terminal output
3. **RenderSystem**: Coordinates rendering pipeline (clear → draw → present)
4. **DisplayHandler**: Wraps keyboard input and rendering

**Key Files:**
- `lib/vanilla/renderers/renderer.rb` - Base renderer interface
- `lib/vanilla/renderers/terminal_renderer.rb` - Current terminal implementation
- `lib/vanilla/systems/render_system.rb` - System that uses renderer
- `lib/vanilla/display_handler.rb` - Display abstraction

### Current Rendering Flow

```ruby
# RenderSystem.update
@renderer.clear
update_renderer_info
render_grid
render_messages
@renderer.present
```

The `TerminalRenderer`:
- Uses `system("clear")` to clear screen
- Prints ASCII art directly to stdout
- Draws grid cells as characters (`.`, `@`, `#`, etc.)
- Uses ANSI colors for entities

## Ruby2D Overview

Ruby2D is a simple 2D graphics library for Ruby that:
- Uses SDL2 under the hood (cross-platform)
- Provides simple API: `Square.new`, `Circle.new`, `Text.new`, etc.
- Handles window management, event loop, and rendering
- Supports colors, textures, sprites, and animations
- Works on macOS, Linux, and Windows

**Example:**
```ruby
require 'ruby2d'

set width: 800, height: 600

Square.new(x: 100, y: 100, size: 50, color: 'red')
Text.new('Hello', x: 200, y: 200, size: 20)

show
```

## Feasibility Analysis

### ✅ **POSSIBLE** - Architecture Supports It

The existing codebase has a **renderer abstraction** that makes this feasible:

1. **Renderer Interface**: The `Renderer` base class defines the contract
2. **System Decoupling**: `RenderSystem` doesn't know about terminal specifics
3. **Clear Separation**: Game logic is separate from rendering

### Implementation Approach

#### Option 1: Parallel Renderers (Recommended)

Create a new `Ruby2DRenderer` that implements the same interface, allowing runtime selection:

```ruby
# lib/vanilla/renderers/ruby2d_renderer.rb
module Vanilla
  module Renderers
    class Ruby2DRenderer < Renderer
      def initialize(width: 800, height: 600, cell_size: 20)
        require 'ruby2d'
        @width = width
        @height = height
        @cell_size = cell_size
        @window_initialized = false
        @sprites = {}  # Cache sprites for entities
        @grid_sprites = []  # Grid tiles
      end

      def clear
        # Ruby2D handles clearing automatically
        @grid_sprites.each(&:remove)
        @grid_sprites.clear
      end

      def draw_grid(grid, algorithm, visibility: nil, dev_mode: nil)
        # Convert grid cells to Ruby2D sprites
        grid.rows.times do |row|
          grid.columns.times do |col|
            cell = grid[row, col]
            x = col * @cell_size
            y = row * @cell_size
            
            # Create sprite for cell
            sprite = Square.new(
              x: x,
              y: y,
              size: @cell_size,
              color: cell_color(cell)
            )
            @grid_sprites << sprite
          end
        end
      end

      def draw_character(row, column, character, color = nil)
        x = column * @cell_size
        y = row * @cell_size
        
        # Create or update sprite for entity
        sprite = Text.new(
          character,
          x: x,
          y: y,
          size: @cell_size,
          color: color || 'white'
        )
        @sprites["#{row}_#{column}"] = sprite
      end

      def present
        unless @window_initialized
          set width: @width, height: @height
          show
          @window_initialized = true
        end
        # Ruby2D handles frame presentation automatically
      end

      private

      def cell_color(cell)
        case cell.tile
        when Vanilla::Support::TileType::WALL then 'gray'
        when Vanilla::Support::TileType::FLOOR then 'black'
        else 'darkgray'
        end
      end
    end
  end
end
```

#### Option 2: Hybrid Mode

Support both terminal and Ruby2D simultaneously:
- Terminal for development/debugging
- Ruby2D for production/visual mode
- Toggle via command-line flag or config

#### Option 3: Complete Replacement

Replace terminal renderer entirely with Ruby2D (not recommended - loses terminal compatibility).

## Required Changes

### 1. Add Ruby2D Dependency

**Gemfile:**
```ruby
gem 'ruby2d', '~> 0.11'
```

### 2. Create Ruby2DRenderer

- Implement all `Renderer` interface methods
- Map grid cells to Ruby2D shapes/sprites
- Handle entity rendering as sprites or text
- Manage window lifecycle

### 3. Update RenderSystem

**Option A: Factory Pattern**
```ruby
# lib/vanilla/systems/render_system.rb
def initialize(world, difficulty, seed, renderer_type: :terminal)
  super(world)
  @renderer = case renderer_type
              when :terminal
                Vanilla::Renderers::TerminalRenderer.new
              when :ruby2d
                Vanilla::Renderers::Ruby2DRenderer.new
              end
  # ...
end
```

**Option B: Configuration**
```ruby
# config/renderer.yml or ENV variable
renderer: ruby2d  # or terminal
```

### 4. Handle Ruby2D Event Loop

Ruby2D has its own event loop (`show` blocks), which conflicts with the current game loop.

**Challenge**: Current architecture uses:
```ruby
# Game loop
loop do
  world.update(delta_time)
  break if world.quit?
end
```

Ruby2D expects:
```ruby
on :key_down do |event|
  # Handle input
end

show  # Blocks and runs event loop
```

**Solutions:**

**A. Integrate Ruby2D into Game Loop**
```ruby
# lib/vanilla/game.rb
def start
  # Initialize Ruby2D window but don't call show yet
  @renderer.initialize_window
  
  loop do
    # Process Ruby2D events manually
    @renderer.poll_events
    
    # Run game update
    @world.update(delta_time)
    
    # Render
    @renderer.present
    
    break if @world.quit?
    sleep(0.016)  # ~60 FPS
  end
end
```

**B. Use Ruby2D's Event Loop**
```ruby
# Restructure game to work with Ruby2D's event-driven model
update do
  @world.update(get(:delta_time))
end

on :key_down do |event|
  @input_handler.handle_input(event.key)
end

show
```

### 5. Input Handling Integration

Ruby2D provides keyboard events:
```ruby
on :key_down do |event|
  # event.key is a symbol like :w, :a, :s, :d
  # event.key_code is the raw key code
end
```

**Update KeyboardHandler:**
```ruby
# lib/vanilla/keyboard_handler.rb
class KeyboardHandler
  def initialize(renderer_type: :terminal)
    @renderer_type = renderer_type
    @key_queue = Queue.new if renderer_type == :ruby2d
  end

  def wait_for_input
    case @renderer_type
    when :terminal
      $stdin.raw { $stdin.getc }
    when :ruby2d
      @key_queue.pop  # Block until key available
    end
  end

  def queue_key(key)
    @key_queue << key if @renderer_type == :ruby2d
  end
end
```

**Ruby2D Integration:**
```ruby
# In Ruby2DRenderer
on :key_down do |event|
  @keyboard_handler.queue_key(event.key.to_s)
end
```

### 6. Coordinate System Mapping

**Current**: Grid-based coordinates (row, column)
**Ruby2D**: Pixel-based coordinates (x, y)

**Mapping:**
```ruby
def grid_to_pixel(row, col, cell_size = 20)
  x = col * cell_size
  y = row * cell_size
  [x, y]
end

def pixel_to_grid(x, y, cell_size = 20)
  row = (y / cell_size).floor
  col = (x / cell_size).floor
  [row, col]
end
```

## Challenges and Limitations

### 1. Event Loop Conflict ⚠️

**Problem**: Ruby2D's `show` method blocks and runs its own event loop, conflicting with the current game loop.

**Impact**: HIGH - Requires architectural changes

**Solutions**: See "Handle Ruby2D Event Loop" section above

### 2. Turn-Based vs Real-Time

**Current**: Turn-based (wait for input, then update)
**Ruby2D**: Real-time (continuous updates)

**Solution**: Use Ruby2D's `update` callback but only process game state when input received:
```ruby
update do
  # Only update if there's pending input
  if @world.has_pending_input?
    @world.update(get(:delta_time))
  end
end
```

### 3. Performance Considerations

**Terminal**: Very fast, minimal overhead
**Ruby2D**: More overhead, but still fast for 2D graphics

**Optimization**: 
- Cache sprites instead of recreating
- Use sprite batching
- Limit redraws to changed cells

### 4. Dependency Size

Ruby2D requires SDL2 libraries:
- macOS: `brew install sdl2`
- Linux: `apt-get install libsdl2-dev` (or equivalent)
- Windows: SDL2 DLLs

**Impact**: Adds external dependency, may complicate deployment

### 5. Testing

**Current**: Terminal output is easy to test (capture stdout)
**Ruby2D**: Requires headless mode or mocking

**Solution**: Keep terminal renderer for tests, use Ruby2D only in production

## Benefits

### ✅ Advantages

1. **Visual Appeal**: Modern graphics instead of ASCII
2. **Cross-Platform**: Works on macOS, Linux, Windows
3. **Extensibility**: Easy to add animations, effects, sprites
4. **User Experience**: More accessible to non-terminal users
5. **Future-Proof**: Foundation for graphical enhancements

### ❌ Disadvantages

1. **Complexity**: Adds dependency and complexity
2. **Deployment**: Requires SDL2 installation
3. **Architecture Changes**: Event loop integration required
4. **Testing**: More complex testing setup
5. **Terminal Loss**: May lose terminal-based simplicity

## Implementation Plan

### Phase 1: Proof of Concept (2-3 days)

1. Add Ruby2D gem to Gemfile
2. Create basic `Ruby2DRenderer` class
3. Implement `draw_grid` to render simple grid
4. Test with minimal game state
5. Resolve event loop integration

### Phase 2: Full Integration (3-5 days)

1. Complete renderer interface implementation
2. Integrate with RenderSystem
3. Handle input events
4. Add sprite caching
5. Coordinate system mapping

### Phase 3: Polish (2-3 days)

1. Add configuration for renderer selection
2. Improve sprite rendering
3. Add animations (optional)
4. Performance optimization
5. Documentation

### Phase 4: Testing (2-3 days)

1. Unit tests for renderer
2. Integration tests
3. Cross-platform testing
4. Performance benchmarks

**Total Estimated Time: 9-14 days**

## Alternative: Keep Terminal, Add Optional Graphics

**Recommended Approach**: Keep terminal as default, add Ruby2D as optional enhancement:

```ruby
# Command-line flag
ruby bin/play.rb --renderer=ruby2d
# or
ruby bin/play.rb --renderer=terminal  # default
```

This preserves:
- Terminal simplicity for development
- Terminal compatibility for CI/CD
- Easy testing
- User choice

## Recommendation

### ✅ **FEASIBLE** with Modifications

**Recommendation**: Implement as **optional renderer** alongside terminal renderer.

**Rationale**:
1. Architecture already supports multiple renderers
2. Low risk - doesn't break existing functionality
3. High value - enables graphical mode
4. Maintains backward compatibility

**Key Requirements**:
1. Resolve event loop integration (biggest challenge)
2. Add configuration for renderer selection
3. Keep terminal renderer as default
4. Ensure tests still work with terminal renderer

## Next Steps

1. **Research**: Investigate Ruby2D event loop integration patterns
2. **Prototype**: Create minimal Ruby2DRenderer proof of concept
3. **Test Event Loop**: Resolve blocking `show` issue
4. **Decision**: Proceed with full implementation or abandon

## References

- [Ruby2D Documentation](https://www.ruby2d.com)
- [Ruby2D GitHub](https://github.com/ruby2d/ruby2d)
- [SDL2 Documentation](https://www.libsdl.org)

## Conclusion

Ruby2D integration is **technically feasible** due to the existing renderer abstraction. The main challenge is integrating Ruby2D's event-driven model with the current turn-based game loop. With proper architecture modifications, this could provide a modern graphical interface while maintaining the terminal renderer for development and testing.

