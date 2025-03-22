# ECS Architecture Standards for Vanilla Roguelike

## Overview

This document defines architectural rules, patterns, and conventions for the Entity-Component-System (ECS) architecture in the Vanilla roguelike game. These standards are designed to address the issues identified in our diagnosis and provide a consistent framework for future development.

## Core ECS Principles

1. **Entities are just IDs or containers for components**
   - Entities should have no behavior
   - Entities should not contain game logic
   - Entities should not inherit from each other for behavior

2. **Components are pure data**
   - Components should store state but have no behavior
   - Components should provide proper encapsulation
   - Components should have clear accessors and mutators

3. **Systems contain all behavior**
   - Systems operate on entities with specific component combinations
   - Systems should be independent of each other
   - Systems communicate via components and events, not direct calls

4. **Data flow is unidirectional**
   - Systems read from and write to components
   - Components do not modify other components
   - Entities do not modify components directly

## Component Standards

### Component Definition

All components must:

1. Have a unique type identifier
2. Provide read access to their data via getter methods
3. Provide controlled write access via setter methods
4. Be serializable to and from a hash
5. Include documentation of their purpose and valid states

Example:

```ruby
module Vanilla
  module Components
    class PositionComponent < Component
      attr_reader :row, :column

      def initialize(row, column)
        @row = row
        @column = column
      end

      # Controlled access for setting position
      def set_position(row, column)
        @row = row
        @column = column
      end

      # Optional: directional movement with intent
      def translate(delta_row, delta_column)
        @row += delta_row
        @column += delta_column
      end

      # Serialization
      def to_hash
        {
          type: self.class.component_type,
          row: @row,
          column: @column
        }
      end

      # Deserialization
      def self.from_hash(hash)
        new(hash[:row] || 0, hash[:column] || 0)
      end

      # Type identifier
      def self.component_type
        :position
      end
    end
  end
end
```

### Component Responsibilities

Each component should have a single, well-defined responsibility:

| Component Type | Responsibility |
|----------------|----------------|
| PositionComponent | Stores entity location in the grid |
| RenderComponent | Stores visual representation data |
| MovementComponent | Stores movement capabilities and requests |
| HealthComponent | Stores current and maximum health |
| CombatComponent | Stores attack and defense attributes |
| InputComponent | Stores pending input actions |
| InventoryComponent | Stores collected items |

Components should not:
- Store references to other entities
- Contain game logic
- Directly modify the game state

## System Standards

### System Definition

All systems must:

1. Accept a reference to the World in their constructor
2. Implement an `update` method that processes entities
3. Declare the component types they require
4. Not directly call other systems
5. Document their purpose and responsibilities

Example:

```ruby
module Vanilla
  module Systems
    class MovementSystem < System
      def initialize(world)
        super
      end

      def update(delta_time)
        entities = world.query_entities([:position, :movement])

        entities.each do |entity|
          movement = entity.get_component(:movement)
          next unless movement.active?

          position = entity.get_component(:position)

          # Process movement logic here
          # ...

          # Emit events after changes
          world.emit_event(:entity_moved, {
            entity_id: entity.id,
            position: { row: position.row, column: position.column }
          })
        end
      end

      # Helper methods...
    end
  end
end
```

### System Responsibilities

Each system should have a clear, focused responsibility:

| System | Responsibility |
|--------|----------------|
| InputSystem | Process user input and update input components |
| MovementSystem | Handle entity movement based on input or AI |
| CollisionSystem | Detect and respond to entity collisions |
| RenderSystem | Draw entities and level to the display |
| CombatSystem | Handle attack, damage and combat mechanics |
| InventorySystem | Manage item pickups and inventory changes |
| AISystem | Control behavior of non-player entities |
| LevelSystem | Manage level generation and transitions |
| MessageSystem | Handle game message logging and display |

Systems should not:
- Store entity or component state (should be queries when needed)
- Directly call methods on other systems
- Bypass the component interface to modify entities

## World and Event System

### World Class

The World class is the central container for all entities and systems:

```ruby
module Vanilla
  class World
    attr_reader :entities, :systems

    def initialize
      @entities = {}
      @systems = []
      @event_subscribers = Hash.new { |h, k| h[k] = [] }
      @event_queue = Queue.new
    end

    def add_entity(entity)
      @entities[entity.id] = entity
      entity
    end

    def remove_entity(entity_id)
      @entities.delete(entity_id)
    end

    def get_entity(entity_id)
      @entities[entity_id]
    end

    def query_entities(component_types)
      return @entities.values if component_types.empty?

      @entities.values.select do |entity|
        component_types.all? { |type| entity.has_component?(type) }
      end
    end

    def add_system(system, priority = 0)
      @systems << [system, priority]
      @systems.sort_by! { |s, p| p }
    end

    def update(delta_time)
      # Update all systems
      @systems.each do |system, _|
        system.update(delta_time)
      end

      # Process events after systems have updated
      process_events
    end

    def emit_event(event_type, data = {})
      @event_queue << [event_type, data]
    end

    def subscribe(event_type, subscriber)
      @event_subscribers[event_type] << subscriber
    end

    private

    def process_events
      until @event_queue.empty?
        event_type, data = @event_queue.pop
        @event_subscribers[event_type].each do |subscriber|
          subscriber.handle_event(event_type, data)
        end
      end
    end
  end
end
```

### Event System

The event system enables decoupled communication between systems:

1. Systems emit events after state changes
2. Systems subscribe to events they're interested in
3. Events contain the minimal data needed for processing

Example event types:

| Event Type | Purpose | Data |
|------------|---------|------|
| :entity_moved | Notify when entity changes position | entity_id, old_position, new_position |
| :entity_damaged | Notify when entity takes damage | entity_id, damage_amount, source_id |
| :item_collected | Notify when an item is picked up | entity_id, item_id |
| :level_changed | Notify when level transitions | level_id, difficulty |

## Game Class Integration

The Game class should:

1. Create and maintain the World instance
2. Expose access to key elements like current level, player, etc.
3. Manage the main game loop
4. Handle initialization and cleanup

Example:

```ruby
module Vanilla
  class Game
    attr_reader :world, :current_level, :player
    attr_reader :movement_system, :render_system, :message_system

    def initialize
      @world = World.new

      # Create and register systems
      @movement_system = Systems::MovementSystem.new(@world)
      @render_system = Systems::RenderSystem.new(@world)
      @message_system = Systems::MessageSystem.new(@world)

      @world.add_system(@movement_system, 10)
      @world.add_system(@render_system, 20)

      # Create initial level
      @current_level = Level.new(difficulty: 1)

      # Create player
      @player = Entities::PlayerFactory.create(@world,
        @current_level.entrance_row,
        @current_level.entrance_column
      )
    end

    def update(delta_time)
      @world.update(delta_time)
    end

    def transition_to_next_level
      # Level transition logic
    end
  end
end
```

## Naming Conventions

### Filenames

- All files use snake_case
- Component files end with `_component.rb`
- System files end with `_system.rb`
- Entity factory files end with `_factory.rb`

### Class Names

- All classes use CamelCase
- Component classes end with `Component`
- System classes end with `System`
- Entity factory classes end with `Factory`

### Method Names

- Methods use snake_case
- Query methods end with `?` (e.g., `has_component?`)
- Getter methods don't have prefixes (e.g., `position` not `get_position`)
- Setter methods use the pattern `set_property` (e.g., `set_position`)

## Comments and Documentation

All classes, modules, and public methods should include:

1. A brief description of their purpose
2. Parameter descriptions
3. Return value descriptions
4. Exception information if applicable

Example:

```ruby
# Component representing an entity's position in the grid
# @since 1.0.0
class PositionComponent < Component
  # Initialize a new position component
  # @param row [Integer] The row position
  # @param column [Integer] The column position
  # @return [PositionComponent] The new component
  def initialize(row, column)
    @row = row
    @column = column
  end

  # Set the entity's position
  # @param row [Integer] The new row position
  # @param column [Integer] The new column position
  # @return [void]
  def set_position(row, column)
    @row = row
    @column = column
  end

  # ... rest of class
end
```

## Testing Standards

### Component Tests

Components should have tests for:

1. Initialization with various parameters
2. Accessor methods
3. Mutator methods
4. Serialization/deserialization

### System Tests

Systems should have tests for:

1. Processing entities with the required components
2. Ignoring entities without required components
3. Proper state updates
4. Event emissions

### Integration Tests

Integration tests should verify:

1. System interactions work correctly
2. Events are properly propagated
3. Entity state changes are reflected correctly
4. Edge cases don't cause crashes

## Implementation Checklist

When implementing or refactoring a component:

- [ ] Component contains only data, no behavior
- [ ] Component has proper accessor methods
- [ ] Component has controlled mutator methods
- [ ] Component can be serialized/deserialized
- [ ] Component has clear documentation
- [ ] Component has comprehensive tests

When implementing or refactoring a system:

- [ ] System declares required components
- [ ] System processes only entities with required components
- [ ] System communicates through events, not direct calls
- [ ] System has clear documentation
- [ ] System has comprehensive tests

## Conclusion

Following these standards will ensure a clean, maintainable ECS architecture for the Vanilla roguelike game. These guidelines directly address the issues identified in our analysis and provide a clear path for refactoring the existing codebase.