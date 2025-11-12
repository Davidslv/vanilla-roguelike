# Proposal 008: Game Controller Support

## Overview

Explore the feasibility of adding game controller (gamepad/joystick) support to the roguelike game. This would allow players to use controllers like Xbox, PlayStation, or generic USB gamepads instead of (or in addition to) keyboard input.

## Current State

### Existing Input Architecture

The game currently uses **keyboard-only input** with the following architecture:

1. **KeyboardHandler**: Reads raw keyboard input using Ruby's `io/console`
2. **InputHandler**: Translates keys to commands
3. **InputSystem**: Processes input in game loop
4. **Commands**: Encapsulate actions (MoveCommand, AttackCommand, etc.)

**Key Files:**
- `lib/vanilla/keyboard_handler.rb` - Low-level keyboard input
- `lib/vanilla/input_handler.rb` - Key-to-command translation
- `lib/vanilla/systems/input_system.rb` - Input processing system
- `lib/vanilla/display_handler.rb` - Wraps input/output

### Current Input Flow

```ruby
# KeyboardHandler
def wait_for_input
  $stdin.raw { $stdin.getc }  # Blocks until keypress
end

# InputHandler
def handle_input(key)
  case key
  when 'k', :up then MoveCommand.new(entity, :north)
  when 'j', :down then MoveCommand.new(entity, :south)
  # ...
  end
end

# InputSystem
def update(_unused)
  key = @world.display.keyboard_handler.wait_for_input
  @input_handler.handle_input(key)
end
```

## Game Controller Support Options

### Option 1: Ruby2D Gamepad Support

If Ruby2D is integrated (see Proposal 007), it provides gamepad support:

```ruby
on :controller_button_down do |event|
  # event.button is :a, :b, :x, :y, :dpad_up, etc.
end

on :controller_axis do |event|
  # event.axis is :left_x, :left_y, :right_x, :right_y
  # event.value is -1.0 to 1.0
end
```

**Pros:**
- Built-in if using Ruby2D
- Cross-platform (SDL2 handles it)
- Simple API

**Cons:**
- Only available if Ruby2D is integrated
- Tied to Ruby2D dependency

### Option 2: SDL2 Ruby Bindings

Use SDL2 directly via Ruby bindings:

**Gems:**
- `sdl2` - Ruby bindings for SDL2
- `sdl2_ffi` - FFI-based SDL2 bindings

**Example:**
```ruby
require 'sdl2'

SDL2.init(SDL2::INIT_GAMECONTROLLER)

# Open first available controller
controller = SDL2::GameController.open(0)

loop do
  event = SDL2::Event.poll
  case event
  when SDL2::Event::ControllerButtonDown
    button = event.button
    handle_button(button)
  when SDL2::Event::ControllerAxisMotion
    axis = event.axis
    value = event.value
    handle_axis(axis, value)
  end
end
```

**Pros:**
- Direct SDL2 access
- Full control over gamepad handling
- Works independently of renderer

**Cons:**
- Requires SDL2 installation
- More complex API
- Lower-level than needed

### Option 3: Ruby Input Libraries

**Gems:**
- `ginput` - Game input library (may be outdated)
- `gosu` - Game development library with controller support
- `ray` - Ruby bindings for raylib (includes gamepad support)

**Example with Ray:**
```ruby
require 'ray'

Ray.init_window(800, 600, "Game")

until Ray.window_should_close?
  # Check gamepad
  if Ray.gamepad_available?(0)
    # D-pad
    if Ray.gamepad_button_pressed?(0, :dpad_up)
      move_north
    end
    
    # Analog stick
    left_x = Ray.gamepad_axis_movement(0, :left_x)
    left_y = Ray.gamepad_axis_movement(0, :left_y)
    if left_x.abs > 0.3 || left_y.abs > 0.3
      move_direction(left_x, left_y)
    end
  end
  
  Ray.end_drawing
end
```

**Pros:**
- Higher-level APIs
- May include other game features

**Cons:**
- Additional dependencies
- May be overkill for just controller support

### Option 4: Platform-Specific Solutions

**macOS**: IOKit framework
**Linux**: `/dev/input/js*` devices
**Windows**: DirectInput/XInput

**Pros:**
- No external dependencies
- Full control

**Cons:**
- Platform-specific code
- Complex implementation
- Maintenance burden

## Feasibility Analysis

### ✅ **POSSIBLE** - Architecture Supports It

The existing input architecture is **well-abstracted** and can be extended:

1. **InputHandler Abstraction**: Can be extended to handle controller input
2. **Command Pattern**: Commands are input-agnostic
3. **System Decoupling**: InputSystem doesn't care about input source

### Recommended Approach: ControllerHandler

Create a parallel input handler similar to KeyboardHandler:

```ruby
# lib/vanilla/controller_handler.rb
module Vanilla
  class ControllerHandler
    def initialize
      @controller = nil
      @button_queue = Queue.new
      @axis_state = {}
      initialize_controller
    end

    def initialize_controller
      # Try to open first available controller
      # Implementation depends on chosen library
    end

    def wait_for_input
      # Poll controller state
      # Return button press or axis movement
      @button_queue.pop
    end

    def poll_controller
      # Check for button presses
      # Check for axis movements
      # Queue events
    end
    end
end
```

## Implementation Approaches

### Approach 1: SDL2 Direct (Recommended if not using Ruby2D)

**Why**: SDL2 is the standard for cross-platform gamepad support, widely used, well-documented.

**Implementation:**

```ruby
# Gemfile
gem 'sdl2', '~> 0.3'  # or sdl2_ffi

# lib/vanilla/controller_handler.rb
require 'sdl2'

module Vanilla
  class ControllerHandler
    def initialize
      SDL2.init(SDL2::INIT_GAMECONTROLLER) unless SDL2.initialized?
      @controller = open_first_controller
      @button_mapping = default_button_mapping
    end

    def wait_for_input
      poll_events
      @input_queue.pop if @input_queue.any?
    end

    private

    def open_first_controller
      (0...SDL2::GameController.num_joysticks).each do |i|
        if SDL2::GameController.is_game_controller?(i)
          return SDL2::GameController.open(i)
        end
      end
      nil
    end

    def poll_events
      while event = SDL2::Event.poll
        case event
        when SDL2::Event::ControllerButtonDown
          handle_button_down(event.button)
        when SDL2::Event::ControllerAxisMotion
          handle_axis_motion(event.axis, event.value)
        end
      end
    end

    def handle_button_down(button)
      # Map controller button to game action
      action = @button_mapping[button] || :unknown
      @input_queue << action if action != :unknown
    end

    def handle_axis_motion(axis, value)
      # Dead zone filtering
      return if value.abs < 8000  # ~25% of max
      
      case axis
      when :left_x
        @input_queue << (value > 0 ? :east : :west) if value.abs > 16000
      when :left_y
        @input_queue << (value > 0 ? :south : :north) if value.abs > 16000
      end
    end

    def default_button_mapping
      {
        :a => :confirm,      # A button / Cross
        :b => :cancel,       # B button / Circle
        :x => :use_item,     # X button / Square
        :y => :inventory,     # Y button / Triangle
        :dpad_up => :north,
        :dpad_down => :south,
        :dpad_left => :west,
        :dpad_right => :east,
        :start => :menu,
        :back => :inventory
      }
    end
  end
end
```

### Approach 2: Ruby2D Integration (If using Ruby2D)

If Ruby2D is integrated, use its built-in controller support:

```ruby
# lib/vanilla/controller_handler.rb
module Vanilla
  class ControllerHandler
    def initialize
      @button_queue = Queue.new
      setup_ruby2d_events
    end

    def setup_ruby2d_events
      on :controller_button_down do |event|
        action = map_button_to_action(event.button)
        @button_queue << action
      end

      on :controller_axis do |event|
        action = map_axis_to_action(event.axis, event.value)
        @button_queue << action if action
      end
    end

    def wait_for_input
      @button_queue.pop
    end

    # ... mapping methods
  end
end
```

### Approach 3: Hybrid Input System

Support both keyboard and controller simultaneously:

```ruby
# lib/vanilla/display_handler.rb
class DisplayHandler
  attr_reader :keyboard_handler, :controller_handler

  def initialize
    @keyboard_handler = KeyboardHandler.new
    @controller_handler = ControllerHandler.new
    @input_source = :keyboard  # or :controller, :auto
  end

  def wait_for_input
    case @input_source
    when :keyboard
      @keyboard_handler.wait_for_input
    when :controller
      @controller_handler.wait_for_input
    when :auto
      # Check both, return first available
      select([@keyboard_handler, @controller_handler], [], [], 0.1)
    end
  end
end
```

## Button Mapping Strategy

### Default Mapping

**Movement:**
- D-Pad: Cardinal directions (north, south, east, west)
- Left Analog Stick: 8-directional movement (with dead zone)

**Actions:**
- A / Cross: Confirm / Use / Interact
- B / Circle: Cancel / Back
- X / Square: Attack / Use item
- Y / Triangle: Inventory
- Start: Menu / Pause
- Back / Select: Inventory / Map

**Advanced:**
- Right Analog Stick: Camera / Look (if implemented)
- Triggers: Special actions (if needed)
- Shoulder Buttons: Quick actions

### Configurable Mapping

Allow users to customize button mappings:

```yaml
# config/controller.yml
controller:
  mapping:
    a: confirm
    b: cancel
    x: attack
    y: inventory
    dpad_up: north
    dpad_down: south
    dpad_left: west
    dpad_right: east
    left_stick: movement
    start: menu
    back: inventory
  dead_zone: 0.25  # 25% dead zone for analog sticks
```

## Challenges and Limitations

### 1. Turn-Based vs Continuous Input ⚠️

**Problem**: Controllers provide continuous input (analog sticks), but game is turn-based.

**Solution**: 
- Use dead zones to filter small movements
- Only trigger movement on significant stick deflection
- D-Pad is discrete and works better for turn-based

### 2. Menu Navigation

**Problem**: Current menu system uses letter keys (`[1]`, `[i]`, `[m]`). Controllers need different navigation.

**Solution**:
- Map controller buttons to menu actions
- Use D-Pad for menu navigation
- Highlight selected option
- Use A to confirm, B to cancel

### 3. Controller Detection

**Problem**: Not all users have controllers connected.

**Solution**:
- Graceful fallback to keyboard
- Auto-detect controller on startup
- Allow manual selection of input method
- Show controller disconnected message

### 4. Platform Differences

**Problem**: Controller button names differ (Xbox vs PlayStation).

**Solution**:
- Use generic button names internally
- Map to platform-specific names for display
- Allow user to see/configure their controller layout

### 5. Multiple Controllers

**Problem**: Some systems support multiple controllers.

**Solution**: 
- Support first connected controller (for single-player)
- Future: Multiplayer support with multiple controllers

## Required Changes

### 1. Add Controller Library

**Gemfile:**
```ruby
# Option A: SDL2 (if not using Ruby2D)
gem 'sdl2', '~> 0.3'

# Option B: Ruby2D (if integrated)
gem 'ruby2d', '~> 0.11'
```

### 2. Create ControllerHandler

- Implement controller initialization
- Handle button presses
- Handle analog stick movements
- Map to game actions

### 3. Update DisplayHandler

- Add controller_handler
- Support input source selection
- Handle both keyboard and controller

### 4. Update InputHandler

- Extend to handle controller actions
- Map controller buttons to commands
- Handle analog stick to direction conversion

### 5. Menu System Updates

- Add controller navigation
- Visual feedback for selected option
- Controller button hints in menus

### 6. Configuration

- Button mapping configuration
- Dead zone settings
- Input source selection

## Benefits

### ✅ Advantages

1. **Accessibility**: More comfortable for some users
2. **Ergonomics**: Better for extended play sessions
3. **Modern Experience**: Expected feature in modern games
4. **Flexibility**: Users can choose input method
5. **Future-Proof**: Foundation for potential multiplayer

### ❌ Disadvantages

1. **Complexity**: Additional input system to maintain
2. **Dependencies**: Requires SDL2 or similar
3. **Testing**: More input methods to test
4. **Menu Changes**: Requires menu system updates
5. **Platform Support**: May need platform-specific code

## Implementation Plan

### Phase 1: Proof of Concept (2-3 days)

1. Choose controller library (SDL2 recommended)
2. Create basic ControllerHandler
3. Implement button detection
4. Map buttons to basic actions (movement)
5. Test with one controller

### Phase 2: Full Integration (3-4 days)

1. Complete button mapping
2. Integrate with InputHandler
3. Update DisplayHandler for dual input
4. Add analog stick support with dead zones
5. Handle controller connect/disconnect

### Phase 3: Menu Integration (2-3 days)

1. Add controller navigation to menus
2. Visual feedback for selection
3. Controller button hints
4. Test all menu interactions

### Phase 4: Polish (2-3 days)

1. Configuration system for button mapping
2. Dead zone configuration
3. Controller detection and messaging
4. Documentation
5. Cross-platform testing

**Total Estimated Time: 9-13 days**

## Testing Strategy

### Unit Tests

- ControllerHandler button mapping
- Analog stick to direction conversion
- Dead zone filtering
- Button queue management

### Integration Tests

- Controller input → command creation
- Menu navigation with controller
- Controller + keyboard fallback
- Controller disconnect handling

### Manual Testing

- Test with multiple controller types
- Test on different platforms
- Test menu navigation
- Test all game actions

## Recommendation

### ✅ **FEASIBLE** with Moderate Effort

**Recommendation**: Implement controller support as **optional feature** alongside keyboard.

**Rationale**:
1. Architecture supports multiple input sources
2. SDL2 provides robust cross-platform support
3. Enhances user experience
4. Doesn't break existing keyboard functionality

**Key Requirements**:
1. Choose appropriate library (SDL2 if not using Ruby2D)
2. Handle turn-based nature (dead zones, discrete input)
3. Update menu system for controller navigation
4. Graceful fallback to keyboard

## Alternative: Simplified Approach

**Minimal Implementation**: 
- D-Pad only (no analog sticks)
- Basic button mapping
- No menu navigation (keyboard required for menus)

**Pros**: Faster implementation, simpler
**Cons**: Less feature-complete

## Next Steps

1. **Research**: Test SDL2 Ruby bindings availability and stability
2. **Prototype**: Create minimal ControllerHandler proof of concept
3. **Test**: Verify controller detection and button reading
4. **Decision**: Proceed with full implementation or simplified version

## References

- [SDL2 Game Controller API](https://wiki.libsdl.org/SDL_GameController)
- [Ruby SDL2 Gem](https://github.com/ohai/ruby-sdl2)
- [SDL2 Controller Mapping](https://github.com/gabomdq/SDL_GameControllerDB)

## Conclusion

Game controller support is **technically feasible** and would enhance the user experience. The main challenges are:
1. Integrating controller input with turn-based gameplay
2. Updating menu system for controller navigation
3. Handling platform differences gracefully

With proper abstraction and SDL2 (or Ruby2D), this feature can be implemented while maintaining keyboard support as the primary input method.

