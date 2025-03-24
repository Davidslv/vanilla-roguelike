require 'spec_helper'
require 'vanilla/algorithms/recursive_backtracker'
require 'vanilla/map_utils/grid'

RSpec.describe Vanilla::Algorithms::RecursiveBacktracker do
  describe '.on' do
    let(:grid) { Vanilla::MapUtils::Grid.new(rows: 5, columns: 5) }

    it 'returns the modified grid' do
      result = described_class.on(grid)
      expect(result).to eq(grid)
    end

    it 'creates a fully connected maze' do
      result = described_class.on(grid)
      
      # Choose a starting cell
      start = result[0, 0]
      
      # Use distances to verify connectivity
      distances = start.distances
      
      # Every cell should be reachable from the starting cell
      result.each_cell do |cell|
        expect(distances[cell]).not_to be_nil
      end
    end

    it 'ensures all cells have at least one link' do
      result = described_class.on(grid)
      
      result.each_cell do |cell|
        expect(cell.links).not_to be_empty
      end
    end

    it 'inherits from AbstractAlgorithm' do
      expect(described_class).to be < Vanilla::Algorithms::AbstractAlgorithm
    end

    it 'creates paths with correct neighbor relationships' do
      result = described_class.on(grid)
      
      result.each_cell do |cell|
        cell.links.each do |linked_cell|
          # Each linked cell should be a neighbor of the current cell
          expect(cell.neighbors).to include(linked_cell)
        end
      end
    end
  end
end
