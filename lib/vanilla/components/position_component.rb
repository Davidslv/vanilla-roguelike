module Vanilla
  module Components
    # Component for tracking an entity's position in a grid
    class PositionComponent < Component
      # @return [Integer] row in the grid
      attr_reader :row

      # @return [Integer] column in the grid
      attr_reader :column

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

      # Set the entity's position (absolute)
      # @param new_row [Integer] the new row position
      # @param new_column [Integer] the new column position
      # @return [void]
      def set_position(new_row, new_column)
        @row = new_row
        @column = new_column
      end

      # Translate the position by the given deltas (relative movement)
      # @param delta_row [Integer] change in row
      # @param delta_column [Integer] change in column
      # @return [void]
      def translate(delta_row, delta_column)
        @row += delta_row
        @column += delta_column
      end

      # Legacy method for backward compatibility
      # @deprecated Use {#set_position} instead
      # @param new_row [Integer] the new row
      # @param new_column [Integer] the new column
      def move_to(new_row, new_column)
        set_position(new_row, new_column)
      end

      # Legacy method for backward compatibility
      # @deprecated Use {#translate} instead
      # @param delta_row [Integer] change in row
      # @param delta_column [Integer] change in column
      def move_by(delta_row, delta_column)
        translate(delta_row, delta_column)
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
        new(row: hash[:row] || 0, column: hash[:column] || 0)
      end
    end

    # Register this component type
    Component.register(PositionComponent)
  end
end