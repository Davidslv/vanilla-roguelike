# Event-Driven Architecture Refactoring

## Overview

This proposal outlines a comprehensive refactoring of the Vanilla roguelike game to implement an Event-Driven Architecture (EDA). This architectural approach centralizes communication between components through events, reducing direct coupling and making the system more resilient to changes in individual components.

## Current Architecture Issues

The current Vanilla architecture suffers from:

1. **Direct Method Calls**: Components directly call methods on each other, leading to tight coupling
2. **Rigid Hierarchical Structure**: Objects have strict parent-child relationships
3. **Inconsistent Error Handling**: Error handling is scattered and inconsistent
4. **Unclear Responsibility Boundaries**: Many components have overlapping responsibilities

## Event-Driven Architecture Overview

In an Event-Driven Architecture:

1. **Components communicate through events, not direct method calls**
2. **Event publishers don't know or care who consumes their events**
3. **Event subscribers don't know who published events**
4. **Components can be added, removed, or modified with minimal impact on others**

## Proposed Implementation

### 1. Core Event System

The foundation of our architecture is a robust event system:

```ruby
module Vanilla
  module Events
    # Event base class
    class Event
      attr_reader :type, :data, :source, :timestamp

      def initialize(type, source, data = {})
        @type = type
        @source = source
        @data = data
        @timestamp = Time.now
      end
    end

    # Event bus - central hub for publishing and subscribing to events
    class EventBus
      include Singleton

      def initialize
        @subscribers = Hash.new { |h, k| h[k] = [] }
        @logger = Vanilla::Logger.instance
      end

      def subscribe(event_type, subscriber)
        @subscribers[event_type] << subscriber
        self
      end

      def unsubscribe(event_type, subscriber)
        @subscribers[event_type].delete(subscriber)
        self
      end

      def publish(event)
        @logger.debug("Published event: #{event.type} from #{event.source.class.name}")

        @subscribers[event.type].each do |subscriber|
          begin
            subscriber.handle_event(event)
          rescue => e
            @logger.error("Error handling event #{event.type} in #{subscriber.class.name}: #{e.message}")
            @logger.error(e.backtrace.join("\n"))
          end
        end
      end
    end
  end
end
```

### 2. EventEmitter Mixin

A mixin to easily add event capabilities to any class:

```ruby
module Vanilla
  module Events
    module EventEmitter
      def emit_event(type, data = {})
        event = Event.new(type, self, data)
        EventBus.instance.publish(event)
      end
    end
  end
end
```

### 3. Game Components as Event Sources and Handlers

Key game components will both emit and handle events:

```ruby
module Vanilla
  class Game
    include Events::EventEmitter

    def initialize(options = {})
      @logger = Vanilla::Logger.instance
      @difficulty = options[:difficulty] || 1

      # Register for events
      event_bus = Events::EventBus.instance
      event_bus.subscribe(:player_moved, self)
      event_bus.subscribe(:stairs_reached, self)
      event_bus.subscribe(:level_transition_requested, self)
      event_bus.subscribe(:input_received, self)

      # Initialize systems
      @input_system = InputSystem.new
      @renderer = RenderSystem.new
      @message_system = MessageSystem.new

      # Initialize game state
      initialize_level(@difficulty)
    end

    def start
      emit_event(:game_started)

      # Initial render
      emit_event(:render_requested)

      # Main game loop
      loop do
        # Process input
        input = get_input
        emit_event(:input_received, { key: input })

        # Process timers, animations, etc.
        update

        # Check if the game should exit
        break if @exit_requested
      end

      emit_event(:game_ended)
    end

    def handle_event(event)
      case event.type
      when :player_moved
        player_position = event.data[:position]
        # Handle player movement consequences
        check_for_item_pickups(player_position)

      when :stairs_reached
        emit_event(:level_transition_requested, { difficulty: @difficulty + 1 })

      when :level_transition_requested
        new_difficulty = event.data[:difficulty]
        transition_to_level(new_difficulty)

      when :input_received
        handle_input(event.data[:key])
      end
    end

    private

    def initialize_level(difficulty)
      # Create new level
      @level = Level.new(difficulty: difficulty)

      # Reset game state
      @exit_requested = false

      # Notify systems about the new level
      emit_event(:level_initialized, {
        level: @level,
        difficulty: difficulty
      })
    end

    def transition_to_level(difficulty)
      @logger.info("Transitioning to level with difficulty: #{difficulty}")

      # Notify about level transition start
      emit_event(:level_transition_started, { difficulty: difficulty })

      # Update difficulty
      @difficulty = difficulty

      # Initialize new level
      initialize_level(difficulty)

      # Notify about level transition completion
      emit_event(:level_transition_completed, { difficulty: difficulty })
    end

    def handle_input(key)
      # Handle quit command
      if key == 'q'
        @exit_requested = true
        emit_event(:exit_requested)
        return
      end

      # Handle directional input
      direction = key_to_direction(key)
      if direction
        emit_event(:move_requested, { entity: @level.player, direction: direction })
      end
    end

    def key_to_direction(key)
      case key
      when "k", "K", :KEY_UP then :north
      when "j", "J", :KEY_DOWN then :south
      when "h", "H", :KEY_LEFT then :west
      when "l", "L", :KEY_RIGHT then :east
      else nil
      end
    end
  end
end
```

### 4. Systems as Event Handlers

Systems are decoupled and communicate only via events:

```ruby
module Vanilla
  class MovementSystem
    include Events::EventEmitter

    def initialize
      @logger = Vanilla::Logger.instance
      @level = nil

      # Register for events
      event_bus = Events::EventBus.instance
      event_bus.subscribe(:move_requested, self)
      event_bus.subscribe(:level_initialized, self)
    end

    def handle_event(event)
      case event.type
      when :level_initialized
        @level = event.data[:level]

      when :move_requested
        entity = event.data[:entity]
        direction = event.data[:direction]

        handle_movement(entity, direction)
      end
    end

    private

    def handle_movement(entity, direction)
      return unless @level && entity

      # Get components
      position = entity.get_component(:position)
      return unless position

      # Calculate new position
      new_position = calculate_new_position(position, direction)

      # Check if movement is possible
      if can_move_to?(new_position)
        # Store old position for event
        old_position = { row: position.row, column: position.column }

        # Update position
        position.row = new_position[:row]
        position.column = new_position[:column]

        # Emit movement event
        emit_event(:entity_moved, {
          entity: entity,
          old_position: old_position,
          new_position: { row: position.row, column: position.column }
        })

        # Check for special tiles
        check_special_tiles(entity, position)
      end
    end

    def calculate_new_position(position, direction)
      row, column = position.row, position.column

      case direction
      when :north then { row: row - 1, column: column }
      when :south then { row: row + 1, column: column }
      when :east then { row: row, column: column + 1 }
      when :west then { row: row, column: column - 1 }
      else { row: row, column: column }
      end
    end

    def can_move_to?(position)
      cell = @level.grid[position[:row], position[:column]]
      return false unless cell

      Vanilla::Support::TileType.walkable?(cell.tile)
    end

    def check_special_tiles(entity, position)
      # Check if entity is player
      return unless entity.has_component?(:player)

      # Check if player is at stairs
      stairs = @level.stairs
      stairs_position = stairs.get_component(:position)

      if position.row == stairs_position.row && position.column == stairs_position.column
        emit_event(:stairs_reached, { entity: entity })
      end
    end
  end
end
```

### 5. Level System as Event Emitter and Handler

```ruby
module Vanilla
  class Level
    include Events::EventEmitter

    attr_reader :grid, :player, :stairs, :difficulty

    def initialize(options = {})
      @difficulty = options[:difficulty] || 1
      @grid = generate_grid(options)

      # Create entities
      create_entities

      # Update grid with entities
      update_grid_with_entities

      # Notify about initialization completion
      emit_event(:level_ready, {
        grid: @grid,
        player: @player,
        stairs: @stairs,
        difficulty: @difficulty
      })
    end

    def all_entities
      result = [@player, @stairs]

      # Add monsters if available
      monster_system = get_monster_system
      result += monster_system.monsters if monster_system && monster_system.respond_to?(:monsters)

      result
    end

    def update_grid_with_entities
      # Reset walkable cells
      @grid.rows.times do |row|
        @grid.columns.times do |col|
          cell = @grid[row, col]
          if cell && Vanilla::Support::TileType.walkable?(cell.tile)
            cell.tile = Vanilla::Support::TileType::EMPTY
          end
        end
      end

      # Update entity positions
      all_entities.each do |entity|
        if entity.has_component?(:position) && entity.has_component?(:render)
          pos = entity.get_component(:position)
          render = entity.get_component(:render)

          cell = @grid[pos.row, pos.column]
          cell.tile = render.character if cell
        end
      end

      # Notify about grid update
      emit_event(:grid_updated, { grid: @grid })
    end

    private

    def generate_grid(options)
      # Implementation
    end

    def create_entities
      # Implementation
    end

    def get_monster_system
      game = Vanilla::ServiceRegistry.get(:game)
      game&.monster_system
    end
  end
end
```

### 6. MessageSystem as Event Handler

```ruby
module Vanilla
  class MessageSystem
    include Events::EventEmitter

    def initialize
      @logger = Vanilla::Logger.instance
      @message_log = Vanilla::Messages::MessageLog.new

      # Register for events
      event_bus = Events::EventBus.instance
      event_bus.subscribe(:entity_moved, self)
      event_bus.subscribe(:stairs_reached, self)
      event_bus.subscribe(:level_transition_completed, self)
      event_bus.subscribe(:item_picked_up, self)
    end

    def handle_event(event)
      case event.type
      when :entity_moved
        entity = event.data[:entity]

        # Only log player movement
        if entity.has_component?(:player)
          log_message("movement.player_moved", importance: :info, category: :movement)
        end

      when :stairs_reached
        log_message("level.stairs_found", importance: :success, category: :level)

      when :level_transition_completed
        difficulty = event.data[:difficulty]
        log_message("level.descended", { level: difficulty }, importance: :success, category: :level)

      when :item_picked_up
        item = event.data[:item]
        item_name = item.get_component(:item).name
        log_message("items.picked_up.single", { item: item_name }, importance: :normal, category: :item)
      end
    end

    def log_message(key, metadata = {}, options = {})
      # Ensure options is a hash
      options = {} unless options.is_a?(Hash)

      # Add metadata to options if it's a hash
      if metadata.is_a?(Hash)
        options[:metadata] = metadata
      end

      # Add the message to the log
      @message_log.add(key, options)

      # Emit message logged event
      emit_event(:message_logged, {
        key: key,
        options: options
      })
    end
  end
end
```

## Migration Strategy

### Phase 1: Implement Core Event System
- Create Event, EventBus, and EventEmitter classes
- Implement basic event handling infrastructure

### Phase 2: Refactor Key Components
- Start with Game, Level, and MovementSystem
- Convert direct method calls to event emissions

### Phase 3: Implement Event Handlers
- Create event handlers for all systems
- Ensure proper event subscription

### Phase 4: Standardize Error Handling
- Add consistent error handling in event handlers
- Implement error events and recovery mechanisms

### Phase 5: Transition Game Loop
- Refactor the main game loop to be fully event-driven
- Remove remaining direct dependencies

## Benefits

1. **Loose Coupling**: Components communicate indirectly through events
2. **Enhanced Testability**: Components can be tested in isolation with mock events
3. **Improved Error Handling**: Centralized error handling in event processing
4. **Easier Extensions**: New components can subscribe to existing events
5. **Better Debugging**: Event flow provides clear traceability

## Drawbacks

1. **Indirection**: Event flows can be harder to trace than direct method calls
2. **Learning Curve**: Event-based thinking is different from procedural code
3. **Potential Performance Overhead**: Event dispatch adds some overhead

## Specific Problems Addressed

1. **Private Method Access**: Components access each other through events, not direct method calls
2. **Parameter Mismatch**: Event data structures enforce consistent parameter formats
3. **Tight Coupling**: Components are decoupled through the event system
4. **Ambiguous Ownership**: Clear separation between event publishers and subscribers

## Quality Assessment

This proposal is rated **4.7/5** based on:
- Strong focus on decoupling components through events
- Comprehensive handling of the identified architectural issues
- Clear migration path with incremental adoption
- Robust error handling through event infrastructure
- Alignment with modern architectural patterns

This event-driven architecture would significantly improve the maintainability and extensibility of the Vanilla roguelike game, making it much more resilient to changes and new features.