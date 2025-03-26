# frozen_string_literal: true

require_relative 'command'
require_relative 'change_level_command'

module Vanilla
  module Commands
    class MoveCommand < Command
      VALID_DIRECTIONS = [:north, :south, :east, :west].freeze
      class InvalidDirectionError < StandardError; end

      attr_reader :entity, :direction

      def initialize(entity, direction)
        raise InvalidDirectionError, "Invalid direction: #{direction}" unless VALID_DIRECTIONS.include?(direction)

        super()
        @entity = entity
        @logger = Vanilla::Logger.instance
        @direction = direction
        @logger.debug("[MoveCommand] Initializing move command for entity in direction #{@direction}")
      end

      def execute(world)
        return if @executed

        movement_system = world.systems.find { |s, _| s.is_a?(Vanilla::Systems::MovementSystem) }&.first
        unless movement_system
          @logger.error("[MoveCommand] No MovementSystem found")
          return
        end

        movement_system.move(@entity, @direction)
        new_pos = @entity.get_component(:position)
        target_cell = world.grid[new_pos.row, new_pos.column]

        @logger.debug("[MoveCommand] Target cell stairs?: #{target_cell.stairs?}")

        if target_cell&.stairs?
          @logger.info("[MoveCommand] Stairs reached at [#{new_pos.row}, #{new_pos.column}]")
          world.queue_command(ChangeLevelCommand.new(world.current_level.difficulty + 1, @entity))
        end
        @executed = true
      end
    end
  end
end
