#!/usr/bin/env ruby
require_relative '../lib/vanilla'

# Set a seed for reproducibility
$seed = 12345

# Create a test grid
grid = Vanilla::MapUtils::Grid.new(rows: 10, columns: 10)
Vanilla::Algorithms::BinaryTree.on(grid)

puts "Created a test grid with BinaryTree algorithm"

# Create renderer and render system
renderer = Vanilla::Renderers::TerminalRenderer.new
render_system = Vanilla::Systems::RenderSystem.new(renderer)

puts "Created renderer and render system"

# Create test entities
player = Vanilla::Components::Entity.new
player.add_component(Vanilla::Components::PositionComponent.new(row: 5, column: 5))
player.add_component(Vanilla::Components::RenderComponent.new(
  character: '@',
  layer: 10
))

monster1 = Vanilla::Components::Entity.new
monster1.add_component(Vanilla::Components::PositionComponent.new(row: 3, column: 7))
monster1.add_component(Vanilla::Components::RenderComponent.new(
  character: 'M',
  layer: 5
))

monster2 = Vanilla::Components::Entity.new
monster2.add_component(Vanilla::Components::PositionComponent.new(row: 7, column: 2))
monster2.add_component(Vanilla::Components::RenderComponent.new(
  character: 'M',
  layer: 5
))

stairs = Vanilla::Components::Entity.new
stairs.add_component(Vanilla::Components::PositionComponent.new(row: 9, column: 9))
stairs.add_component(Vanilla::Components::RenderComponent.new(
  character: '%',
  layer: 1
))

puts "Created test entities (player, monsters, stairs)"
puts "Press Enter to render the test scene..."
gets

# Render the scene
puts "Rendering test scene with multiple entities..."
render_system.render([player, monster1, monster2, stairs], grid)

puts "\nPress Enter to exit..."
gets