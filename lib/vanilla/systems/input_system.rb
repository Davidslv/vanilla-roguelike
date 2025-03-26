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
        entities = entities_with(:input)
        return if entities.empty?

        key = @world.display.keyboard_handler.wait_for_input
        command = @input_handler.handle_input(key)

        @world.queue_command(command)
      end
    end
  end
end
