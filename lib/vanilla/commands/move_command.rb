# frozen_string_literal: true

require_relative 'command'

module Vanilla
  module Commands
    # MoveCommand handles entity movement in a specified direction
    # This is a critical command used by the player and NPCs for movement
    class MoveCommand < Command
      attr_reader :entity, :direction, :grid

      # Create a new movement command
      #
      # @param entity [Object] the entity to move (usually player or monster)
      # @param direction [Symbol] the direction to move in (:north, :south, :east, :west)
      # @param grid [Vanilla::MapUtils::Grid] the grid on which to move
      # @param render_system [Vanilla::Systems::RenderSystem] optional render system
      #
      # IMPORTANT: The parameter order is (entity, direction, grid), NOT (entity, grid, direction)
      # Incorrect parameter order will result in a NoMethodError when trying to call to_sym on a Grid object
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
        logger = Vanilla::Logger.instance
        logger.debug("MoveCommand: Player position before movement: [#{old_row}, #{old_column}]")

        # Execute movement
        success = @movement_system.move(@entity, @direction)
        logger.debug("MoveCommand: Movement successful: #{success}")

        # Update display if movement was successful
        if success
          # Get new position
          new_row, new_column = position.row, position.column
          logger.debug("MoveCommand: Player position after movement: [#{new_row}, #{new_column}]")

          # IMPORTANT: We should NOT modify the grid cells directly
          # This was causing the disappearing entities issue
          # The grid should remain just a representation of walkable spaces and walls

          # Get the game instance
          game = Vanilla::ServiceRegistry.get(:game)

          # Update the grid representation with current entity positions
          # This ensures the grid stays in sync with actual entity positions
          game.level.update_grid_with_entities if game&.level.respond_to?(:update_grid_with_entities)

          # Use the level's all_entities method to get all entities to render
          # This will include the player, stairs, and monsters
          if game && game.level
            entities = game.level.all_entities
          else
            # Fallback if game or level is not available
            entities = []

            # Add the current entity
            entities << @entity

            # Add monsters if available
            monster_system = game&.monster_system
            if monster_system && monster_system.respond_to?(:monsters)
              entities += monster_system.monsters
            end

            # Add stairs if available
            entities << game.level.stairs if game&.level&.stairs
          end

          # Render the scene
          # This will clear the renderer and redraw everything
          @render_system.render(entities, @grid)

          # Set executed flag
          @executed = true
        end

        success
      end
    end
  end
end
