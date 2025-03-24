# frozen_string_literal: true

require_relative 'system'

module Vanilla
  module Systems
    class InputSystem < System
      def initialize(world)
        super(world)
        @logger = Vanilla::Logger.instance
        @quit = false
      end

      def update(_unused)
        entities_with(:input).each do |entity|
          process_input(entity)
        end
      end

      def quit?
        @logger.debug("<InputSystem>: Quit? #{@quit}")

        @quit
      end

      private

      def process_input(entity)
        return unless entity.has_tag?(:player)

        game = Vanilla::ServiceRegistry.get(:game)
        return unless game

        input = game.instance_variable_get(:@display).keyboard_handler.wait_for_input
        @logger.debug("InputSystem: Received input #{input.inspect}")

        case input
        when "q", "\u0003" # 'q' or Ctrl+C
          @quit = true
        else
          key_to_direction = {
            "h" => :west,
            "j" => :south,
            "k" => :north,
            "l" => :east
          }
          direction = key_to_direction[input]

          if direction
            @logger.debug("InputSystem: Setting direction #{direction} for entity #{entity.id}")

            entity.get_component(:input).move_direction = direction
          end
        end
      end
    end
  end
end
