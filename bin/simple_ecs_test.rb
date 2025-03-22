#!/usr/bin/env ruby

# Add lib directory to load path
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'vanilla'

puts "Creating a test world..."
world = Vanilla::World.new

puts "Creating a test entity..."
entity = Vanilla::Components::Entity.new
entity.add_component(Vanilla::Components::PositionComponent.new(row: 5, column: 5))
entity.add_component(Vanilla::Components::RenderComponent.new(character: '@', color: :white))
entity.add_component(Vanilla::Components::InputComponent.new)
entity.add_component(Vanilla::Components::MovementComponent.new)
entity.add_tag(:player)
entity.name = "Test Player"

puts "Adding entity to world..."
world.add_entity(entity)

puts "Adding systems to world..."
world.add_system(Vanilla::Systems::InputSystem.new(world), 1)
world.add_system(Vanilla::Systems::MovementSystem.new(world), 2)
world.add_system(Vanilla::Systems::RenderSystem.new(world), 3)

puts "Running one update cycle..."
world.update(0.1)

puts "Test complete!"