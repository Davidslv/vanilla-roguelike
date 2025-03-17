module Vanilla
  module Algorithms
    class Dijkstra < AbstractAlgorithm
      # Dijkstra's algorithm for finding the shortest path through a maze
      # 
      # @param grid [Vanilla::MapUtils::Grid] the grid representing the maze
      # @param start [Vanilla::MapUtils::Cell] the starting cell
      # @param goal [Vanilla::MapUtils::Cell, nil] the target cell (nil to calculate distances to all cells)
      # @return [Vanilla::MapUtils::Grid] the grid with distances calculated
      def self.on(grid, start:, goal: nil)
        # Calculate distances from the start cell to all reachable cells
        distances = start.distances
        
        # If a goal cell is provided, find the shortest path to it
        # This creates a new distances object containing only the path
        if goal
          distances = distances.path_to(goal)
        end
        
        # Set the distances on the grid so they can be displayed
        grid.distances = distances
        
        grid
      end
      
      # Find the shortest path between two cells
      # 
      # @param grid [Vanilla::MapUtils::Grid] the grid representing the maze
      # @param start [Vanilla::MapUtils::Cell] the starting cell
      # @param goal [Vanilla::MapUtils::Cell] the target cell
      # @return [Array<Vanilla::MapUtils::Cell>] the cells in the shortest path
      def self.shortest_path(grid, start:, goal:)
        # Skip full distance calculation if not needed for display
        # We only need the cells in the path
        distances = start.distances
        path_distances = distances.path_to(goal)
        
        # Return the cells in the path (ordered from start to goal)
        path_distances.cells
      end
    end
  end
end 