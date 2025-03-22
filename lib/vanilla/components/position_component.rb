module Vanilla
  module Components
    # Component for tracking an entity's position in a grid
    class PositionComponent < Component
      # @return [Integer] row in the grid
      attr_accessor :row

      # @return [Integer] column in the grid
      attr_accessor :column

      # Initialize a new position component
      # @param row [Integer] the row position
      # @param column [Integer] the column position
      def initialize(row: 0, column: 0)
        super()
        @row = row
        @column = column
      end

      # @return [Symbol] the component type
      def type
        :position
      end

      # Get the entity's coordinates
      # @return [Array<Integer>] [row, column]
      def coordinates
        [row, column]
      end

      # Move to an absolute position
      # @param new_row [Integer] the new row
      # @param new_column [Integer] the new column
      def move_to(new_row, new_column)
        @row = new_row
        @column = new_column
      end

      # Move relative to current position
      # @param delta_row [Integer] change in row
      # @param delta_column [Integer] change in column
      def move_by(delta_row, delta_column)
        @row += delta_row
        @column += delta_column
      end

      # @return [Hash] serialized component data
      def data
        {
          row: @row,
          column: @column
        }
      end

      # Create a position component from a hash
      # @param hash [Hash] serialized component data
      # @return [PositionComponent] deserialized component
      def self.from_hash(hash)
        new(row: hash[:row], column: hash[:column])
      end
    end

    # Register this component type
    Component.register(PositionComponent)
  end
end