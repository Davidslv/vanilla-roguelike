# frozen_string_literal: true

module Vanilla
  module MapUtils
# >> cell
    class Cell
      attr_reader :row, :column
      attr_accessor :north, :south, :east, :west

      def initialize(row:, column:)
        @row, @column = row, column
        @links = {}
      end

      def link(cell:, bidirectional: true)
        @links[cell] = true
        cell.link(cell: self, bidirectional: false) if bidirectional
        self
      end

      def links
        @links.keys
      end

      def linked?(cell)
        @links.key?(cell)
      end
# << cell

      def neighbors
        [north, south, east, west].compact
      end

      def inspect
        "#<#{self.class.name} #{row},#{column}>"
      end

      attr_accessor :tile

# >> cell
    end
# << cell
  end
end
