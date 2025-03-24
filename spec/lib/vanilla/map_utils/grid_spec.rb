# frozen_string_literal: true

require 'spec_helper'
require 'vanilla/map_utils/grid'

RSpec.describe Vanilla::MapUtils::Grid do
  describe '#initialize' do
    it 'creates a grid with the specified number of rows and columns' do
      rows = 5
      columns = 7
      grid = described_class.new(rows: rows, columns: columns)

      expect(grid.rows).to eq(rows)
      expect(grid.columns).to eq(columns)
    end

    it 'raises an ArgumentError when rows is less than 1' do
      expect { described_class.new(rows: 0, columns: 5) }.to raise_error(ArgumentError, "Rows must be greater than 0")
    end

    it 'raises an ArgumentError when columns is less than 1' do
      expect { described_class.new(rows: 5, columns: 0) }.to raise_error(ArgumentError, "Columns must be greater than 0")
    end

    it 'initializes cells as instances of Vanilla::MapUtils::Cell' do
      grid = described_class.new(rows: 3, columns: 3)

      grid.each_cell do |cell|
        expect(cell).to be_an_instance_of(Vanilla::MapUtils::Cell)
      end
    end

    it 'sets correct row and column values for each cell' do
      grid = described_class.new(rows: 2, columns: 2)

      expect(grid[0, 0].row).to eq(0)
      expect(grid[0, 0].column).to eq(0)
      expect(grid[1, 1].row).to eq(1)
      expect(grid[1, 1].column).to eq(1)
    end

    it 'correctly sets neighboring cells' do
      grid = described_class.new(rows: 3, columns: 3)
      center_cell = grid[1, 1]

      expect(center_cell.north).to eq(grid[0, 1])
      expect(center_cell.south).to eq(grid[2, 1])
      expect(center_cell.east).to eq(grid[1, 2])
      expect(center_cell.west).to eq(grid[1, 0])
    end
  end

  describe '[]' do
    it 'returns the cell at the specified row and column' do
      grid = described_class.new(rows: 3, columns: 3)
      cell = grid[1, 1]
      expect(cell).to be_an_instance_of(Vanilla::MapUtils::Cell)
    end

    it 'returns nil if the row is out of bounds' do
      grid = described_class.new(rows: 3, columns: 3)
      expect(grid[3, 0]).to be_nil
    end

    it 'returns nil if the column is out of bounds' do
      grid = described_class.new(rows: 3, columns: 3)
      expect(grid[0, 3]).to be_nil
    end
  end

  describe 'size' do
    it 'returns the total number of cells in the grid' do
      grid = described_class.new(rows: 3, columns: 3)
      expect(grid.size).to eq(9)
    end
  end

  describe 'contents_of' do
    it 'returns the correct content for a cell' do
      grid = described_class.new(rows: 3, columns: 3)
      cell = grid[1, 1]
      expect(grid.contents_of(cell)).to eq(" ")
    end

    it 'returns the correct content for a cell with a player' do
      grid = described_class.new(rows: 3, columns: 3)
      cell = grid[1, 1]
      cell.tile = Vanilla::Support::TileType::PLAYER
      expect(grid.contents_of(cell)).to eq(Vanilla::Support::TileType::PLAYER)
    end
  end

  describe 'dead_ends' do
    it 'marks cells with a single link as dead ends' do
      grid = described_class.new(rows: 3, columns: 3)
      cell = grid[1, 1]
      cell.link(cell: grid[1, 0])
      grid.dead_ends

      expect(cell.dead_end).to be_truthy
    end

    it 'does not mark cells with multiple links as dead ends' do
      grid = described_class.new(rows: 3, columns: 3)
      cell = grid[1, 1]
      cell.link(cell: grid[1, 0])
      cell.link(cell: grid[1, 2])

      grid.dead_ends

      expect(cell.dead_end).to be_falsey
    end
  end
end
