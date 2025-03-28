# frozen_string_literal: true

require_relative 'system'

module Vanilla
  module Systems
    class InputSystem < System
      def initialize(world)
        super(world)
        @logger = Vanilla::Logger.instance

        @input_handler = InputHandler.new(world)
        @quit = false
      end

      def update(_unused)
        key = @world.display.keyboard_handler.wait_for_input # Blocking I/O
        message_system = Vanilla::ServiceRegistry.get(:message_system)

        if message_system&.handle_input(key)
          @logger.debug("[InputSystem] Input handled by MessageSystem: #{key}")
        else
          @input_handler.handle_input(key)
        end
      end

      def quit?
        @quit
      end
    end
  end
end
