# frozen_string_literal: true

module Vanilla
  module Commands
    class ToggleMenuModeCommand < Command
      def execute(_world)
        message_system = Vanilla::ServiceRegistry.get(:message_system)
        if message_system
          message_system.toggle_selection_mode
          @logger.debug("[ToggleMenuModeCommand] Menu mode toggled to #{message_system.selection_mode? ? 'ON' : 'OFF'}")
        else
          @logger.error("[ToggleMenuModeCommand] No message system found")
        end
      end
    end
  end
end
