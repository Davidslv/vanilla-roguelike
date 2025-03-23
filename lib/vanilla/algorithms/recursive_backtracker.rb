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

        # Set walls for unlinked boundaries
        grid.each_cell do |cell|
          cell.tile = Vanilla::Support::TileType::WALL unless cell.links.any?
          # Ensure linked cells are floors
          cell.links.keys.each { |linked_cell| linked_cell.tile = Vanilla::Support::TileType::EMPTY }
        end

        grid
      end
    end
  end
end
