require_relative 'command'

module Vanilla
  module Commands
    class MoveCommand < Command
      attr_reader :entity, :direction, :grid

      def initialize(entity, direction, grid, render_system = nil)
        super()
        @entity = entity
        @direction = direction
        @grid = grid
        @movement_system = Vanilla::Systems::MovementSystem.new(grid)
        @render_system = render_system || Vanilla::Systems::RenderSystemFactory.create
      end

      def execute
        # Store position before movement
        position = @entity.get_component(:position)
        old_row, old_column = position.row, position.column

        # Execute movement
        success = @movement_system.move(@entity, @direction)

        # Update display if movement was successful
        if success
          # Get new position
          new_row, new_column = position.row, position.column

          # If player moved, clear the old position
          if old_row != new_row || old_column != new_column
            old_cell = @grid[old_row, old_column]
            old_cell.tile = Vanilla::Support::TileType::EMPTY if old_cell
          end

          # Update display
          # Get all renderable entities and update the display
          if @entity.is_a?(Vanilla::Level)
            # If entity is a level
            entities = @entity.all_entities
          else
            # If we just have a single entity
            entities = [@entity]
          end

          # TODO: Monsters do not move yet
          # Add monster entities if available
          # if @grid.respond_to?(:monster_system) && @grid.monster_system.respond_to?(:monsters)
          #   entities += @grid.monster_system.monsters
          # end

          # Render the scene
          @render_system.render(entities, @grid)

          # Set executed flag
          @executed = true
        end

        success
      end
    end
  end
end