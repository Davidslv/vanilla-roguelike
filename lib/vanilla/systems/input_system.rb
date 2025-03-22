require_relative 'system'

module Vanilla
  module Systems
    # System that processes keyboard input and updates input components
    class InputSystem < System
      # Update method called once per frame
      # @param delta_time [Float] Time since last update
      def update(delta_time)
        # Get player entity with input component
        player = @world.find_entity_by_tag(:player)
        return unless player && player.has_component?(:input)

        input_component = player.get_component(:input)

        # Process movement input
        if @world.keyboard.key_pressed?(:up)
          input_component.set_move_direction(:north)
        elsif @world.keyboard.key_pressed?(:down)
          input_component.set_move_direction(:south)
        elsif @world.keyboard.key_pressed?(:left)
          input_component.set_move_direction(:west)
        elsif @world.keyboard.key_pressed?(:right)
          input_component.set_move_direction(:east)
        else
          input_component.set_move_direction(nil)
        end

        # Process action input
        action_triggered = @world.keyboard.key_pressed?(:space)
        input_component.set_action_triggered(action_triggered)

        # Process inventory input
        if @world.keyboard.key_pressed?(:i)
          emit_event(:inventory_toggled, { entity_id: player.id })
        end

        # Emit input processed event
        emit_event(:input_processed, { entity_id: player.id })
      end
    end
  end
end