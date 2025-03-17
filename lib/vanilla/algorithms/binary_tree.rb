module Vanilla
  module Algorithms
    class BinaryTree < AbstractAlgorithm
      def self.on(grid)
        # What the binary tree is doing here is linking each cell that has been created before.
        # This will be necessary to decide on the maze layout later on.
        # Linked neighbors means that theres a passage between both cells (no wall)
        # More efficient implementation that avoids unnecessary array operations
        grid.each_cell do |cell|
          # Most cells will have north or east neighbors, so we optimize for that case
          has_north = !cell.north.nil?
          has_east = !cell.east.nil?
          
          # If cell has both north and east neighbors, randomly choose one
          if has_north && has_east
            if rand(2) == 0
              cell.link(cell: cell.north)
            else
              cell.link(cell: cell.east)
            end
          # Otherwise, link to whichever neighbor exists
          elsif has_north
            cell.link(cell: cell.north)
          elsif has_east
            cell.link(cell: cell.east)
          # No links if no north or east neighbors
          end
        end

        grid
      end
    end
  end
end
