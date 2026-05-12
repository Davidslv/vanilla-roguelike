# frozen_string_literal: true

require_relative 'spec_helper'
require 'map_utils/grid'

RSpec.describe Vanilla::MapUtils::Grid do
  subject(:grid) { described_class.new(3, 4) }

  it 'exposes its dimensions' do
    expect(grid.rows).to eq(3)
    expect(grid.columns).to eq(4)
    expect(grid.size).to eq(12)
  end

  it 'returns the cell at a valid position' do
    cell = grid[1, 2]
    expect(cell).not_to be_nil
    expect(cell.row).to eq(1)
    expect(cell.column).to eq(2)
  end

  it 'returns nil for out-of-bounds indices' do
    expect(grid[-1, 0]).to be_nil
    expect(grid[3, 0]).to be_nil
    expect(grid[0, 4]).to be_nil
  end

  it 'wires up neighbours' do
    cell = grid[1, 1]
    expect(cell.north).to eq(grid[0, 1])
    expect(cell.south).to eq(grid[2, 1])
    expect(cell.east).to eq(grid[1, 2])
    expect(cell.west).to eq(grid[1, 0])
  end

  it 'leaves edge cells without neighbours on the boundary side' do
    expect(grid[0, 0].north).to be_nil
    expect(grid[0, 0].west).to be_nil
  end

  it 'iterates over every cell' do
    seen = []
    grid.each_cell { |cell| seen << cell }
    expect(seen.size).to eq(12)
  end
end
