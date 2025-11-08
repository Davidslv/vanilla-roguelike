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

        if message_system&.selection_mode?
          # In menu mode, only process valid menu inputs
          if key.is_a?(String) && key.length == 1 && message_system.valid_menu_option?(key)
            message_system.handle_input(key)
            @logger.debug("[InputSystem] Handled menu option: #{key}")
          else
            @logger.debug("[InputSystem] Ignoring non-option key in menu mode: #{key}")
          end
        else
          # Normal mode: check for menu options first, then process other inputs
          if message_system && key.is_a?(String) && key.length == 1
            # Check if options are available and this key matches an option
            # valid_menu_option? checks if options exist and key matches
            if message_system.valid_menu_option?(key)
              message_system.handle_input(key)
              @logger.debug("[InputSystem] Handled menu option in normal mode: #{key}")
              return
            end
          end
          # No options or not a valid option key, process as normal input
          @input_handler.handle_input(key)
        end
      end

      def quit?
        @quit
      end
    end
  end
end
