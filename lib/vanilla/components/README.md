# Entity-Component System

This folder contains Vanilla's Entity-Component System (ECS) architecture, which provides a flexible and modular approach to game object management.

## What is an ECS?

An Entity-Component System is a software architectural pattern that:

- Separates identity (Entity) from behavior and data (Components)
- Promotes composition over inheritance
- Makes it easy to add, remove, or modify behaviors at runtime
- Simplifies serialization of game objects

## Core Concepts

### Entity

An `Entity` is essentially just an ID with a collection of components. It doesn't contain any game logic itself but acts as a container for components that provide behavior and data.

### Component

A `Component` is a simple data container that represents a single aspect of an entity, such as position, visual representation, or special state. Components typically don't contain complex logic.

## Available Components

- **PositionComponent**: Tracks an entity's position in a grid with row and column coordinates
- **TileComponent**: Handles an entity's visual representation with a tile character
- **StairsComponent**: Tracks whether an entity has found stairs

## Usage

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

## Best Practices

1. Keep components small and focused on a single aspect of an entity
2. Store only data in components, with minimal logic
3. Use the `update` method for component behavior that needs to run every frame
4. Use the Entity's method_missing capability for clean, readable code
5. Always serialize all components needed to fully reconstruct an entity