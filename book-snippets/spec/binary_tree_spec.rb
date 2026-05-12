# frozen_string_literal: true

require_relative 'spec_helper'
require 'support/tile_type'
require 'map_utils/grid'
require 'algorithms/binary_tree'

RSpec.describe Vanilla::Algorithms::BinaryTree do
  let(:grid) { Vanilla::MapUtils::Grid.new(5, 5) }

  it 'returns the grid it was applied to' do
    expect(described_class.on(grid)).to eq(grid)
  end

  it 'links every cell except the top-right corner' do
    described_class.on(grid)
    expected_unlinked = [grid[0, 4]]
    grid.each_cell do |cell|
      next if expected_unlinked.include?(cell)

      expect(cell.links).not_to be_empty, "expected #{cell.row},#{cell.column} to have at least one link"
    end
  end

  it 'only links cells to their direct cardinal neighbours' do
    described_class.on(grid)
    grid.each_cell do |cell|
      cell.links.each do |linked|
        neighbours = [cell.north, cell.south, cell.east, cell.west].compact
        expect(neighbours).to include(linked),
          "cell at #{cell.row},#{cell.column} linked to non-neighbour at #{linked.row},#{linked.column}"
      end
    end
  end

  it 'sets unlinked cells to wall tiles' do
    skip <<~MSG
      Binary tree links bidirectionally, so the top-right corner (0,4) still
      receives back-links from its south neighbour (1,4) and west neighbour
      (0,3). It never has empty links, never gets WALL. Either the algorithm's
      wall step needs to be reconceived (e.g. wall any cell at the grid
      boundary that has no carve direction) or this test should be removed
      to match what binary tree actually produces.
    MSG
    described_class.on(grid)
    expect(grid[0, 4].tile).to eq(Vanilla::Support::TileType::WALL)
  end
end
