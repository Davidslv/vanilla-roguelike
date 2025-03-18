require 'spec_helper'
require 'vanilla/draw'

RSpec.describe Vanilla::Draw do
  let(:grid) { instance_double('Vanilla::MapUtils::Grid') }
  let(:cell) { instance_double('Vanilla::MapUtils::Cell') }
  let(:output) { instance_double('Vanilla::Output::Terminal') }

  before do
    allow(Vanilla::Output::Terminal).to receive(:new).and_return(output)
    allow(output).to receive(:to_s).and_return("grid output")
    allow(grid).to receive(:[]).and_return(cell)
    allow(cell).to receive(:tile=)
    allow(grid).to receive(:rows).and_return(10)
    allow(grid).to receive(:columns).and_return(20)
  end

  describe '.map' do
    before do
      # Stub puts to avoid actual output
      allow(described_class).to receive(:puts)
      allow(described_class).to receive(:system)
      $seed = 12345
    end

    it 'clears the screen and displays the grid' do
      expect(described_class).to receive(:system).with("clear")

      # We don't care about the exact order of puts calls
      expect(described_class).to receive(:puts).with("Seed: 12345 | Rows: 10 | Columns: 20")
      expect(described_class).to receive(:puts).with("-" * 35)
      expect(described_class).to receive(:puts).with("\n\n")
      expect(described_class).to receive(:puts).with(output)

      described_class.map(grid)
    end
  end

  describe '.tile' do
    before do
      allow(described_class).to receive(:map)
    end

    it 'sets the tile for a cell' do
      expect(grid).to receive(:[]).with(5, 10).and_return(cell)
      expect(cell).to receive(:tile=).with('@')
      expect(described_class).to receive(:map).with(grid)

      described_class.tile(grid: grid, row: 5, column: 10, tile: '@')
    end

    it 'raises an error for invalid tile types' do
      expect {
        described_class.tile(grid: grid, row: 5, column: 10, tile: 'X')
      }.to raise_error(ArgumentError, 'Invalid tile type')
    end
  end

  describe '.player' do
    before do
      allow(described_class).to receive(:tile)
    end

    context 'with a legacy unit' do
      let(:unit) { instance_double('Vanilla::Unit', row: 5, column: 10, tile: '@') }

      it 'draws the player at their position' do
        expect(described_class).to receive(:tile).with(
          grid: grid,
          row: 5,
          column: 10,
          tile: '@'
        )

        described_class.player(grid: grid, unit: unit)
      end
    end

    context 'with an entity' do
      let(:player) { Vanilla::Entities::Player.new(row: 5, column: 10) }

      it 'draws the player at their position' do
        expect(described_class).to receive(:tile).with(
          grid: grid,
          row: 5,
          column: 10,
          tile: Vanilla::Support::TileType::PLAYER
        )

        described_class.player(grid: grid, unit: player)
      end
    end
  end

  describe '.stairs' do
    before do
      allow(described_class).to receive(:tile)
    end

    it 'draws stairs at the specified position' do
      expect(described_class).to receive(:tile).with(
        grid: grid,
        row: 5,
        column: 10,
        tile: Vanilla::Support::TileType::STAIRS
      )

      described_class.stairs(grid: grid, row: 5, column: 10)
    end
  end

  describe '.movement' do
    before do
      allow(described_class).to receive(:map)
    end

    context 'with a legacy unit' do
      let(:unit) { instance_double('Vanilla::Unit', row: 5, column: 10, tile: '@') }

      it 'processes movement and redraws the map' do
        expect(Vanilla::Movement).to receive(:move).with(
          grid: grid,
          unit: unit,
          direction: :up
        )
        expect(described_class).to receive(:map).with(grid)

        described_class.movement(grid: grid, unit: unit, direction: :up)
      end
    end

    context 'with an entity' do
      let(:player) { Vanilla::Entities::Player.new(row: 5, column: 10) }

      it 'processes movement and redraws the map' do
        expect(Vanilla::Movement).to receive(:move).with(
          grid: grid,
          unit: player,
          direction: :up
        )
        expect(described_class).to receive(:map).with(grid)

        described_class.movement(grid: grid, unit: player, direction: :up)
      end
    end
  end
end
