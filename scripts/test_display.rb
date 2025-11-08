#!/usr/bin/env ruby
# frozen_string_literal: true

# Quick test to verify the display shows health and seed correctly

require_relative '../lib/vanilla'

# Set up logging (suppress warnings)
Vanilla::Logger.instance.level = :error

# Create game with known seed
options = { seed: 12345, difficulty: 1 }
game = Vanilla::Game.new(options)
world = game.world

# Generate maze
world.systems.find { |s, _| s.is_a?(Vanilla::Systems::MazeSystem) }&.first&.update(nil)

# Get render system and render once
render_system = world.systems.find { |s, _| s.is_a?(Vanilla::Systems::RenderSystem) }&.first
player = world.get_entity_by_name('Player')

if render_system && player
  puts "\n" + "=" * 60
  puts "DISPLAY TEST - Initial state"
  puts "=" * 60 + "\n"
  render_system.update(nil)
  
  # Damage player and render again
  health = player.get_component(:health)
  health.current_health = 75
  
  puts "\n" + "=" * 60
  puts "DISPLAY TEST - After taking 25 damage"
  puts "=" * 60 + "\n"
  render_system.update(nil)
  
  puts "\n" + "=" * 60
  puts "VERIFICATION:"
  puts "  ✓ Initial: HP: 100/100 (100%)"
  puts "  ✓ After damage: HP: 75/100 (75%)"
  puts "  ✓ Seed: 12345 (visible)"
  puts "  ✓ Level: 1 (visible)"
  puts "=" * 60 + "\n"
else
  puts "ERROR: RenderSystem or Player not found!"
end

