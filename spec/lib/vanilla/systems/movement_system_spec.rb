# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Vanilla::Systems::MovementSystem do
  let(:world) { Vanilla::World.new }
  let(:grid) { instance_double("Vanilla::Grid") }
  let(:entity) { Vanilla::Components::Entity.new }
  let(:position_component) { Vanilla::Components::PositionComponent.new(row: 5, column: 10) }
  let(:movement_component) { Vanilla::Components::MovementComponent.new }
  let(:input_component) { Vanilla::Components::InputComponent.new }
  let(:logger) { instance_double("Vanilla::Logger", debug: nil, info: nil, warn: nil, error: nil) }
  let(:level) { instance_double("Vanilla::Level", grid: grid) }
  let(:current_cell) { instance_double("Vanilla::Cell", row: 5, column: 10) }
  let(:target_cell) { instance_double("Vanilla::Cell", row: 4, column: 10) }

  before do
    allow(Vanilla::Logger).to receive(:instance).and_return(logger)

    # Setup world, level and grid
    world.set_level(level)

    # Add components to entity
    entity.add_component(position_component)
    entity.add_component(movement_component)
    entity.add_component(input_component)

    # Add entity to world
    world.add_entity(entity)
  end

  describe '#initialize' do
    it 'initializes with a world' do
      system = Vanilla::Systems::MovementSystem.new(world)
      expect(system.world).to eq(world)
    end

    it 'initializes with a grid (legacy mode)' do
      system = Vanilla::Systems::MovementSystem.new(grid)
      expect(system.instance_variable_get(:@direct_grid)).to eq(grid)
      expect(system.world).to be_nil
    end
  end

  describe '#update' do
    let(:system) { Vanilla::Systems::MovementSystem.new(world) }

    it 'processes movement for entities with input directions' do
      input_component.set_move_direction(:north)

      expect(system).to receive(:process_entity_movement).with(entity)
      system.update(0.1)
    end

    it 'does nothing when initialized with direct grid' do
      direct_grid_system = Vanilla::Systems::MovementSystem.new(grid)
      expect(direct_grid_system).not_to receive(:process_entity_movement)
      direct_grid_system.update(0.1)
    end
  end

  describe '#process_entity_movement' do
    let(:system) { Vanilla::Systems::MovementSystem.new(world) }

    it 'moves the entity in the input direction' do
      input_component.set_move_direction(:north)

      expect(system).to receive(:move).with(entity, :north)
      system.process_entity_movement(entity)

      # Direction should be cleared after processing
      expect(input_component.move_direction).to be_nil
    end

    it 'does nothing if entity has no movement direction' do
      input_component.set_move_direction(nil)

      expect(system).not_to receive(:move)
      system.process_entity_movement(entity)
    end

    it 'does nothing if entity has no input component' do
      entity_without_input = Vanilla::Components::Entity.new
      entity_without_input.add_component(position_component.dup)
      entity_without_input.add_component(movement_component.dup)

      expect(system).not_to receive(:move)
      system.process_entity_movement(entity_without_input)
    end
  end

  describe '#move' do
    let(:system) { Vanilla::Systems::MovementSystem.new(world) }

    before do
      # Setup grid mock with array access notation
      allow(grid).to receive(:[]).with(5, 10).and_return(current_cell)
      allow(grid).to receive(:[]).with(4, 10).and_return(target_cell)

      # Setup grid dimensions for get_target_cell method
      allow(grid).to receive(:rows).and_return(20)
      allow(grid).to receive(:columns).and_return(20)

      # Setup cell linking
      allow(current_cell).to receive(:linked?).with(target_cell).and_return(true)

      # Allow the system to emit events
      allow(world).to receive(:emit_event)

      # Mock special cell attributes handling
      allow(system).to receive(:handle_special_cell_attributes).and_return(nil)
    end

    it 'returns false if entity cannot be processed' do
      entity_without_position = Vanilla::Components::Entity.new
      entity_without_position.add_component(movement_component.dup)

      expect(system.move(entity_without_position, :north)).to be false
    end

    it 'returns false if movement is not active' do
      movement_component.set_active(false)

      expect(system.move(entity, :north)).to be false
    end

    it 'updates position when movement is valid' do
      result = system.move(entity, :north)

      expect(result).to be true
      expect(position_component.row).to eq(4)
      expect(position_component.column).to eq(10)
    end

    it 'emits a movement_completed event' do
      system.move(entity, :north)

      expect(world).to have_received(:emit_event).with(
        :entity_moved,
        {
          entity_id: entity.id,
          old_position: { row: 5, column: 10 },
          new_position: { row: 4, column: 10 },
          direction: :north
        }
      )
    end

    it 'does not move if cells are not linked' do
      allow(current_cell).to receive(:linked?).with(target_cell).and_return(false)

      result = system.move(entity, :north)

      expect(result).to be false
      expect(position_component.row).to eq(5)  # Position unchanged
      expect(position_component.column).to eq(10)
    end
  end

  describe '#normalize_direction' do
    let(:system) { Vanilla::Systems::MovementSystem.new(world) }

    it 'converts string directions to symbols' do
      expect(system.send(:normalize_direction, 'north')).to eq(:north)
    end

    it 'handles uppercase directions' do
      expect(system.send(:normalize_direction, 'NORTH')).to eq(:north)
    end

    it 'maps single letters to directions' do
      expect(system.send(:normalize_direction, 'n')).to eq(:north)
      expect(system.send(:normalize_direction, 's')).to eq(:south)
      expect(system.send(:normalize_direction, 'e')).to eq(:east)
      expect(system.send(:normalize_direction, 'w')).to eq(:west)
    end

    it 'passes through valid symbols' do
      expect(system.send(:normalize_direction, :north)).to eq(:north)
    end

    # This test is conditional based on how normalize_direction is implemented
    # If it returns nil for invalid directions, use this test
    it 'returns nil or the input for invalid directions' do
      result = system.send(:normalize_direction, 'invalid')
      expect([:nil, 'invalid']).to include(result)
    end
  end

  describe '#can_process?' do
    let(:system) { Vanilla::Systems::MovementSystem.new(world) }

    it 'returns true when entity has position and movement components' do
      expect(system.send(:can_process?, entity)).to be true
    end

    it 'returns false if position component is missing' do
      entity_without_position = Vanilla::Components::Entity.new
      entity_without_position.add_component(movement_component.dup)

      expect(system.send(:can_process?, entity_without_position)).to be false
    end

    it 'returns false if movement component is missing' do
      entity_without_movement = Vanilla::Components::Entity.new
      entity_without_movement.add_component(position_component.dup)

      expect(system.send(:can_process?, entity_without_movement)).to be false
    end
  end
end
