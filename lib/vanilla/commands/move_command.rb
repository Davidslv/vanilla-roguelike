# frozen_string_literal: true

require_relative 'command'

module Vanilla
  module Commands
    # MoveCommand handles entity movement in a specified direction
    # This is a critical command used by the player and NPCs for movement
    class MoveCommand < Command
      VALID_DIRECTIONS = [:north, :south, :east, :west].freeze
      class InvalidDirectionError < StandardError; end

      attr_reader :entity, :direction

      # Create a new movement command
      #
      # @param entity [Object] the entity to move (usually player or monster)
      # @param direction [Symbol] the direction to move in (:north, :south, :east, :west)
      def initialize(entity, direction)
        raise InvalidDirectionError, "Invalid direction: #{direction}" unless VALID_DIRECTIONS.include?(direction)

        super()
        @entity = entity
        @direction = direction

        @logger.debug("[MoveCommand] Initializing move command for entity in direction #{@direction}")
      end

      def execute(world)
        @logger.debug("[MoveCommand] Executing move command for entity in direction #{@direction}")
        @logger.debug("[MoveCommand] Executed? #{@executed}")
        return if @executed

        @logger.debug("[MoveCommand] Executing move command for entity in direction #{@direction}")

        @logger.debug("[MoveCommand] System: #{world.systems.first.first.class.name}")

        movement_system = world.systems.find { |system, _priority| system.is_a?(Vanilla::Systems::MovementSystem) }[0]
        @logger.debug("[MoveCommand] Movement system: #{movement_system.nil?}")
        return unless movement_system

        @logger.debug("[MoveCommand] Executing move command for entity in direction #{@direction}")

        @logger.debug("[MoveCommand] Moving entity #{@entity.class.name}")
        movement_system.move(@entity, @direction)

        @executed = true
      end
    end
  end
end
