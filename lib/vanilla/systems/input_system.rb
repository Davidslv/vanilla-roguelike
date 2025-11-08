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

        # Always process 'm' to toggle menu mode
        if key == 'm'
          @world.queue_command(Vanilla::Commands::ToggleMenuModeCommand.new)
          @logger.debug("[InputSystem] Queued ToggleMenuModeCommand for key: #{key}")
          return
        end

        # Check for menu options first (regardless of selection mode)
        # This ensures options work immediately even if selection mode hasn't been set yet
        if message_system && key.is_a?(String) && key.length == 1 && message_system.valid_menu_option?(key)
          message_system.handle_input(key)
          @logger.debug("[InputSystem] Handled menu option: #{key}")
          return
        end

        if message_system&.selection_mode?
          # In menu mode, ignore non-option keys
          @logger.debug("[InputSystem] Ignoring non-option key in menu mode: #{key}")
        else
          # Normal mode: process as normal input (movement, etc.)
          @input_handler.handle_input(key)
        end
      end

      def quit?
        @quit
      end
    end
  end
end
