#!/usr/bin/env ruby
# frozen_string_literal: true

# Test to verify level display updates when transitioning to new level

require_relative '../lib/vanilla'

# Set up logging (suppress warnings)
Vanilla::Logger.instance.level = :error

# Create game with known seed
options = { seed: 12345, difficulty: 1 }
game = Vanilla::Game.new(options)
world = game.world

# Generate initial maze
world.systems.find { |s, _| s.is_a?(Vanilla::Systems::MazeSystem) }&.first&.update(nil)

# Get render system and player
render_system = world.systems.find { |s, _| s.is_a?(Vanilla::Systems::RenderSystem) }&.first
player = world.get_entity_by_name('Player')

if render_system && player
  puts "\n" + "=" * 60
  puts "LEVEL DISPLAY TEST - Level 1"
  puts "=" * 60 + "\n"
  render_system.update(nil)
  
  # Transition to level 2
  puts "\n" + "=" * 60
  puts "Transitioning to Level 2..."
  puts "=" * 60 + "\n"
  
  change_level_command = Vanilla::Commands::ChangeLevelCommand.new(2, player)
  change_level_command.execute(world)
  world.send(:process_events) # Process events without InputSystem
  
  puts "\n" + "=" * 60
  puts "LEVEL DISPLAY TEST - Level 2 (after transition)"
  puts "=" * 60 + "\n"
  render_system.update(nil)
  
  puts "\n" + "=" * 60
  puts "VERIFICATION:"
  puts "  ✓ Level 1: Should show 'Level: 1'"
  puts "  ✓ Level 2: Should show 'Level: 2' (updated)"
  puts "=" * 60 + "\n"
else
  puts "ERROR: RenderSystem or Player not found!"
end

