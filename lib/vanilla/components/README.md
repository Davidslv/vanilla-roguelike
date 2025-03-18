# Components in Entity-Component-System Architecture

This folder contains component implementations for Vanilla's Entity-Component-System (ECS) architecture.

## What are Components in ECS?

Components are the "data" part of the ECS pattern. While:
- **Entities** are just identifiers for game objects
- **Systems** contain the logic that processes entities

**Components** are pure data containers that represent a single aspect of an entity. They store state but typically contain minimal logic. Components enable a modular, composition-based approach to building game objects.

## Key Principles of Components

1. **Data-Focused**: Components should primarily store data, not behavior.
2. **Single Responsibility**: Each component should represent one aspect of an entity (position, appearance, etc.).
3. **Composition**: Complex entities are built by combining multiple components.
4. **Reusability**: Components should be reusable across different types of entities.
5. **Serializable**: Components should be easily serializable for saving/loading game state.

## Implemented Components

### PositionComponent

`PositionComponent` tracks an entity's position in the game world. It:
- Stores row and column coordinates
- Provides methods for absolute and relative movement
- Supports serialization and deserialization

### TileComponent

`TileComponent` handles an entity's visual representation. It:
- Stores the character used to represent the entity on the grid
- Validates tile types against allowed values
- Provides methods to change the entity's appearance

### MovementComponent

`MovementComponent` defines an entity's movement capabilities. It:
- Stores movement speed
- Defines which directions an entity can move
- Controls movement restrictions

### StairsComponent

`StairsComponent` tracks whether an entity has found stairs. It:
- Stores a boolean flag for stairs discovery
- Provides methods to update the stairs found state

## The Entity Class

The `Entity` class is the container for components and provides core ECS functionality:

- Unique ID generation for each entity
- Adding, removing, and accessing components
- Serialization and deserialization
- Method delegation to components for cleaner code

## Usage Examples

### Creating an Entity

```ruby
# Create a new entity with an auto-generated ID
entity = Vanilla::Components::Entity.new

# Create an entity with a specific ID
custom_entity = Vanilla::Components::Entity.new(id: "player-001")
```

### Adding Components to an Entity

```ruby
# Create components
position = Vanilla::Components::PositionComponent.new(row: 5, column: 10)
tile = Vanilla::Components::TileComponent.new(tile: Vanilla::Support::TileType::PLAYER)
stairs = Vanilla::Components::StairsComponent.new

# Add components to the entity
entity.add_component(position)
entity.add_component(tile)
entity.add_component(stairs)

# Method chaining is also supported
entity.add_component(position)
      .add_component(tile)
      .add_component(stairs)
```

### Accessing Component Data

```ruby
# Get a specific component
position = entity.get_component(:position)
tile = entity.get_component(:tile)

# Check if an entity has a component
if entity.has_component?(:stairs)
  # Do something
end

# Using method_missing for convenient access
row = entity.row             # Delegates to position component
entity.column = 12           # Delegates setter to position component
tile_char = entity.tile      # Delegates to tile component
found = entity.found_stairs? # Delegates to stairs component
```

### Updating an Entity

```ruby
# Update all components with a delta time
entity.update(0.016) # ~60 FPS
```

### Removing Components

```ruby
# Remove a component by type
position_component = entity.remove_component(:position)
```

### Serialization and Deserialization

```ruby
# Convert an entity to a hash (for saving)
entity_data = entity.to_hash

# Load an entity from a hash (for loading)
loaded_entity = Vanilla::Components::Entity.from_hash(entity_data)
```

## Creating Custom Components

To create a new component type:

1. Inherit from `Vanilla::Components::Component`
2. Implement the `type` method to return a unique symbol
3. Add any required attributes and behaviors
4. Implement the `data` method for serialization
5. Implement the `self.from_hash` method for deserialization
6. Register the component using `Component.register(YourComponent)`

Example:

```ruby
module Vanilla
  module Components
    class HealthComponent < Component
      attr_accessor :current_health, :max_health

      def initialize(current_health: 100, max_health: 100)
        @current_health = current_health
        @max_health = max_health
        super() # Important: call super to ensure proper initialization
      end

      def type
        :health
      end

      def data
        {
          current_health: @current_health,
          max_health: @max_health
        }
      end

      def self.from_hash(hash)
        new(
          current_health: hash[:current_health],
          max_health: hash[:max_health]
        )
      end
    end

    # Register this component type
    Component.register(HealthComponent)
  end
end
```

## Component and System Interaction

Components provide data that Systems operate on:

1. Systems query entities for specific component combinations
2. Systems read data from components
3. Systems perform logic based on component data
4. Systems write results back to components

For example, a `MovementSystem` would:
- Find entities with both `PositionComponent` and `MovementComponent`
- Read current position and movement capabilities
- Calculate new positions based on input and collision detection
- Update the position component with new coordinates

## Best Practices

1. **Keep Components Minimal**: Components should be small, focused data containers
2. **Avoid Inter-Component Dependencies**: Components should not directly reference other components
3. **Use Plain Data Types**: Prefer simple data types that are easy to serialize
4. **Composition over Inheritance**: Create specialized entities by combining components, not by subclassing
5. **Immutable When Possible**: Consider making component data immutable to prevent unexpected changes
6. **Thorough Documentation**: Document component purpose, data, and how systems should use it
7. **Comprehensive Testing**: Create unit tests for component serialization and behavior