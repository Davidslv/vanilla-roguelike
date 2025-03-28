# frozen_string_literal: true

module Vanilla
  module Commands
    class ToggleMenuModeCommand < Command
      def initialize
        @logger = Vanilla::Logger.instance
      end

      def execute(_world)
        message_system = Vanilla::ServiceRegistry.get(:message_system)
        if message_system
          message_system.toggle_selection_mode
          @logger.debug("[ToggleMenuModeCommand] Menu mode toggled")
        else
          @logger.error("[ToggleMenuModeCommand] No message system found")
        end
      end
    end
  end
end
