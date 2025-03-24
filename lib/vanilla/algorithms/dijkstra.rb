# frozen_string_literal: true
module Vanilla
  module Algorithms
    class Dijkstra < AbstractAlgorithm
      def self.on(grid, start:, goal: nil)
        distances = start.distances
        return distances.path_to(goal) if goal
        distances
      end

      def self.shortest_path(grid, start:, goal:)
        distances = start.distances
        distances.path_to(goal).cells
      end

      # Helper to check if a path exists (for LevelGenerator)
      def self.path_exists?(start, goal)
        distances = start.distances
        !!distances[goal] # Returns true if goal is reachable
      end
    end
  end
end
