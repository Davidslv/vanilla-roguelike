# frozen_string_literal: true

module Vanilla
  module Components
    class PositionComponent < Component
      attr_reader :row, :column

      def initialize(row:, column:)
        super()
        @row = row
        @column = column
      end

      def type
        :position
      end

      # FIX: Movement mechanic is depending on this.
      def set_position(row, column)
        @row = row
        @column = column
      end

      def to_hash
        { type: type, row: @row, column: @column }
      end

      def self.from_hash(hash)
        new(row: hash[:row], column: hash[:column])
      end
    end

    Component.register(PositionComponent)
  end
end
