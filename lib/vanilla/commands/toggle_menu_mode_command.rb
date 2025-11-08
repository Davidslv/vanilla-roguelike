# frozen_string_literal: true

module Vanilla
  module Commands
    class ToggleMenuModeCommand < Command
      def execute(world)
        message_system = Vanilla::ServiceRegistry.get(:message_system)
        if message_system
          was_in_selection_mode = message_system.selection_mode?
          message_system.toggle_selection_mode
          
          # When entering selection mode (not in combat), add inventory option
          if message_system.selection_mode? && !was_in_selection_mode
            message_system.add_inventory_option_if_available(world)
          end
          
          @logger.debug("[ToggleMenuModeCommand] Menu mode toggled to #{message_system.selection_mode? ? 'ON' : 'OFF'}")
        else
          @logger.error("[ToggleMenuModeCommand] No message system found")
        end
      end
    end
  end
end
