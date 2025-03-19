# Movement System Migration Guide

## Overview

Vanilla is transitioning from a traditional object-oriented approach to an Entity-Component-System (ECS) architecture. This guide provides instructions for migrating legacy movement code to the new ECS pattern.

## Why Migrate?

The ECS architecture offers several advantages:

- **Better separation of concerns**: Data (components) is separated from behavior (systems)
- **Improved performance**: Components can be processed in batches
- **Enhanced extensibility**: New features can be added without modifying existing code
- **Easier testing**: Components and systems can be tested in isolation

## Deprecation Timeline

- **Phase 1**: Legacy movement with deprecation warnings (current)
- **Phase 2**: Usage migration (convert all code to ECS pattern)
- **Phase 3**: Removal of legacy movement code

## Migration Steps

### For Legacy Character Classes

If you have a legacy character class using the `Vanilla::Characters::Shared::Movement` module:

```ruby
# OLD APPROACH
class Character
  include Vanilla::Characters::Shared::Movement

  def move_left
    # custom movement logic
  end
end

# Usage
character.move(:left)
```

Replace with:

```ruby
# NEW APPROACH
class Character < Vanilla::Components::Entity
  def initialize(row:, column:)
    super()
    add_component(Vanilla::Components::PositionComponent.new(row: row, column: column))
    add_component(Vanilla::Components::MovementComponent.new)
    # Add other components as needed
  end
end

# Usage
movement_system = Vanilla::Systems::MovementSystem.new(grid)
movement_system.move(character, :west)
```

### For Direct Movement Module Usage

If you're using the `Vanilla::Movement` module directly:

```ruby
# OLD APPROACH
Vanilla::Movement.move(grid: grid, unit: player, direction: :left)
```

Replace with:

```ruby
# NEW APPROACH
movement_system = Vanilla::Systems::MovementSystem.new(grid)
movement_system.move(player, :west)
```

## Component Reference

### PositionComponent

The `PositionComponent` stores the entity's position in the grid:

```ruby
position = Vanilla::Components::PositionComponent.new(row: 5, column: 10)
entity.add_component(position)

# Access position
position = entity.get_component(:position)
puts "Entity at [#{position.row}, #{position.column}]"
```

### MovementComponent

The `MovementComponent` defines an entity's movement capabilities:

```ruby
# All directions allowed with normal speed
movement = Vanilla::Components::MovementComponent.new

# Limited directions with increased speed
movement = Vanilla::Components::MovementComponent.new(
  speed: 2,
  can_move_directions: [:north, :south] # Can only move vertically
)

entity.add_component(movement)
```

## System Reference

### MovementSystem

The `MovementSystem` handles all movement logic:

```ruby
# Initialize with the game grid
movement_system = Vanilla::Systems::MovementSystem.new(grid)

# Move an entity
success = movement_system.move(entity, :north)
if success
  puts "Entity moved successfully"
else
  puts "Movement failed (blocked or invalid)"
end
```

## Best Practices

1. Always use the ECS pattern for new code
2. Migrate existing code as you modify it
3. Use systems to operate on entities rather than calling methods on entities
4. Keep components as pure data containers
5. Test components and systems separately

## Support

If you encounter issues during migration, contact the core development team for assistance.