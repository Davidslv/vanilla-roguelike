module Vanilla
  module Systems
    # Base class for all ECS systems
    #
    # This class provides the foundation for all systems in the ECS architecture.
    # Systems operate on entities with specific combinations of components,
    # implementing game behavior while keeping it separate from data.
    #
    # Systems should:
    # 1. Query entities with the components they need
    # 2. Process those entities according to their specific logic
    # 3. Communicate with other systems via events, not direct calls
    # 4. Not store entity state directly
    class System
      # @return [Vanilla::World] The world this system operates on
      attr_reader :world

      # Initialize a new system
      # @param world [Vanilla::World] The world this system operates on
      def initialize(world)
        @world = world
      end

      # Update method called each frame
      # @param delta_time [Float] Time in seconds since the last update
      def update(delta_time)
        # Override in subclasses
        raise NotImplementedError, "#{self.class.name}#update must be implemented"
      end

      # Handle an event from the event system
      # @param event_type [Symbol] The type of event
      # @param data [Hash] Event data
      def handle_event(event_type, data)
        # Override in subclasses that need to react to events
      end

      # Helper method to find entities with specific components
      # @param component_types [Array<Symbol>] Types of components to query for
      # @return [Array<Entity>] Entities that have all the specified components
      def entities_with(*component_types)
        @world.query_entities(component_types)
      end

      # Helper method to emit an event
      # @param event_type [Symbol] The type of event to emit
      # @param data [Hash] Event data to include
      def emit_event(event_type, data = {})
        @world.emit_event(event_type, data)
      end
    end
  end
end