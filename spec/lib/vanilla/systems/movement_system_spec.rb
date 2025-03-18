require 'spec_helper'

RSpec.describe Vanilla::Systems::MovementSystem do
  let(:grid) { instance_double('Vanilla::MapUtils::Grid') }
  let(:entity) { Vanilla::Components::Entity.new }
  let(:position_component) { Vanilla::Components::PositionComponent.new(row: 5, column: 5) }
  let(:movement_component) { Vanilla::Components::MovementComponent.new }
  let(:system) { described_class.new(grid) }
  let(:logger) { instance_double('Vanilla::Logger', info: nil, debug: nil) }

  before do
    allow(Vanilla::Logger).to receive(:instance).and_return(logger)
    entity.add_component(position_component)
    entity.add_component(movement_component)
  end

  describe '#initialize' do
    it 'stores the grid reference' do
      expect(system.instance_variable_get(:@grid)).to eq(grid)
    end

    it 'gets a logger instance' do
      expect(system.instance_variable_get(:@logger)).to eq(logger)
    end
  end

  describe '#move' do
    let(:current_cell) { instance_double('Vanilla::MapUtils::Cell', row: 5, column: 5) }
    let(:north_cell) { instance_double('Vanilla::MapUtils::Cell', row: 4, column: 5) }
    let(:south_cell) { instance_double('Vanilla::MapUtils::Cell', row: 6, column: 5) }
    let(:east_cell) { instance_double('Vanilla::MapUtils::Cell', row: 5, column: 6) }
    let(:west_cell) { instance_double('Vanilla::MapUtils::Cell', row: 5, column: 4) }

    before do
      allow(grid).to receive(:[]).with(5, 5).and_return(current_cell)
      allow(current_cell).to receive(:north).and_return(north_cell)
      allow(current_cell).to receive(:south).and_return(south_cell)
      allow(current_cell).to receive(:east).and_return(east_cell)
      allow(current_cell).to receive(:west).and_return(west_cell)

      allow(current_cell).to receive(:linked?).with(north_cell).and_return(true)
      allow(current_cell).to receive(:linked?).with(south_cell).and_return(true)
      allow(current_cell).to receive(:linked?).with(east_cell).and_return(true)
      allow(current_cell).to receive(:linked?).with(west_cell).and_return(true)

      allow(north_cell).to receive(:stairs?).and_return(false)
      allow(south_cell).to receive(:stairs?).and_return(false)
      allow(east_cell).to receive(:stairs?).and_return(false)
      allow(west_cell).to receive(:stairs?).and_return(false)
    end

    context 'when entity has required components' do
      it 'moves the entity north' do
        system.move(entity, :north)
        expect(position_component.row).to eq(4)
        expect(position_component.column).to eq(5)
      end

      it 'moves the entity south' do
        system.move(entity, :south)
        expect(position_component.row).to eq(6)
        expect(position_component.column).to eq(5)
      end

      it 'moves the entity east' do
        system.move(entity, :east)
        expect(position_component.row).to eq(5)
        expect(position_component.column).to eq(6)
      end

      it 'moves the entity west' do
        system.move(entity, :west)
        expect(position_component.row).to eq(5)
        expect(position_component.column).to eq(4)
      end
    end

    context 'when entity is missing required components' do
      it 'does not move the entity without position component' do
        entity.remove_component(:position)
        system.move(entity, :north)
        expect(entity.has_component?(:position)).to be false
      end

      it 'does not move the entity without movement component' do
        entity.remove_component(:movement)
        system.move(entity, :north)
        expect(entity.has_component?(:movement)).to be false
      end
    end

    context 'when movement is blocked' do
      before do
        allow(current_cell).to receive(:linked?).with(north_cell).and_return(false)
      end

      it 'does not move the entity when path is blocked' do
        system.move(entity, :north)
        expect(position_component.row).to eq(5)
        expect(position_component.column).to eq(5)
      end
    end

    context 'when direction is restricted' do
      before do
        movement_component.can_move_directions = [:east, :west]
      end

      it 'does not move in restricted directions' do
        system.move(entity, :north)
        expect(position_component.row).to eq(5)
        expect(position_component.column).to eq(5)
      end

      it 'moves in allowed directions' do
        system.move(entity, :east)
        expect(position_component.row).to eq(5)
        expect(position_component.column).to eq(6)
      end
    end

    context 'when stairs are found' do
      let(:stairs_component) { Vanilla::Components::StairsComponent.new }

      before do
        entity.add_component(stairs_component)
        allow(east_cell).to receive(:stairs?).and_return(true)
      end

      it 'updates stairs component when stairs are found' do
        system.move(entity, :east)
        expect(stairs_component.found_stairs).to be true
      end
    end
  end
end