# Prerequisites for State Recording & Playback

This document outlines the foundational systems needed to implement a robust state recording and playback system in the Vanilla game engine.

## 1. Complete Serialization Layer

A serialization layer allows converting all game state to a format that can be stored and later reconstructed.

### Requirements:
- **Object Serialization**: All game objects must implement serialization methods
  ```ruby
  class GameObject
    def to_hash
      # Return a hash representing this object's state
    end

    def self.from_hash(hash)
      # Reconstruct an object from a hash
    end
  end
  ```

- **Version Compatibility**: Ensure serialized data remains compatible across game versions
  ```ruby
  def to_hash
    {
      version: "1.0",
      data: {
        # Version-specific serialization
      }
    }
  end
  ```

- **Circular Reference Handling**: Resolve circular references between objects
  ```ruby
  # Use reference IDs instead of direct object references
  def to_hash
    {
      id: object_id,
      references: [ref1.object_id, ref2.object_id]
    }
  end
  ```

### Implementation Targets:
- `lib/vanilla/map_utils/grid.rb` - Grid serialization
- `lib/vanilla/map_utils/cell.rb` - Cell serialization
- `lib/vanilla/characters/player.rb` - Player state serialization
- `lib/vanilla/level.rb` - Overall level serialization
- `lib/vanilla.rb` - Game state serialization controller

## 2. Event System

An event system decouples actions from their effects, making it easier to record and replay sequences of events.

### Requirements:
- **Event Bus**: Centralized event dispatcher
  ```ruby
  module Vanilla
    class EventBus
      include Singleton

      def emit(event_type, payload)
        # Notify all subscribers about the event
      end

      def subscribe(event_type, &handler)
        # Register a handler for events of the given type
      end
    end
  end
  ```

- **Event Types**: Well-defined event types for all game actions
  ```ruby
  module Vanilla
    module Events
      PLAYER_MOVE = "player.move"
      PLAYER_COLLECT = "player.collect"
      LEVEL_CHANGE = "level.change"
      # etc.
    end
  end
  ```

- **Event History**: Recording of all events with timestamps
  ```ruby
  class EventHistory
    def log(event_type, payload, timestamp)
      # Store event for later replay
    end

    def replay(from_time, to_time)
      # Replay events within the given time range
    end
  end
  ```

### Implementation Targets:
- `lib/vanilla/events.rb` - Event types and bus
- `lib/vanilla/events/history.rb` - Event recording
- `lib/vanilla/movement.rb` - Convert direct actions to events
- `lib/vanilla/command.rb` - Emit events for commands

## 3. Input Abstraction

Input abstraction separates detecting input from processing it, allowing for recorded input to be replayed.

### Requirements:
- **Input Queue**: Buffer for inputs to be processed
  ```ruby
  class InputQueue
    def push(input_event)
      # Add input to queue
    end

    def poll
      # Get next input from queue
    end
  end
  ```

- **Input Events**: Structured representation of inputs
  ```ruby
  class InputEvent
    attr_reader :key, :timestamp, :metadata

    def initialize(key, timestamp, metadata = {})
      @key = key
      @timestamp = timestamp
      @metadata = metadata
    end
  end
  ```

- **Input Providers**: Abstractions for different input sources
  ```ruby
  module InputProviders
    class Keyboard
      def next_input
        # Return keyboard input as InputEvent
      end
    end

    class Recording
      def next_input
        # Return recorded input as InputEvent
      end
    end
  end
  ```

### Implementation Targets:
- `lib/vanilla/input.rb` - Input handling abstraction
- `lib/vanilla/input/providers.rb` - Input providers
- `lib/vanilla/input/queue.rb` - Input queue
- `lib/vanilla.rb` - Integration with main game loop

## 4. Deterministic Game Loop

A deterministic game loop ensures that given the same inputs and starting state, the game will always produce the same sequence of states.

### Requirements:
- **Fixed Timestep**: Update game state at fixed intervals
  ```ruby
  def game_loop
    accumulated_time = 0
    frame_time = 1.0/60.0 # 60 FPS

    while running?
      current_time = Time.now
      elapsed = current_time - last_time
      last_time = current_time

      accumulated_time += elapsed

      # Process fixed updates
      while accumulated_time >= frame_time
        update(frame_time)
        accumulated_time -= frame_time
      end

      render()
    end
  end
  ```

- **Deterministic RNG**: Seeded random number generation
  ```ruby
  class GameRandom
    def initialize(seed)
      @rng = Random.new(seed)
    end

    def next_int(max)
      @rng.rand(max)
    end

    # Save/restore state methods
  end
  ```

- **State Update Isolation**: Separate state updates from rendering
  ```ruby
  def update(delta_time)
    # Update game state based on fixed time step
  end

  def render
    # Render current game state
    # No state changes should happen here
  end
  ```

### Implementation Targets:
- `lib/vanilla.rb` - Main game loop
- `lib/vanilla/random.rb` - Deterministic RNG
- `lib/vanilla/update.rb` - Fixed timestep updates

## 5. State Management Architecture

A state management architecture ensures that game state changes are explicit, trackable, and reversible.

### Requirements:
- **State/Behavior Separation**: Clear separation between data and behavior
  ```ruby
  # State (data only)
  class PlayerState
    attr_reader :position, :inventory, :health
    # No behavior methods
  end

  # Behavior
  class PlayerController
    def move(player_state, direction)
      # Return a new PlayerState with updated position
    end
  end
  ```

- **Immutable State**: Prefer creating new state over modifying existing state
  ```ruby
  def move(direction)
    # Instead of modifying @position directly
    new_position = [@position[0] + direction[0], @position[1] + direction[1]]

    # Return a new state with the updated position
    PlayerState.new(
      position: new_position,
      inventory: @inventory.clone,
      health: @health
    )
  end
  ```

- **State Diffing**: Ability to compute differences between states
  ```ruby
  def diff(old_state, new_state)
    changes = {}

    # Compare state properties and record differences
    changes[:position] = new_state.position if old_state.position != new_state.position
    changes[:health] = new_state.health if old_state.health != new_state.health

    changes
  end
  ```

### Implementation Targets:
- `lib/vanilla/state.rb` - Core state management
- `lib/vanilla/state/diff.rb` - State diffing utilities
- Refactor existing classes to separate state and behavior

## 6. Integration Plan

Building these systems should follow a phased approach:

1. **Phase 1: Serialization Layer**
   - Implement basic serialization for all game objects
   - Add save/load functionality for game state

2. **Phase 2: Event System**
   - Set up event bus and event types
   - Convert direct actions to event-based actions

3. **Phase 3: Input Abstraction**
   - Refactor input handling to use the input queue
   - Create keyboard and recording input providers

4. **Phase 4: Game Loop Refactoring**
   - Implement fixed timestep updates
   - Set up deterministic RNG system

5. **Phase 5: State Management**
   - Refactor core classes to separate state and behavior
   - Implement state diffing utilities

6. **Phase 6: State Recording Integration**
   - Combine all systems to implement state recording and playback
   - Create debugging UI for controlling playback

## 7. Technical Debt Considerations

Implementing these systems may require significant refactoring of existing code. Key areas of technical debt to address:

- **Global State**: Eliminate reliance on global variables like `$seed`
- **Direct Property Access**: Use accessors/mutators to track state changes
- **Tight Coupling**: Reduce dependencies between components
- **Missing Abstractions**: Identify and create missing abstractions
- **Inconsistent Patterns**: Standardize patterns across the codebase

## Conclusion

These foundational systems provide the architectural basis for a robust state recording and playback system. While implementing them requires significant effort, they will not only enable recording and playback but also improve the overall quality, testability, and maintainability of the codebase.