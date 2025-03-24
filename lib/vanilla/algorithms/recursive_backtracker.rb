module Vanilla
  module Algorithms
    class RecursiveBacktracker < AbstractAlgorithm
      def self.on(grid)
        stack = []
        stack.push(grid.random_cell)

        while stack.any?
          current = stack.last
          neighbors = current.neighbors.select { |cell| cell.links.empty? }

          if neighbors.empty?
            stack.pop
          else
            neighbor = neighbors.sample
            current.link(cell: neighbor)
            stack.push(neighbor)
          end
        end

        # Set walls only where there are no links to neighbors
        grid.each_cell do |cell|
          cell.tile = Vanilla::Support::TileType::WALL if cell.links.empty?
        end

        grid
      end
    end
  end
end
