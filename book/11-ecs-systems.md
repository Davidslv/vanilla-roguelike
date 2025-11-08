# Chapter 11: Building ECS - Systems

## Systems: Logic That Processes Entities

Systems are where the behavior lives in ECS. They contain the logic that operates on entities with specific component combinations. A system doesn't care what type of entity it's processing—it only cares about the components.

### System Base Class

In Vanilla, all systems inherit from a base `System` class:

```ruby
module Vanilla
  module Systems
    class System
      def initialize(world)
        @world = world
      end

      def update(_delta_time)
        # Override in subclasses
      end

      def entities_with(*component_types)
        @world.query_entities(component_types)
      end

      def emit_event(event_type, data = {})
        @world.emit_event(event_type, data)
      end

      def queue_command(command)
        @world.queue_command(command)
      end
    end
  end
end
```

The base system provides:
- Access to the world (for querying entities)
- Helper methods to find entities with specific components
- Methods to emit events and queue commands

### MovementSystem: Processing Movement

The `MovementSystem` processes entities that can move:

```ruby
module Vanilla
  module Systems
    class MovementSystem < System
      def update(_delta_time)
        movable_entities = entities_with(:position, :movement, :input, :render)
        movable_entities.each { |entity| process_entity_movement(entity) }
      end

      def process_entity_movement(entity)
        input = entity.get_component(:input)
        direction = input.move_direction
        return unless direction

        success = move(entity, direction)
        input.move_direction = nil if success
      end

      def move(entity, direction)
        position = entity.get_component(:position)
        movement = entity.get_component(:movement)
        return false unless movement&.active?

        grid = @world.current_level.grid
        return false unless grid

        current_cell = grid[position.row, position.column]
        new_cell = get_cell_in_direction(current_cell, direction)
        return false unless new_cell && can_move_to?(new_cell)

        position.set_position(new_cell.row, new_cell.column)
        emit_event(:movement_succeeded, {
          entity_id: entity.id,
          new_position: { row: new_cell.row, column: new_cell.column }
        })
        true
      end
    end
  end
end
```

Notice:
- The system queries for entities with specific components (`:position, :movement, :input, :render`)
- It doesn't care if it's a player, monster, or anything else
- It processes each entity based on its components
- It emits events to notify other systems

### RenderSystem: Drawing Entities

The `RenderSystem` draws entities that can be seen:

```ruby
module Vanilla
  module Systems
    class RenderSystem < System
      def update(_delta_time)
        grid = @world.current_level.grid
        return unless grid

        # Draw grid
        grid.each_cell do |cell|
          draw_cell(cell)
        end

        # Draw entities
        renderable_entities = entities_with(:position, :render)
        renderable_entities.each do |entity|
          position = entity.get_component(:position)
          render = entity.get_component(:render)
          draw_entity(position.row, position.column, render.character)
        end
      end
    end
  end
end
```

The system:
- Queries for entities with `:position` and `:render` components
- Draws each entity at its position
- Doesn't know or care what type of entity it's drawing

### CombatSystem: Handling Combat

The `CombatSystem` processes combat between entities:

```ruby
module Vanilla
  module Systems
    class CombatSystem < System
      def process_attack(attacker, target)
        attacker_combat = attacker.get_component(:combat)
        target_combat = target.get_component(:combat)
        return false unless attacker_combat && target_combat

        # Check if attack hits
        hit = rand < attacker_combat.accuracy
        return false unless hit

        # Calculate damage
        damage = calculate_damage(attacker_combat, target_combat)

        # Apply damage
        apply_damage(target, damage, attacker)

        # Check for death
        check_death(target, attacker)

        true
      end

      def calculate_damage(attacker_combat, defender_combat)
        damage = attacker_combat.attack_power - defender_combat.defense
        [damage, 1].max  # Minimum 1 damage
      end

      def apply_damage(target, damage, source = nil)
        health = target.get_component(:health)
        return unless health

        health.current_health = [health.current_health - damage, 0].max

        emit_event(:combat_damage, {
          target_id: target.id,
          damage: damage,
          source_id: source&.id
        })
      end

      def check_death(entity, killer = nil)
        health = entity.get_component(:health)
        return false unless health
        return false unless health.current_health <= 0

        emit_event(:combat_death, {
          entity_id: entity.id,
          killer_id: killer&.id
        })

        @world.remove_entity(entity.id)
        true
      end
    end
  end
end
```

The system:
- Operates on entities with `:combat` and `:health` components
- Calculates damage based on component data
- Modifies health components
- Emits events for other systems to react to

## System Priority: Order Matters

Systems run in a specific order. This is crucial because some systems depend on others completing first.

### Vanilla's System Order

```ruby
# Systems are added with priorities
@world.add_system(MazeSystem.new(@world), 0)        # Generate maze first
@world.add_system(InputSystem.new(@world), 1)        # Process input
@world.add_system(MovementSystem.new(@world), 2)     # Move entities
@world.add_system(CombatSystem.new(@world), 3)       # Handle combat
@world.add_system(CollisionSystem.new(@world), 3)   # Check collisions
@world.add_system(MonsterSystem.new(@world), 4)     # Update monster AI
@world.add_system(RenderSystem.new(@world), 10)     # Render last
```

The order ensures:
1. **Maze generation** happens first (if needed)
2. **Input** is processed before movement
3. **Movement** happens before collision detection
4. **Combat** and **collisions** are checked after movement
5. **Monster AI** runs after player actions
6. **Rendering** happens last, showing the final state

### Why Order Matters

If systems ran in the wrong order, you'd see:
- Entities rendering before they move (flickering)
- Collisions detected before movement (false positives)
- Input processed after rendering (delayed response)

The priority system ensures correct execution order.

## Query Pattern: Finding Entities by Components

Systems find entities using the query pattern:

```ruby
def entities_with(*component_types)
  @world.query_entities(component_types)
end
```

This returns all entities that have **all** of the specified components.

**Example:**
```ruby
# Find all entities that can move and be rendered
movable = entities_with(:position, :movement, :render)

# Find all entities that can fight
combatants = entities_with(:combat, :health)

# Find all entities that are items
items = entities_with(:item, :position)
```

The query is efficient because:
- It only checks entities that exist
- It uses component maps for fast lookups
- It returns only entities that match all requirements

## System Update Pattern

Every system follows the same pattern:

```ruby
def update(_delta_time)
  # 1. Query for entities with required components
  relevant_entities = entities_with(:component1, :component2)

  # 2. Process each entity
  relevant_entities.each do |entity|
    process_entity(entity)
  end

  # 3. Emit events if needed
  emit_event(:system_completed, { count: relevant_entities.size })
end
```

This pattern ensures:
- Systems only process relevant entities
- Logic is consistent across systems
- Events are emitted for other systems to react

## System Independence

Systems are independent. They don't know about each other. They communicate through:
- **Events**: Systems emit events that other systems can subscribe to
- **Components**: Systems read and modify components
- **World queries**: Systems query for entities through the world

This independence makes systems:
- **Testable**: Test a system in isolation
- **Reusable**: Use the same system in different games
- **Maintainable**: Change one system without affecting others

## Key Takeaway

Systems contain the behavior in ECS. They query for entities with specific components, process them, and emit events. Systems are independent, reusable, and testable. Understanding how systems work is key to building with ECS.

## Exercises

1. **Design a system**: Think of a new game feature (like hunger or magic). What system would you create? What components would it query for?

2. **System order**: Why does `RenderSystem` run last? What would happen if it ran first?

3. **Query practice**: What query would you use to find all entities that can be picked up? What components would those entities need?

4. **System independence**: How would you test `MovementSystem` in isolation? What would you need to mock?

