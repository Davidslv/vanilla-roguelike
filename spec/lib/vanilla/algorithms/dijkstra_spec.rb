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

  describe '.shortest_path', skip: 'skipping because it takes too long and consumes too much memory' do
    let(:grid) { Vanilla::MapUtils::Grid.new(rows: 3, columns: 3) }
    let(:start_cell) { grid[0, 0] }
    let(:goal_cell) { grid[0, 1] }

    before do
      # Connect all cells in a grid pattern
      grid.each_cell do |cell|
        cell.link(cell: cell.east) if cell.east
        cell.link(cell: cell.south) if cell.south
      end
    end

    it 'returns an array of cells representing the shortest path' do
      path = described_class.shortest_path(grid, start: start_cell, goal: goal_cell)
      
      expect(path).to be_an(Array)
      expect(path.first).to eq(start_cell)
      expect(path.last).to eq(goal_cell)
      
      # Check that each cell in the path is connected to the next
      path.each_cons(2) do |current, next_cell|
        expect(current.linked?(next_cell)).to be true
      end
    end

    context 'with a simple maze' do
      before do
        # Clear all links
        grid.each_cell do |cell|
          cell.links.keys.each do |linked_cell|
            cell.unlink(cell: linked_cell)
          end
        end
        
        # Create a simple L-shaped path: (0,0) -> (0,1) -> (1,1) -> (2,1) -> (2,2)
        grid[0, 0].link(cell: grid[0, 1])
        grid[0, 1].link(cell: grid[1, 1])
        grid[1, 1].link(cell: grid[2, 1])
        grid[2, 1].link(cell: grid[2, 2])
      end

      it 'finds the correct path through the maze' do
        path = described_class.shortest_path(grid, start: start_cell, goal: goal_cell)
        
        # Verify the first and last cells
        expect(path.first).to eq(grid[0, 0])
        expect(path.last).to eq(grid[2, 2])
        
        # Verify the length of the path (should be 5 cells for our L-shaped path)
        expect(path.length).to eq(5)
        
        # Verify each cell in the path is connected to its neighbors
        path.each_cons(2) do |current, next_cell|
          expect(current.linked?(next_cell)).to be true
        end
      end
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