require 'spec_helper'
require 'vanilla/draw'

RSpec.describe Vanilla::Draw do
  let(:logger) { instance_double('Vanilla::Logger') }
  let(:grid) { instance_double("Vanilla::MapUtils::Grid", rows: 10, columns: 10) }
  let(:terminal_output) { instance_double("Vanilla::Output::Terminal", to_s: "grid output") }
  let(:cell) { instance_double("Vanilla::MapUtils::Cell") }

  before do
    allow(Vanilla::Logger).to receive(:instance).and_return(logger)
    allow(logger).to receive(:info)
    allow(logger).to receive(:debug)
    allow(logger).to receive(:warn)
    allow(Vanilla::Output::Terminal).to receive(:new).with(grid, open_maze: true).and_return(terminal_output)
    allow(STDOUT).to receive(:puts)
    allow(Kernel).to receive(:system).and_return(true)
    $seed = nil
  end

  describe '.map' do
    it 'clears the screen and displays the grid' do
      expect(Kernel).to receive(:system).with("clear")
      expect(Vanilla::Output::Terminal).to receive(:new).with(grid, open_maze: true).and_return(terminal_output)
      expect(STDOUT).to receive(:puts).at_least(:once)

      described_class.map(grid)
    end
  end

  describe '.tile' do
    it 'sets the tile on the cell and updates the display' do
      allow(grid).to receive(:[]).with(5, 10).and_return(cell)
      allow(cell).to receive(:tile=)

      expect(described_class).to receive(:map).with(grid)

      described_class.tile(grid: grid, row: 5, column: 10, tile: Vanilla::Support::TileType::PLAYER)
    end
  end

  describe '.player' do
    let(:player) do
      player = Vanilla::Components::Entity.new
      player.add_component(Vanilla::Components::PositionComponent.new(row: 5, column: 10))
      player.add_component(Vanilla::Components::TileComponent.new(tile: Vanilla::Support::TileType::PLAYER))
      player
    end

    it 'calls tile with the players position and tile' do
      expect(described_class).to receive(:tile).with(
        grid: grid,
        row: 5,
        column: 10,
        tile: Vanilla::Support::TileType::PLAYER
      )

      described_class.player(grid: grid, unit: player)
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
    let(:player) do
      player = Vanilla::Components::Entity.new
      player.add_component(Vanilla::Components::PositionComponent.new(row: 5, column: 10))
      player.add_component(Vanilla::Components::MovementComponent.new)
      player.add_component(Vanilla::Components::TileComponent.new(tile: Vanilla::Support::TileType::PLAYER))
      player
    end

    let(:movement_system) { instance_double("Vanilla::Systems::MovementSystem") }
    let(:old_cell) { instance_double("Vanilla::MapUtils::Cell") }

    before do
      allow(Vanilla::Systems::MovementSystem).to receive(:new).with(grid).and_return(movement_system)
      allow(grid).to receive(:[]).with(5, 10).and_return(old_cell)
      allow(old_cell).to receive(:tile=)
    end

    it 'uses the movement system to move the player' do
      position = player.get_component(:position)

      # Mock successful movement that changes position
      allow(movement_system).to receive(:move) do |entity, direction|
        expect(entity).to eq(player)
        expect(direction).to eq(:up)

        # Simulate movement
        position.row = 4
        true
      end

      expect(described_class).to receive(:player).with(grid: grid, unit: player)
      expect(described_class).to receive(:map).with(grid)

      described_class.movement(grid: grid, unit: player, direction: :up)
    end
  end
end
