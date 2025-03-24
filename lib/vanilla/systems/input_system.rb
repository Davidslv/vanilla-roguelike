# frozen_string_literal: true

require_relative 'system'

module Vanilla
  module Systems
    class InputSystem < System
      def initialize(world)
        super(world)
        @logger = Vanilla::Logger.instance
      end

      def update(_delta_time)
        entities_with(:input).each do |entity|
          process_input(entity)
        end
      end

      private

      def process_input(entity)
        game = Vanilla::ServiceRegistry.get(:game)
        return unless game && entity.has_tag?(:player)

        input = game.instance_variable_get(:@display).keyboard_handler.wait_for_input
        direction = game.send(:input_to_direction, input)

        if direction
          @logger.debug("InputSystem: Setting direction #{direction} for entity #{entity.id}")
          entity.get_component(:input).set_move_direction(direction)
        end
      end
    end
  end
end
