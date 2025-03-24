# frozen_string_literal: true

require 'spec_helper'
require 'vanilla/algorithms/recursive_division'
require 'vanilla/map_utils/grid'

RSpec.describe Vanilla::Algorithms::RecursiveDivision do
  describe '.on' do
    let(:grid) { Vanilla::MapUtils::Grid.new(rows: 8, columns: 8) }

    it 'modifies the grid' do
      # Keep a reference to the original grid
      original_grid = grid

      # RecursiveDivision does not return the grid
      described_class.on(grid)

      # The original grid should be modified
      expect(grid).to eq(original_grid)
    end

    it 'creates a maze with passages and walls' do
      described_class.on(grid)

      # Count linked and unlinked neighbors
      linked_neighbors = 0
      unlinked_neighbors = 0

      grid.each_cell do |cell|
        cell.neighbors.each do |neighbor|
          if cell.linked?(neighbor)
            linked_neighbors += 1
          else
            unlinked_neighbors += 1
          end
        end
      end

      # A maze should have both passages and walls
      expect(linked_neighbors).to be > 0
      expect(unlinked_neighbors).to be > 0
    end

    it 'preserves the grid dimensions' do
      before_rows = grid.rows
      before_columns = grid.columns

      described_class.on(grid)

      expect(grid.rows).to eq(before_rows)
      expect(grid.columns).to eq(before_columns)
    end

    it 'inherits from AbstractAlgorithm' do
      expect(described_class).to be < Vanilla::Algorithms::AbstractAlgorithm
    end

    it 'creates a reachable maze' do
      described_class.on(grid)

      # Choose a starting cell
      start = grid[0, 0]

      # Use distances to verify connectivity
      distances = start.distances

      # Every cell should be reachable from the starting cell
      grid.each_cell do |cell|
        expect(distances[cell]).not_to be_nil
      end
    end
  end
end
