# lib/systems/input_system.rb
require_relative "../event"
require_relative "../logger"

module Systems
  class InputSystem
    def initialize(event_manager)
      @event_manager = event_manager
    end

    def process(entities)
      @event_manager.process do |event|
        next unless event.type == :key_pressed

        key = event.data[:key]
        Logger.debug("Key pressed: #{key}")

        player = entities.find { |e| e.has_component?(Components::Input) }
        if player
          Logger.debug("Player found, processing movement")
          case key
          when "w" then issue_move_command(player, 0, -1)   # Up
          when "s" then issue_move_command(player, 0, 1)    # Down
          when "a" then issue_move_command(player, -1, 0)   # Left
          when "d" then issue_move_command(player, 1, 0)    # Right
          end
        else
          Logger.error("Player not found!")
        end
      end
    end

    private

    def issue_move_command(entity, dx, dy)
      return unless entity.has_component?(Components::Movement)

      movement = entity.get_component(Components::Movement)
      movement.dx = dx
      movement.dy = dy
      Logger.debug("Movement command issued: dx=#{dx}, dy=#{dy}")
    end
  end
end
