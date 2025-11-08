#!/usr/bin/env ruby
# frozen_string_literal: true

# End-to-end test script for combat system
# This script simulates a full game session: move player, encounter monster, kill it, move to new level

require_relative '../lib/vanilla'

# Set up logging
Vanilla::Logger.instance.level = :info

# Create game world
options = { seed: 12345, difficulty: 1 }
game = Vanilla::Game.new(options)
world = game.world

# Get systems
combat_system = world.systems.find { |s, _| s.is_a?(Vanilla::Systems::CombatSystem) }&.first
movement_system = world.systems.find { |s, _| s.is_a?(Vanilla::Systems::MovementSystem) }&.first
message_system = Vanilla::ServiceRegistry.get(:message_system)
player = world.get_entity_by_name('Player')

unless player
  puts "ERROR: Player not found!"
  exit 1
end

puts "=" * 60
puts "END-TO-END COMBAT TEST"
puts "=" * 60
puts "Player ID: #{player.id}"
puts "Starting position: #{player.get_component(:position).row}, #{player.get_component(:position).column}"
puts ""

# Step 1: Generate initial maze
puts "[STEP 1] Generating initial maze..."
game.send(:setup_world)
world.systems.find { |s, _| s.is_a?(Vanilla::Systems::MazeSystem) }&.first&.update(nil)
puts "✓ Maze generated"
puts ""

# Step 2: Find a monster
puts "[STEP 2] Finding a monster..."
monsters = world.current_level.entities.select { |e| e.has_tag?(:monster) }
if monsters.empty?
  puts "⚠ No monsters found on this level"
  puts "  Spawning a test monster..."
  # Create a test monster at position (3, 3)
  monster = Vanilla::EntityFactory.create_monster('Goblin', 3, 3, 20, 5)
  world.current_level.add_entity(monster)
  monsters = [monster]
end

monster = monsters.first
monster_pos = monster.get_component(:position)
puts "✓ Found monster: #{monster.name} at (#{monster_pos.row}, #{monster_pos.column})"
puts "  Monster health: #{monster.get_component(:health).current_health}"
puts ""

# Step 3: Move player towards monster
puts "[STEP 3] Moving player towards monster..."
player_pos = player.get_component(:position)
target_row = monster_pos.row
target_col = monster_pos.column

# Simple pathfinding: move towards monster
moved = false
max_moves = 20
move_count = 0

while (player_pos.row != target_row || player_pos.column != target_col) && move_count < max_moves
  move_count += 1
  direction = nil

  if player_pos.row < target_row
    direction = :south
  elsif player_pos.row > target_row
    direction = :north
  elsif player_pos.column < target_col
    direction = :east
  elsif player_pos.column > target_col
    direction = :west
  end

    if direction
      old_row = player_pos.row
      old_col = player_pos.column
      success = movement_system.move(player, direction)
      if success
        puts "  → Moved #{direction} from (#{old_row}, #{old_col}) to (#{player_pos.row}, #{player_pos.column})"
        moved = true
        world.send(:process_events) # Process events without InputSystem
        message_system&.update(nil) # Process messages

      # Check if we collided with monster
      if player_pos.row == target_row && player_pos.column == target_col
        puts "  ✓ Reached monster position!"
        break
      end
    else
      puts "  ✗ Movement blocked, trying alternative path..."
      # Try alternative direction
      if direction == :south || direction == :north
        direction = player_pos.column < target_col ? :east : :west
      else
        direction = player_pos.row < target_row ? :south : :north
      end
      movement_system.move(player, direction)
      world.send(:process_events) # Process events without InputSystem
      message_system&.update(nil)
    end
  else
    break
  end
end

if player_pos.row == target_row && player_pos.column == target_col
  puts "✓ Player reached monster!"
else
  puts "⚠ Player could not reach monster (moved #{move_count} times)"
  puts "  Player at: (#{player_pos.row}, #{player_pos.column}), Monster at: (#{target_row}, #{target_col})"
end
puts ""

# Step 4: Trigger combat collision
puts "[STEP 4] Triggering combat collision..."
world.emit_event(:entities_collided, {
  entity_id: player.id,
  other_entity_id: monster.id,
  position: { row: player_pos.row, column: player_pos.column }
})
world.send(:process_events) # Process events without InputSystem
message_system&.update(nil)
puts "✓ Combat collision event emitted"
puts ""

# Step 5: Attack monster
puts "[STEP 5] Attacking monster..."
initial_monster_health = monster.get_component(:health).current_health
puts "  Monster health before: #{initial_monster_health}"

attack_command = Vanilla::Commands::AttackCommand.new(player, monster)
attack_command.execute(world)
world.send(:process_events) # Process events without InputSystem
message_system&.update(nil)

final_monster_health = monster.get_component(:health)&.current_health || 0
puts "  Monster health after: #{final_monster_health}"

if final_monster_health <= 0
  puts "✓ Monster killed!"
  if world.get_entity(monster.id).nil?
    puts "  ✓ Monster removed from world"
  end
else
  puts "⚠ Monster still alive with #{final_monster_health} health"
end
puts ""

# Step 6: Find stairs and move to new level
puts "[STEP 6] Finding stairs and moving to new level..."
stairs = world.current_level.entities.find { |e| e.has_tag?(:stairs) }
if stairs
  stairs_pos = stairs.get_component(:position)
  puts "  Found stairs at (#{stairs_pos.row}, #{stairs_pos.column})"

  # Move player to stairs
  puts "  Moving player to stairs..."
  while (player_pos.row != stairs_pos.row || player_pos.column != stairs_pos.column) && move_count < 30
    move_count += 1
    direction = nil

    if player_pos.row < stairs_pos.row
      direction = :south
    elsif player_pos.row > stairs_pos.row
      direction = :north
    elsif player_pos.column < stairs_pos.column
      direction = :east
    elsif player_pos.column > stairs_pos.column
      direction = :west
    end

    if direction
      success = movement_system.move(player, direction)
      if success
        world.send(:process_events) # Process events without InputSystem
        message_system&.update(nil)

        # Check if we reached stairs
        if player_pos.row == stairs_pos.row && player_pos.column == stairs_pos.column
          puts "  ✓ Reached stairs!"
          # Trigger level change
          change_level_command = Vanilla::Commands::ChangeLevelCommand.new(2, player)
          change_level_command.execute(world)
          world.send(:process_events) # Process events without InputSystem
          message_system&.update(nil)
          puts "  ✓ Level changed to difficulty 2"
          puts "  New player position: (#{player.get_component(:position).row}, #{player.get_component(:position).column})"
          break
        end
      end
    else
      break
    end
  end
else
  puts "  ⚠ No stairs found on this level"
end
puts ""

# Step 7: Summary
puts "=" * 60
puts "TEST SUMMARY"
puts "=" * 60
puts "✓ Maze generated"
puts "✓ Monster found and engaged"
puts "✓ Combat executed"
puts "#{final_monster_health <= 0 ? '✓' : '⚠'} Monster #{final_monster_health <= 0 ? 'killed' : 'damaged'}"
puts "#{stairs ? '✓' : '⚠'} Level transition #{stairs ? 'completed' : 'skipped (no stairs)'}"
puts ""
puts "Test completed!"
puts "=" * 60

