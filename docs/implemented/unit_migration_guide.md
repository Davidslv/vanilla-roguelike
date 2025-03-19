# Unit to Entity Migration Guide

This guide outlines the process for migrating from the legacy `Vanilla::Unit` class to the new Entity-Component-System (ECS) architecture.

## Overview

The `Vanilla::Unit` class is being deprecated in favor of the ECS architecture. This migration is part of our larger effort to improve modularity, reusability, and maintainability of the codebase.

## Reasons for the Migration

1. **Improved Modularity**: The ECS pattern separates data (components) from behavior (systems), making the code more modular and easier to maintain.
2. **Enhanced Flexibility**: Components can be added or removed from entities at runtime, allowing for greater flexibility.
3. **Better Performance**: The ECS pattern can lead to better performance through data-oriented design and cache-friendly patterns.
4. **Future-Proofing**: The ECS pattern is widely used in game development and provides a solid foundation for future features.

## Migration Steps

### 1. Replace Unit instantiation with Entity creation

Instead of:

```ruby
unit = Vanilla::Unit.new(row: 5, column: 10, tile: '@')
```

Use:

```ruby
entity = Vanilla::Components::Entity.new
entity.add_component(Vanilla::Components::PositionComponent.new(row: 5, column: 10))
entity.add_component(Vanilla::Components::TileComponent.new(tile: '@'))
entity.add_component(Vanilla::Components::StairsComponent.new)
```

### 2. Replace direct property access with component access

Instead of:

```ruby
unit.row = 6
column = unit.column
coordinates = unit.coordinates
```

Use:

```ruby
# While you can use method_missing for backward compatibility:
entity.row = 6
column = entity.column

# It's better to use the component directly:
position_component = entity.get_component(:position)
position_component.row = 6
column = position_component.column
coordinates = position_component.coordinates
```

### 3. Replace stairs functionality

Instead of:

```ruby
unit.found_stairs = true
if unit.found_stairs?
  # Do something
end
```

Use:

```ruby
# While you can use method_missing for backward compatibility:
entity.found_stairs = true
if entity.found_stairs?
  # Do something
end

# It's better to use the component directly:
stairs_component = entity.get_component(:stairs)
stairs_component.found_stairs = true
if stairs_component.found_stairs
  # Do something
end
```

### 4. Use the Movement System for movement

Instead of using the deprecated movement code, use the Movement System:

```ruby
movement_system = Vanilla::Systems::MovementSystem.new(grid)
movement_system.move(entity, :north)
```

## Complete Example

Here's a complete example of migrating a typical Unit usage to an Entity with components:

```ruby
# Old approach with Unit
unit = Vanilla::Unit.new(row: 5, column: 10, tile: '@')
unit.row = 6
coordinates = unit.coordinates
unit.found_stairs = true

# New approach with Entity and Components
entity = Vanilla::Components::Entity.new
entity.add_component(Vanilla::Components::PositionComponent.new(row: 5, column: 10))
entity.add_component(Vanilla::Components::TileComponent.new(tile: '@'))
entity.add_component(Vanilla::Components::StairsComponent.new)
entity.add_component(Vanilla::Components::MovementComponent.new)

# Using components directly (preferred)
position_component = entity.get_component(:position)
position_component.row = 6
coordinates = position_component.coordinates

stairs_component = entity.get_component(:stairs)
stairs_component.found_stairs = true

# Moving the entity
movement_system = Vanilla::Systems::MovementSystem.new(grid)
movement_system.move(entity, :north)
```

## Using the Player Entity

For most cases, you'll want to use the `Vanilla::Entities::Player` class, which is a pre-configured entity with all the necessary components:

```ruby
player = Vanilla::Entities::Player.new(row: 5, column: 10)
player.row = 6  # Uses method_missing to delegate to the PositionComponent
coordinates = player.coordinates  # Delegates to PositionComponent
player.found_stairs = true  # Delegates to StairsComponent

# Moving the player
movement_system = Vanilla::Systems::MovementSystem.new(grid)
movement_system.move(player, :north)
```

## Timeline

The `Unit` class is now deprecated and will be removed in a future release. All new code should use the Entity-Component-System architecture instead.