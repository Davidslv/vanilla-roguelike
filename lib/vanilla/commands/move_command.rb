require_relative 'command'

module Vanilla
  module Commands
    class MoveCommand < Command
      attr_reader :entity, :direction, :grid

      def initialize(entity, direction, grid)
        @entity = entity
        @direction = direction
        @grid = grid
        @movement_system = Vanilla::Systems::MovementSystem.new(grid)
      end

      def execute
        # Store position before movement
        old_row = nil
        old_column = nil

        if @entity.respond_to?(:has_component?) && @entity.has_component?(:position)
          position = @entity.get_component(:position)
          old_row, old_column = position.row, position.column
        else
          # Handle legacy Unit
          old_row, old_column = @entity.row, @entity.column
        end

        # Execute movement
        success = @movement_system.move(@entity, @direction)

        # Update display if movement was successful
        if success
          # Get new position
          new_row = nil
          new_column = nil

          if @entity.respond_to?(:has_component?) && @entity.has_component?(:position)
            position = @entity.get_component(:position)
            new_row, new_column = position.row, position.column
          else
            # Handle legacy Unit
            new_row, new_column = @entity.row, @entity.column
          end

          # If player moved, clear the old position
          if old_row != new_row || old_column != new_column
            old_cell = @grid[old_row, old_column]
            old_cell.tile = Vanilla::Support::TileType::EMPTY if old_cell
          end

          # Update display
          Vanilla::Draw.player(grid: @grid, unit: @entity)
          Vanilla::Draw.map(@grid)
        end

        success
      end
    end
  end
end