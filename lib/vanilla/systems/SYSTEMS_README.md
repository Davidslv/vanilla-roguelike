# Systems in Entity-Component-System Architecture

This directory contains system implementations for Vanilla's Entity-Component-System (ECS) architecture.

## What are Systems in ECS?

Systems are the "behavior" part of the ECS pattern. While:
- **Entities** are just identifiers for game objects
- **Components** are pure data containers attached to entities

**Systems** contain the logic that processes entities with specific component combinations. Systems implement game mechanics and behaviors without being tightly coupled to specific entity types.

## Key Principles of Systems

1. **Single Responsibility**: Each system should focus on one specific aspect of gameplay (e.g., movement, combat, AI).
2. **Component-Based Logic**: Systems operate on entities based on their component composition, not their entity type.
3. **Data-Oriented**: Systems process data from components, emphasizing data transformation over object behavior.
4. **Statelessness**: Systems should generally avoid maintaining internal state, instead reading state from components.
5. **Performance**: Systems should be designed with performance in mind, processing entities efficiently.

## Implemented Systems

### MovementSystem

`MovementSystem` handles entity movement in the game world. It:
- Processes entities with both Position and Movement components
- Validates movement against the game grid (collision detection)
- Updates entity positions based on movement direction
- Handles special collision cases (like finding stairs)

### MonsterSystem

`MonsterSystem` manages monster behavior in the game. It:
- Spawns monsters at appropriate locations based on level difficulty
- Controls monster movement (pathfinding, random wandering)
- Detects player-monster collisions
- Manages monster lifecycle (creation, updates, removal)

## Using Systems in Vanilla

Systems are typically instantiated and updated from the main game loop. Example usage:

```ruby
# Create a movement system with access to the game grid
movement_system = MovementSystem.new(grid)

# Move an entity that has appropriate components
movement_system.move(entity, :north)
```

## Implementing New Systems

When creating a new system:

1. **Name Clearly**: Use a descriptive name ending with "System"
2. **Define Component Requirements**: Document which components your system requires
3. **Use Dependency Injection**: Accept dependencies in the constructor
4. **Provide a Clear API**: Define clear methods for how the system should be used
5. **Log Important Events**: Use the logger for debugging and tracing
6. **Publish Events**: Use the event system to notify other systems of changes

Example skeleton for a new system:

```ruby
module Vanilla
  module Systems
    # The CombatSystem handles attack and damage calculations between entities
    #
    # Required Components:
    # - HealthComponent - For tracking and updating entity health
    # - CombatComponent - For combat capabilities and stats
    class CombatSystem
      def initialize(logger)
        @logger = logger
      end

      # Process an attack between attacker and defender entities
      # @param attacker [Entity] entity performing the attack
      # @param defender [Entity] entity receiving the attack
      # @return [Boolean] whether the attack was successful
      def process_attack(attacker, defender)
        # Implementation goes here
      end
    end
  end
end
```

## Best Practices

1. **Separate Update Logic**: Use different methods for different behaviors rather than one large update method
2. **Validate Component Existence**: Always check that entities have required components before processing
3. **Use Events for Communication**: Use the event system for communicating between systems
4. **Performance Optimizations**: For systems processing many entities, consider spatial partitioning or other optimization techniques
5. **Error Handling**: Gracefully handle missing components or invalid states
6. **Testing**: Create unit tests that verify system behavior with mocked components

By following these guidelines, systems remain modular, testable, and maintainable while implementing the game's behaviors.