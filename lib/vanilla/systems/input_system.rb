module Vanilla
  module Systems
    # System for handling user input and updating input components
    #
    # This system follows the ECS pattern by:
    # 1. Processing keyboard/input events
    # 2. Converting them to game actions via InputComponents
    # 3. Not performing the actions directly, but triggering events for other systems
    #
    # @example
    #   world = Vanilla::World.new
    #   input_system = InputSystem.new(world, keyboard_handler)
    #   world.add_system(input_system, 1) # Low priority to run first
    class InputSystem < System
      # Initialize a new input system
      # @param world [Vanilla::World] The world this system operates on
      # @param keyboard [Vanilla::InputHandler] The keyboard handler
      def initialize(world, keyboard)
        super(world)
        @keyboard = keyboard
      end

      # Update method called each frame to process input
      # @param delta_time [Float] Time in seconds since the last update
      def update(delta_time)
        # Get player entity
        player = @world.find_entity_by_tag(:player)
        return unless player

        # Process movement input
        process_movement_input(player)

        # Process action input
        process_action_input(player)
      end

      private

      # Process movement input for an entity
      # @param entity [Vanilla::Components::Entity] The entity to process input for
      def process_movement_input(entity)
        # Determine movement direction from keyboard input
        direction = nil

        if @keyboard.key_pressed?(:up) || @keyboard.key_pressed?(:k) || @keyboard.key_pressed?(:w)
          direction = :north
        elsif @keyboard.key_pressed?(:down) || @keyboard.key_pressed?(:j) || @keyboard.key_pressed?(:s)
          direction = :south
        elsif @keyboard.key_pressed?(:left) || @keyboard.key_pressed?(:h) || @keyboard.key_pressed?(:a)
          direction = :west
        elsif @keyboard.key_pressed?(:right) || @keyboard.key_pressed?(:l) || @keyboard.key_pressed?(:d)
          direction = :east
        end

        # If direction is set, emit a move event
        if direction
          emit_event(:movement_requested, {
            entity_id: entity.id,
            direction: direction
          })
        end
      end

      # Process action input for an entity
      # @param entity [Vanilla::Components::Entity] The entity to process input for
      def process_action_input(entity)
        # Check for action keys (e.g., pickup, use item, attack)
        if @keyboard.key_pressed?(:space) || @keyboard.key_pressed?(:return)
          emit_event(:action_requested, {
            entity_id: entity.id,
            action_type: :primary_action
          })
        elsif @keyboard.key_pressed?(:e)
          emit_event(:action_requested, {
            entity_id: entity.id,
            action_type: :pickup
          })
        elsif @keyboard.key_pressed?(:i)
          emit_event(:inventory_toggle_requested, {
            entity_id: entity.id
          })
        end
      end
    end
  end
end