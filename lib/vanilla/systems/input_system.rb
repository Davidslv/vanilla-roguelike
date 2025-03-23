require_relative 'system'

module Vanilla
  module Systems
    # System that processes keyboard input and updates input components
    class InputSystem < System
      # Initialize a new input system
      # @param world [World] The world this system belongs to
      def initialize(world)
        super(world)
        @logger = Vanilla::Logger.instance
        @keyboard = Vanilla::KeyboardHandler.new
      end

      # Update method called once per frame
      # @param delta_time [Float] Time since last update
      def update(_delta_time)
        # Get player entity with input component
        player = @world.find_entity_by_tag(:player)
        return unless player && player.has_component?(:input)

        input_component = player.get_component(:input)

        if @keyboard.key_pressed?(:q)
          emit_event(:quit_requested) # Handle quit here
        elsif direction = movement_key
          input_component.set_move_direction(direction)
        else
          input_component.set_move_direction(nil)
        end

        # Emit input processed event
        emit_event(:input_processed, { entity_id: player.id })
      end

      private

      def movement_key
        %i[up down left right k j h l].find { |key| @keyboard.key_pressed?(key) }
      end
    end
  end
end
