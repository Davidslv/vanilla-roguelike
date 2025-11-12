# frozen_string_literal: true

require_relative "command"

module Vanilla
  module Commands
    # Command to toggle Field of View on/off (dev mode feature)
    class ToggleFOVCommand < Command
      def execute(world)
        player = world.find_entity_by_tag(:player)
        return unless player

        dev_mode = player.get_component(:dev_mode)

        # If no dev mode component, add one and enable it
        unless dev_mode
          dev_mode = Vanilla::Components::DevModeComponent.new(fov_disabled: true)
          player.add_component(dev_mode)
        else
          # Toggle existing dev mode
          dev_mode.toggle_fov
        end

        mode_text = dev_mode.fov_disabled ? "OFF" : "ON"
        world.emit_event(:dev_mode_toggled, { fov: mode_text, entity: player.id })

        # Show message to player
        message_system = Vanilla::ServiceRegistry.get(:message_system)
        if message_system
          message = dev_mode.fov_disabled ? "DEV MODE: FOV disabled - Full map visible" : "FOV enabled - Exploration mode active"
          message_system.add_message(message)
        end
      end
    end
  end
end
