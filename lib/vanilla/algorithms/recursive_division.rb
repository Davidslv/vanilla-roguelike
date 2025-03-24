# frozen_string_literal: true
module Vanilla
  module Algorithms
    class RecursiveDivision < AbstractAlgorithm
      MINIMUM_SIZE = 5
      TOO_SMALL = 1
      HOW_OFTEN = 4

      def self.on(grid)
        new(grid).process
      end

      def initialize(grid)
        @grid = grid
      end

      def process
        @grid.each_cell do |cell|
          cell.neighbors.each { |n| cell.link(cell: n, bidirectional: false) }
        end
        divide(0, 0, @grid.rows, @grid.columns)
        @grid.each_cell { |cell| cell.tile = Vanilla::Support::TileType::WALL if cell.links.empty? }
        @grid
      end

      private

      def divide(row, column, height, width)
        return if height <= TOO_SMALL || width <= TOO_SMALL || (height < MINIMUM_SIZE && width < MINIMUM_SIZE && rand(HOW_OFTEN) == 0)
        if height > width
          divide_horizontally(row, column, height, width)
        else
          divide_vertically(row, column, height, width)
        end
      end

      def divide_horizontally(row, column, height, width)
        divide_south_of = rand(height - 1)
        passage_at = rand(width)
        width.times do |x|
          next if passage_at == x
          cell = @grid[row + divide_south_of, column + x]
          cell.unlink(cell: cell.south)
        end
        divide(row, column, divide_south_of + 1, width)
        divide(row + divide_south_of + 1, column, height - divide_south_of - 1, width)
      end

      def divide_vertically(row, column, height, width)
        divide_east_of = rand(width - 1)
        passage_at = rand(height)
        height.times do |y|
          next if passage_at == y
          cell = @grid[row + y, column + divide_east_of]
          cell.unlink(cell: cell.east)
        end
        divide(row, column, height, divide_east_of + 1)
        divide(row, column + divide_east_of + 1, height, width - divide_east_of - 1)
      end
    end
  end
end
