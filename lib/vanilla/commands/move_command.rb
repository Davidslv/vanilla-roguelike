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

        current_position = @entity.get_component(:position)
        new_row, new_col = case @direction
                           when :north then [current_position.row - 1, current_position.column]
                           when :south then [current_position.row + 1, current_position.column]
                           when :east  then [current_position.row, current_position.column + 1]
                           when :west  then [current_position.row, current_position.column - 1]
                           else return
                           end

        # Check for stairs entity at target position
        target_entities = world.current_level.entities.select do |entity|
          entity_position = entity.get_component(:position)

          entity_position&.row == new_row && entity_position&.column == new_col && entity.has_component?(:stairs)
        end

        is_stairs = target_entities.any?
        @logger.debug("[MoveCommand] Target [#{new_row}, #{new_col}] has stairs entity? #{is_stairs}")

        movement_system.move(@entity, @direction)
        new_position = @entity.get_component(:position)

        # Check if the entity is at the target position and has stairs component
        # this is done before the movement command is executed so that we can change levels
        if is_stairs && new_position.row == new_row && new_position.column == new_col
          @logger.info("[MoveCommand] Stairs reached at [#{new_row}, #{new_col}]")
          world.queue_command(ChangeLevelCommand.new(world.current_level.difficulty + 1, @entity))
        end
        @executed = true
      end
    end
  end
end
