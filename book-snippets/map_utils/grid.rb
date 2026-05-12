# frozen_string_literal: true

require_relative 'cell'

# >> grid
module Vanilla
  module MapUtils
    class Grid
      attr_reader :rows, :columns

      def initialize(rows, columns)
        @rows = rows
        @columns = columns
        @grid = Array.new(rows * columns) do |i|
          Cell.new(row: i / columns, column: i % columns)
        end
        each_cell do |cell|
          row, col = cell.row, cell.column
          cell.north = self[row - 1, col] if row > 0
          cell.south = self[row + 1, col] if row < @rows - 1
          cell.east  = self[row, col + 1] if col < @columns - 1
          cell.west  = self[row, col - 1] if col > 0
        end
      end

      def [](row, col)
        return nil unless row.between?(0, @rows - 1) && col.between?(0, @columns - 1)
        @grid[row * @columns + col]
      end
# << grid

      def each_cell
        @grid.each { |cell| yield cell }
      end

      def size
        @rows * @columns
      end

# >> grid
    end
  end
end
# << grid
