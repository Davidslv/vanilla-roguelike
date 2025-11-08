# Chapter 17: AI and Monsters

## Simple AI Patterns: Random Movement, Player Detection

Monster AI in Vanilla is simple but effective. Monsters either move randomly or toward the player.

### MonsterSystem: Managing Monsters

```ruby
module Vanilla
  module Systems
    class MonsterSystem < System
      def update(_delta_time)
        # Remove dead monsters
        @monsters.reject! do |monster|
          health = monster.get_component(:health)
          if health.current_health <= 0
            @world.remove_entity(monster.id)
            true
          else
            false
          end
        end

        # Move living monsters
        @monsters.each { |monster| move_monster(monster) }
      end

      def move_monster(monster)
        player_pos = @player.get_component(:position)
        monster_pos = monster.get_component(:position)

        # Simple AI: move toward player
        direction = choose_direction(monster_pos, player_pos)
        movement_system = @world.systems.find { |s, _| s.is_a?(MovementSystem) }&.first
        movement_system.move(monster, direction) if direction
      end

      def choose_direction(monster_pos, player_pos)
        row_diff = player_pos.row - monster_pos.row
        col_diff = player_pos.column - monster_pos.column

        # Prefer moving toward player
        if row_diff.abs > col_diff.abs
          row_diff > 0 ? :south : :north
        else
          col_diff > 0 ? :east : :west
        end
      end
    end
  end
end
```

The system:
- Manages monster lifecycle (spawning, removal)
- Implements simple AI (move toward player)
- Uses the same `MovementSystem` as the player

## Monster Spawning: Procedural Placement

Monsters are spawned during level generation:

```ruby
def spawn_monsters(level, grid)
  count = determine_monster_count(level)
  count.times { spawn_monster(level, grid) }
end

def spawn_monster(level, grid)
  # Find a random floor cell
  floor_cells = grid.each_cell.select { |c| !c.links.empty? }
  cell = floor_cells.sample

  # Create monster entity
  monster = EntityFactory.create_monster(:goblin, cell.row, cell.column, 30, 5)
  @world.add_entity(monster)
  @monsters << monster
end
```

Monsters are placed on floor cells, ensuring they're reachable.

## Monster Behavior: Systems That Control Non-Player Entities

Monster behavior is just another system processing entities:

- **MonsterSystem**: Manages monster AI and lifecycle
- **MovementSystem**: Handles monster movement (same as player)
- **CombatSystem**: Processes monster attacks
- **RenderSystem**: Draws monsters (same as other entities)

Monsters are entities with components, processed by systems. No special handling needed.

## AI Is Just Another System Processing Entities

This is the power of ECS: AI is just a system that processes entities. You could:

- Add different AI behaviors (flee, patrol, guard)
- Create different monster types (fast, strong, smart)
- Implement complex AI (pathfinding, group behavior)

All by adding components and systems. The architecture supports any behavior.

## Key Takeaway

AI in ECS is just another system processing entities. Monsters are entities with components, and systems control their behavior. This makes AI extensible: add new components for new behaviors, add new systems for new AI patterns.

## Exercises

1. **Design AI**: How would you implement a "fleeing" monster? What components and systems would you need?

2. **Monster types**: How would you create different monster types with different behaviors? What would vary?

3. **Pathfinding**: How would you implement A* pathfinding for monsters? What system would handle it?

4. **Group behavior**: How would you make monsters work together? What new systems would you create?

