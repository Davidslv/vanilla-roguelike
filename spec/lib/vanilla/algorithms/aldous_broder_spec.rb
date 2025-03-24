# frozen_string_literal: true
require 'spec_helper'
require 'vanilla/algorithms/aldous_broder'
require 'vanilla/map_utils/grid'

RSpec.describe Vanilla::Algorithms::AldousBroder do
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

    it 'preserves all cells in the grid' do
      cell_count_before = 0
      grid.each_cell { |_| cell_count_before += 1 }
      
      result = described_class.on(grid)
      
      cell_count_after = 0
      result.each_cell { |_| cell_count_after += 1 }
      
      expect(cell_count_after).to eq(cell_count_before)
    end
  end
end
