module Vanilla
  module Algorithms
    # Uses Dijkstra's distance to calculate the longest path
    # the path given doesn't mean it's the only longest path,
    # but one between the longest possible paths
    #
    # In the future:
    # We can use this to decide wether the maze has enough complexity,
    # and we can tie it to the characters experience / level
    class LongestPath < AbstractAlgorithm
      def self.on(grid, start:)
        distances = start.distances
        new_start, distance = distances.max
        new_distances = new_start.distances

        goal, distances = new_distances.max
        grid.distances = new_distances.path_to(goal)

        grid
      end
    end
  end
end
