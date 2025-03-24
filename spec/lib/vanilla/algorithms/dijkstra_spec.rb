# frozen_string_literal: true
require 'spec_helper'
require 'vanilla/algorithms/dijkstra'
require 'vanilla/map_utils/grid'

RSpec.describe Vanilla::Algorithms::Dijkstra do
  describe '.on' do
    let(:grid) { Vanilla::MapUtils::Grid.new(rows: 3, columns: 3) }
    let(:start_cell) { grid[0, 0] }
    let(:goal_cell) { grid[2, 2] }

    # Create a simple maze where all cells are connected in a grid pattern
    before do
      grid.each_cell do |cell|
        cell.link(cell: cell.east) if cell.east
        cell.link(cell: cell.south) if cell.south
      end
    end

    it 'returns the grid with distances calculated' do
      result = described_class.on(grid, start: start_cell)

      expect(result).to eq(grid)
      expect(grid.distances).not_to be_nil
    end

    it 'calculates distances to all cells from start when no goal is provided' do
      described_class.on(grid, start: start_cell)

      # All cells should be reachable
      grid.each_cell do |cell|
        expect(grid.distances[cell]).not_to be_nil
      end
    end

    it 'calculates the shortest path to the goal cell when provided' do
      described_class.on(grid, start: start_cell, goal: goal_cell)

      # The path should be calculated
      expect(grid.distances[goal_cell]).not_to be_nil

      # In a simple grid with all connections, the distance should be the Manhattan distance
      expected_distance = (goal_cell.row - start_cell.row) + (goal_cell.column - start_cell.column)
      expect(grid.distances[goal_cell]).to eq(expected_distance)
    end
  end

  # Test with mock objects
  describe 'with mocks' do
    let(:grid) { instance_double('Vanilla::MapUtils::Grid') }
    let(:start_cell) { instance_double('Vanilla::MapUtils::Cell') }
    let(:goal_cell) { instance_double('Vanilla::MapUtils::Cell') }
    let(:distances) { instance_double('Vanilla::MapUtils::Distances') }
    let(:path_distances) { instance_double('Vanilla::MapUtils::Distances') }

    before do
      allow(start_cell).to receive(:distances).and_return(distances)
      allow(distances).to receive(:path_to).with(goal_cell).and_return(path_distances)
      allow(path_distances).to receive(:cells).and_return([start_cell, goal_cell])
      allow(grid).to receive(:distances=)
    end

    it 'calculates distances using the start cell' do
      expect(start_cell).to receive(:distances)

      described_class.on(grid, start: start_cell)
    end

    it 'finds the path to the goal when provided' do
      expect(distances).to receive(:path_to).with(goal_cell)

      described_class.on(grid, start: start_cell, goal: goal_cell)
    end

    it 'returns the cells in the path for shortest_path' do
      expect(path_distances).to receive(:cells)

      result = described_class.shortest_path(grid, start: start_cell, goal: goal_cell)
      expect(result).to eq([start_cell, goal_cell])
    end
  end
end
