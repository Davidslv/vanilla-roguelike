# frozen_string_literal: true

module Vanilla
  module Systems
    # Base class for all systems in the ECS architecture.
    # Systems contain the behavior and logic of the game.
    class System
      attr_reader :world

      # Initialize a new system
      # @param world [World] The world this system belongs to
      def initialize(world)
        @world = world
      end

      # Update method called once per frame
      # @param delta_time [Float] Time since last update
      def update(delta_time)
        # Override in subclasses
      end

      # Handle an event from the world
      # @param event_type [Symbol] The type of event
      # @param data [Hash] The event data
      def handle_event(event_type, data)
        # Override in subclasses
      end

      # Helper method to find entities with specific components
      # @param component_types [Array<Symbol>] Component types to query for
      # @return [Array<Entity>] Entities with all the specified component types
      def entities_with(*component_types)
        @world.query_entities(component_types)
      end

      # Helper method to emit an event
      # @param event_type [Symbol] The type of event
      # @param data [Hash] The event data
      def emit_event(event_type, data = {})
        @world.emit_event(event_type, data)
      end

      # Helper method to queue a command
      # @param command_type [Symbol] The type of command
      # @param params [Hash] The command parameters
      def queue_command(command_type, params = {})
        @world.queue_command(command_type, params)
      end
    end
  end
end
