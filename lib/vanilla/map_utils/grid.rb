# frozen_string_literal: true

module Vanilla
  module MapUtils
    class Grid
      attr_reader :rows, :columns

      def initialize(rows, columns)
        @rows = rows
        @columns = columns
        @grid = Array.new(rows * columns) { |i| Cell.new(self, i / columns, i % columns) }
        # Set neighbors for each cell
        each_cell do |cell|
          row, col = cell.row, cell.column
          cell.north = self[row - 1, col] if row > 0
          cell.south = self[row + 1, col] if row < @rows - 1
          cell.east  = self[row, col + 1] if col < @columns - 1
          cell.west  = self[row, col - 1] if col > 0
        end
      end

      def [](row, col)
        return nil unless row.is_a?(Integer) && col.is_a?(Integer)
        return nil unless row.between?(0, @rows - 1) && col.between?(0, @columns - 1)

        @grid[row * @columns + col]
      end

      def each_cell
        @grid.each { |cell| yield cell }
      end

      def random_cell
        @grid.sample
      end

      def size
        @rows * @columns
      end
    end

    class Cell
      attr_reader :row, :column, :grid
      attr_accessor :north, :south, :east, :west, :tile

      def initialize(grid, row, column)
        @grid = grid
        @row = row
        @column = column
        @links = {}
        @tile = Vanilla::Support::TileType::EMPTY # Default to walkable
      end

      def link(cell:, bidirectional: true)
        @links[cell] = true
        cell.links[self] = true if bidirectional && cell
      end

      def unlink(cell:, bidirectional: true)
        @links.delete(cell)
        cell.links.delete(self) if bidirectional && cell
      end

      def linked?(cell)
        @links.key?(cell)
      end

      def links
        @links
      end

      def neighbors
        [north, south, east, west].compact
      end

      def distances
        Distances.new(self)
      end
    end

    class Distances
      def initialize(root)
        @root = root
        @cells = { root => 0 }
      end

      def [](cell)
        @cells[cell]
      end

      def path_to(_goal)
        self # Placeholder
      end

      def cells
        @cells.keys
      end

      def max
        max_distance = 0
        max_cell = @root
        @cells.each { |cell, distance| max_cell, max_distance = cell, distance if distance > max_distance }
        [max_cell, max_distance]
      end
    end
  end
end
