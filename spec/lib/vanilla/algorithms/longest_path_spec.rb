# frozen_string_literal: true

require 'spec_helper'
require 'vanilla/algorithms/longest_path'
require 'vanilla/map_utils/grid'

RSpec.describe Vanilla::Algorithms::LongestPath do
  describe '.on' do
    let(:grid) { Vanilla::MapUtils::Grid.new(rows: 5, columns: 5) }
    let(:start_cell) { grid[0, 0] }

    # We need to create some links to find paths
    before do
      # Use binary tree to create a maze with paths
      Vanilla::Algorithms::BinaryTree.on(grid)
    end

    it 'returns the grid with distances set' do
      result = described_class.on(grid, start: start_cell)
      
      expect(result).to eq(grid)
      expect(grid.distances).not_to be_nil
    end

    it 'sets distances on the grid' do
      described_class.on(grid, start: start_cell)
      
      expect(grid.distances).not_to be_nil
    end

    it 'inherits from AbstractAlgorithm' do
      expect(described_class).to be < Vanilla::Algorithms::AbstractAlgorithm
    end

    it 'calculates the longest path from the start cell' do
      described_class.on(grid, start: start_cell)
      
      # The grid's distances should be a path
      expect(grid.distances).to respond_to(:path_to)
      
      # The path should connect cells
      path_cells = grid.distances.cells
      expect(path_cells.size).to be > 0
      
      # Each cell in the path should be linked to at least one other cell in the path
      # (Except potentially the endpoints)
      path_cells.each do |cell|
        linked_path_neighbors = cell.links.select { |link| path_cells.include?(link) }
        
        # Either it's an endpoint with 1 connection, or it has 2 connections to other path cells
        expect([1, 2]).to include(linked_path_neighbors.size) unless cell == path_cells.first
      end
    end
  end
end
