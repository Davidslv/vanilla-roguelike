module Vanilla
  module MapUtils
    # We will use this class to record the distance of each cell from the starting point (@root)
    # so the initialize constructor simply sets up the hash so that the distance of the root from itself is 0.
    class DistanceBetweenCells
      def initialize(root)
        @root = root
        @cells = {}
        @cells[@root] = 0
      end

      # We also add an array accessor method, [](cell),
      # so that we can query the distance of a given cell from the root
      def [](cell)
        @cells[cell]
      end

      # And a corresponding setter, to record the distance of a given cell.
      def []=(cell, distance)
        @cells[cell] = distance
      end

      # to get a list of all of the cells that are present.
      def cells
        @cells.keys
      end

      def path_to(goal)
        current = goal

        breadcrumbs = DistanceBetweenCells.new(@root)
        breadcrumbs[current] = @cells[current]

          until current == @root
            current.links.each do |neighbor|
              if @cells[neighbor] < @cells[current]
                breadcrumbs[neighbor] = @cells[neighbor]
                current = neighbor

                break
              end
            end
          end

        breadcrumbs
      end

      def max
        @cells.values.max
      end
    end

  end
end
