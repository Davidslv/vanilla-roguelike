require_relative 'system'

module Vanilla
  module Systems
    # System that handles collision detection and response
    class CollisionSystem < System
      # Initialize the collision system
      # @param world [World] The world this system belongs to
      def initialize(world)
        super
        @world.subscribe(:entity_moved, self)
      end

      # Update method called once per frame
      # @param delta_time [Float] Time since last update
      def update(delta_time)
        # Most collision logic is handled via events
        # Any continuous collision detection would go here
      end

      # Handle events from the world
      # @param event_type [Symbol] The type of event
      # @param data [Hash] The event data
      def handle_event(event_type, data)
        return unless event_type == :entity_moved

        entity_id = data[:entity_id]
        entity = @world.get_entity(entity_id)
        return unless entity

        position = data[:new_position] || entity.get_component(:position)
        return unless position

        # Find entities at the same position
        entities_at_position = find_entities_at_position(position)
        entities_at_position.each do |other_entity|
          next if other_entity.id == entity_id

          # Emit collision event
          emit_event(:entities_collided, {
            entity_id: entity_id,
            other_entity_id: other_entity.id,
            position: { row: position.row, column: position.column }
          })
        end
      end

      private

      # Find all entities at a specific position
      # @param position [PositionComponent] The position to check
      # @return [Array<Entity>] Entities at the specified position
      def find_entities_at_position(position)
        entities_with(:position).select do |entity|
          pos = entity.get_component(:position)
          pos.row == position.row && pos.column == position.column
        end
      end
    end
  end
end