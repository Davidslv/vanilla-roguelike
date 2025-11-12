# frozen_string_literal: true

require_relative 'cell'

module Vanilla
  module MapUtils
    class Grid
      attr_reader :rows, :columns

      def initialize(rows, columns, type_factory: CellTypeFactory.new)
        @rows = rows
        @columns = columns
        @type_factory = type_factory
        @grid = Array.new(rows * columns) do |i|
          Cell.new(row: i / columns, column: i % columns, type_factory: @type_factory)
        end
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

      # Check if coordinates are within grid bounds
      # @param row [Integer] Row coordinate
      # @param col [Integer] Column coordinate
      # @return [Boolean] True if within bounds
      def in_bounds?(row, col)
        row.between?(0, @rows - 1) && col.between?(0, @columns - 1)
      end

      # Check if a tile at the given coordinates blocks vision
      # @param row [Integer] Row coordinate
      # @param col [Integer] Column coordinate
      # @return [Boolean] True if vision is blocked
      def blocks_vision?(row, col)
        cell = self[row, col]
        return true unless cell # Out of bounds blocks vision

        # Check if cell has no links (it's a wall)
        cell.links.empty?
      end
    end
  end
end
