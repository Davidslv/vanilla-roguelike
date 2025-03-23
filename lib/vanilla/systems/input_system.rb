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

        # InputSystem owns KeyboardHandler
        @keyboard = Vanilla::KeyboardHandler.new

        game = Vanilla::ServiceRegistry.get(:game)
        # World relays to Game
        @world.subscribe(:quit_requested, game) if game
      end

      # Update method called once per frame
      # @param delta_time [Float] Time since last update
      def update(_unused)
        # Wait for input (I/O Blocking)
        keyboard_key = @keyboard.wait_for_input
        @logger.debug("<InputSystem> Input received: #{keyboard_key}")

        # Get player entity with input component
        player = @world.find_entity_by_tag(:player)
        return unless player&.has_component?(:input)

        input_component = player.get_component(:input)

        case keyboard_key
        when :q
          emit_event(:quit_requested)
          @logger.info("Quit requested")
        when :k, :up
          input_component.set_move_direction(:north)
          @logger.debug("Move north")
        when :j, :down
          input_component.set_move_direction(:south)
        when :h, :left
          input_component.set_move_direction(:west)
        when :l, :right
          input_component.set_move_direction(:east)
        else
          input_component.set_move_direction(nil)
        end

        # Emit input processed event
        if input_component.move_direction
          emit_event(:input_processed, { entity_id: player.id })
        end
      end

      private

      def movement_key
        %i[up down left right k j h l].find { |key| @keyboard.key_pressed?(key) }
      end
    end
  end
end
