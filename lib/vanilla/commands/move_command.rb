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
        # Execute movement
        success = @movement_system.move(@entity, @direction)

        # Update display if movement was successful
        if success
          Vanilla::Draw.player(grid: @grid, unit: @entity)
          Vanilla::Draw.map(@grid)
        end

        success
      end
    end
  end
end