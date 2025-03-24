# frozen_string_literal: true
module Vanilla
  module Algorithms
    class AldousBroder < AbstractAlgorithm
      def self.on(grid)
        cell = grid.random_cell
        unvisited = grid.size - 1
        while unvisited > 0
          neighbor = cell.neighbors.sample
          if neighbor.links.empty?
            cell.link(cell: neighbor)
            unvisited -= 1
          end
          cell = neighbor
        end

        grid.each_cell do |cell|
          if cell.links.empty?
            cell.tile = Vanilla::Support::TileType::WALL
          end
        end

        grid
      end
    end
  end
end
