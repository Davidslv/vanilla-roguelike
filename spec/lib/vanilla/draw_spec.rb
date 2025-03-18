require 'spec_helper'
require 'vanilla/draw'

RSpec.describe Vanilla::Draw do
  let(:grid) { instance_double('Vanilla::MapUtils::Grid') }
  let(:cell) { instance_double('Vanilla::MapUtils::Cell') }
  let(:logger) { instance_double('Vanilla::Logger') }

  before do
    allow(Vanilla::Logger).to receive(:instance).and_return(logger)
    allow(logger).to receive(:info)
    allow(logger).to receive(:debug)
    allow(logger).to receive(:warn)
  end

  describe '.map' do
    let(:terminal_output) { instance_double('Vanilla::Output::Terminal', to_s: "Map Content") }

    before do
      allow(grid).to receive(:rows).and_return(10)
      allow(grid).to receive(:columns).and_return(10)
      allow(Vanilla::Output::Terminal).to receive(:new).with(grid, open_maze: true).and_return(terminal_output)
      # Stub system and puts to prevent actual execution
      allow(Kernel).to receive(:system)
      allow_any_instance_of(Object).to receive(:puts)
      $seed = nil
    end

    it 'creates the terminal output with the grid' do
      # Just verify that the terminal output is created correctly
      expect(Vanilla::Output::Terminal).to receive(:new).with(grid, open_maze: true).and_return(terminal_output)

      described_class.map(grid)
    end
  end

  describe '.tile' do
    before do
      allow(grid).to receive(:[]).with(5, 5).and_return(cell)
      allow(cell).to receive(:tile=)
      allow(described_class).to receive(:map)
    end

    it 'sets the tile for a cell' do
      expect(cell).to receive(:tile=).with(Vanilla::Support::TileType::PLAYER)
      described_class.tile(grid: grid, row: 5, column: 5, tile: Vanilla::Support::TileType::PLAYER)
    end

    it 'raises an error for invalid tile types' do
      expect {
        described_class.tile(grid: grid, row: 5, column: 5, tile: 'X')
      }.to raise_error(ArgumentError, 'Invalid tile type')
    end
  end

  describe '.player' do
    context 'with a legacy-compatible entity' do
      # Create a real entity with components instead of a mock
      let(:unit) do
        entity = Vanilla::Components::Entity.new
        entity.add_component(Vanilla::Components::PositionComponent.new(row: 5, column: 10))
        entity.add_component(Vanilla::Components::TileComponent.new(tile: '@'))
        entity
      end

      before do
        # Make the entity appear as a legacy object
        allow(unit).to receive(:respond_to?).with(:has_component?).and_return(false)
        allow(described_class).to receive(:tile)
      end

      it 'draws the player at their position' do
        expect(described_class).to receive(:tile).with(grid: grid, row: 5, column: 10, tile: '@')
        described_class.player(grid: grid, unit: unit)
      end
    end

    context 'with an entity' do
      let(:player) { Vanilla::Entities::Player.new(row: 5, column: 10) }

      before do
        allow(described_class).to receive(:tile)
      end

      it 'draws the player at their position' do
        expect(described_class).to receive(:tile).with(grid: grid, row: 5, column: 10, tile: '@')
        described_class.player(grid: grid, unit: player)
      end
    end
  end

  describe '.stairs' do
    before do
      allow(described_class).to receive(:tile)
    end

    it 'draws stairs at the specified position' do
      expect(described_class).to receive(:tile).with(grid: grid, row: 5, column: 5, tile: Vanilla::Support::TileType::STAIRS)
      described_class.stairs(grid: grid, row: 5, column: 5)
    end
  end

  describe '.movement' do
    context 'with a legacy-compatible entity' do
      # Create a real entity with components instead of a mock
      let(:unit) do
        entity = Vanilla::Components::Entity.new
        entity.add_component(Vanilla::Components::PositionComponent.new(row: 5, column: 10))
        entity.add_component(Vanilla::Components::TileComponent.new(tile: '@'))
        entity
      end
      let(:movement_system) { instance_double('Vanilla::Systems::MovementSystem') }

      before do
        # Make the entity appear as a legacy object
        allow(unit).to receive(:respond_to?).with(:has_component?).and_return(false)
        allow(Vanilla::Systems::MovementSystem).to receive(:new).with(grid).and_return(movement_system)
        allow(movement_system).to receive(:move)
        allow(described_class).to receive(:player)
        allow(described_class).to receive(:map)
        allow(grid).to receive(:[]).with(5, 10).and_return(cell)
        allow(cell).to receive(:tile=)
      end

      it 'uses the movement system directly' do
        expect(movement_system).to receive(:move).with(unit, :up)
        described_class.movement(grid: grid, unit: unit, direction: :up)
      end
    end

    context 'with an entity' do
      let(:player) { Vanilla::Entities::Player.new(row: 5, column: 10) }
      let(:movement_system) { instance_double('Vanilla::Systems::MovementSystem') }

      before do
        allow(Vanilla::Systems::MovementSystem).to receive(:new).with(grid).and_return(movement_system)
        allow(movement_system).to receive(:move)
        allow(described_class).to receive(:player)
        allow(described_class).to receive(:map)
        allow(grid).to receive(:[]).with(5, 10).and_return(cell)
        allow(cell).to receive(:tile=)
      end

      it 'uses the movement system directly' do
        expect(movement_system).to receive(:move).with(player, :up)
        described_class.movement(grid: grid, unit: player, direction: :up)
      end
    end
  end
end
