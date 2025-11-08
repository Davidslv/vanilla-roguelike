# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Systems::MovementSystem do
  let(:world) { instance_double('Vanilla::World') }
  let(:system) { described_class.new(world) }
  let(:logger) { instance_double('Vanilla::Logger') }
  let(:grid) { Vanilla::MapUtils::Grid.new(5, 5) }
  let(:level) { instance_double('Vanilla::Level', grid: grid, entities: [], update_grid_with_entity: nil, update_grid_with_entities: nil) }
  let(:entity) do
    Vanilla::Entities::Entity.new.tap do |e|
      e.add_component(Vanilla::Components::PositionComponent.new(row: 2, column: 2))
      e.add_component(Vanilla::Components::MovementComponent.new(active: true))
      e.add_component(Vanilla::Components::InputComponent.new)
      e.add_component(Vanilla::Components::RenderComponent.new(character: '@', color: :white))
    end
  end

  before do
    allow(Vanilla::Logger).to receive(:instance).and_return(logger)
    allow(logger).to receive(:debug)
    allow(logger).to receive(:info)
    allow(logger).to receive(:error)
    allow(logger).to receive(:warn)
    allow(world).to receive(:current_level).and_return(level)
    allow(world).to receive(:entities).and_return({ entity.id => entity })
    allow(world).to receive(:query_entities).and_return([])
    allow(world).to receive(:emit_event)
    allow(level).to receive(:entities).and_return([])
  end

  describe '#initialize' do
    it 'initializes with world' do
      expect(system).to be_a(described_class)
    end
  end

  describe '#update' do
    it 'processes movement for entities with required components' do
      allow(world).to receive(:query_entities).with([:position, :movement, :input, :render]).and_return([entity])
      input = entity.get_component(:input)
      input.move_direction = :north

      # Link cells for movement
      current_cell = grid[2, 2]
      target_cell = grid[1, 2]
      current_cell.link(cell: target_cell, bidirectional: true)
      current_cell.tile = Vanilla::Support::TileType::FLOOR
      target_cell.tile = Vanilla::Support::TileType::FLOOR

      allow(system).to receive(:move).and_return(true)
      system.update(nil)
      expect(system).to have_received(:move).with(entity, :north)
    end

    it 'does not process entities without required components' do
      incomplete_entity = Vanilla::Entities::Entity.new
      allow(world).to receive(:query_entities).with([:position, :movement, :input, :render]).and_return([])
      system.update(nil)
      expect(system).not_to receive(:move)
    end
  end

  describe '#process_entity_movement' do
    it 'processes movement when direction is set' do
      input = entity.get_component(:input)
      input.move_direction = :south
      allow(system).to receive(:move).and_return(true)
      system.process_entity_movement(entity)
      expect(system).to have_received(:move).with(entity, :south)
    end

    it 'clears move_direction after successful movement' do
      input = entity.get_component(:input)
      input.move_direction = :east
      allow(system).to receive(:move).and_return(true)
      system.process_entity_movement(entity)
      expect(input.move_direction).to be_nil
    end

    it 'does not clear move_direction after failed movement' do
      input = entity.get_component(:input)
      input.move_direction = :west
      allow(system).to receive(:move).and_return(false)
      system.process_entity_movement(entity)
      expect(input.move_direction).to eq(:west)
    end

    it 'does nothing when direction is nil' do
      input = entity.get_component(:input)
      input.move_direction = nil
      system.process_entity_movement(entity)
      expect(system).not_to receive(:move)
    end
  end

  describe '#move' do
    before do
      # Set up linked cells
      current_cell = grid[2, 2]
      target_cell = grid[2, 3] # East
      current_cell.link(cell: target_cell, bidirectional: true)
      current_cell.tile = Vanilla::Support::TileType::FLOOR
      target_cell.tile = Vanilla::Support::TileType::FLOOR
      allow(level.entities).to receive(:clear)
      allow(level).to receive(:add_entity)
      allow(level).to receive(:update_grid_with_entities)
      allow(world).to receive(:entities).and_return({ entity.id => entity })
    end

    it 'moves entity to target cell when valid' do
      position = entity.get_component(:position)
      initial_row = position.row
      initial_col = position.column

      result = system.move(entity, :east)

      expect(result).to be true
      expect(position.row).to eq(initial_row)
      expect(position.column).to eq(initial_col + 1)
    end

    it 'returns false when movement component is not active' do
      inactive_entity = Vanilla::Entities::Entity.new.tap do |e|
        e.add_component(Vanilla::Components::PositionComponent.new(row: 2, column: 2))
        e.add_component(Vanilla::Components::MovementComponent.new(active: false))
        e.add_component(Vanilla::Components::InputComponent.new)
        e.add_component(Vanilla::Components::RenderComponent.new(character: '@', color: :white))
      end

      result = system.move(inactive_entity, :east)
      expect(result).to be false
    end

    it 'returns false when no grid exists' do
      allow(world).to receive(:current_level).and_return(nil)
      result = system.move(entity, :east)
      expect(result).to be false
    end

    it 'returns false when current cell is nil' do
      position = entity.get_component(:position)
      position.set_position(10, 10) # Out of bounds
      result = system.move(entity, :east)
      expect(result).to be false
    end

    it 'returns false when target cell is nil' do
      position = entity.get_component(:position)
      position.set_position(0, 0) # Edge of grid, no north neighbor
      result = system.move(entity, :north)
      expect(result).to be false
    end

    it 'returns false when cells are not linked' do
      # Unlink cells
      current_cell = grid[2, 2]
      target_cell = grid[2, 3]
      current_cell.unlink(cell: target_cell, bidirectional: true)

      result = system.move(entity, :east)
      expect(result).to be false
    end

    it 'returns false when target cell is not walkable' do
      target_cell = grid[2, 3]
      target_cell.tile = Vanilla::Support::TileType::WALL

      result = system.move(entity, :east)
      expect(result).to be false
    end

    it 'emits entity_moved event on successful movement' do
      expect(world).to receive(:emit_event).with(:entity_moved, hash_including(
        entity_id: entity.id,
        direction: :east
      ))
      system.move(entity, :east)
    end

    it 'updates grid with entity after movement' do
      expect(level).to receive(:update_grid_with_entity).with(entity)
      system.move(entity, :east)
    end

    it 'handles errors gracefully' do
      allow(grid).to receive(:[]).and_raise(StandardError.new("Test error"))
      result = system.move(entity, :east)
      expect(result).to be false
    end
  end

  describe 'private methods' do
    describe '#get_target_cell' do
      it 'returns north cell for :north direction' do
        cell = grid[2, 2]
        target = system.send(:get_target_cell, cell, :north)
        expect(target).to eq(cell.north)
      end

      it 'returns south cell for :south direction' do
        cell = grid[2, 2]
        target = system.send(:get_target_cell, cell, :south)
        expect(target).to eq(cell.south)
      end

      it 'returns east cell for :east direction' do
        cell = grid[2, 2]
        target = system.send(:get_target_cell, cell, :east)
        expect(target).to eq(cell.east)
      end

      it 'returns west cell for :west direction' do
        cell = grid[2, 2]
        target = system.send(:get_target_cell, cell, :west)
        expect(target).to eq(cell.west)
      end

      it 'returns nil for invalid direction' do
        cell = grid[2, 2]
        target = system.send(:get_target_cell, cell, :invalid)
        expect(target).to be_nil
      end
    end

    describe '#can_move_to?' do
      it 'returns true when cells are linked and walkable' do
        current = grid[2, 2]
        target = grid[2, 3]
        current.link(cell: target, bidirectional: true)
        current.tile = Vanilla::Support::TileType::FLOOR
        target.tile = Vanilla::Support::TileType::FLOOR

        result = system.send(:can_move_to?, current, target, :east)
        expect(result).to be true
      end

      it 'returns false when cells are not linked' do
        current = grid[2, 2]
        target = grid[2, 3]
        current.tile = Vanilla::Support::TileType::FLOOR
        target.tile = Vanilla::Support::TileType::FLOOR

        result = system.send(:can_move_to?, current, target, :east)
        expect(result).to be false
      end

      it 'returns false when target is not walkable' do
        current = grid[2, 2]
        target = grid[2, 3]
        current.link(cell: target, bidirectional: true)
        current.tile = Vanilla::Support::TileType::FLOOR
        target.tile = Vanilla::Support::TileType::WALL

        result = system.send(:can_move_to?, current, target, :east)
        expect(result).to be false
      end
    end
  end
end

