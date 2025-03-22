module Vanilla
  module Systems
    # System for detecting and responding to entity collisions
    #
    # This system listens for movement events and checks if entities
    # collide with each other, then emits collision events.
    #
    # It follows the ECS pattern by:
    # 1. Not storing entity state directly
    # 2. Using events for communication with other systems
    # 3. Operating on position components only
    class CollisionSystem < System
      # Initialize a new collision system
      # @param world [Vanilla::World] The world this system operates on
      def initialize(world)
        super

        # Subscribe to movement events
        world.subscribe(:entity_moved, self)
      end

      # Update method called each frame
      # @param delta_time [Float] Time in seconds since the last update
      def update(delta_time)
        # This system primarily works via events, but could
        # check for collisions that don't involve movement here
      end

      # Handle events
      # @param event_type [Symbol] The type of event
      # @param data [Hash] Event data
      def handle_event(event_type, data)
        case event_type
        when :entity_moved
          check_for_collisions(data)
        end
      end

      private

      # Check for collisions after an entity has moved
      # @param data [Hash] Movement event data
      def check_for_collisions(data)
        entity_id = data[:entity_id]
        entity = @world.get_entity(entity_id)
        return unless entity

        new_position = data[:new_position]
        row, column = new_position[:row], new_position[:column]

        # Find all entities at the same position
        entities_at_position = find_entities_at_position(row, column)

        # Don't count collisions with itself
        entities_at_position.delete(entity)

        # Emit collision events for each entity at this position
        entities_at_position.each do |other_entity|
          emit_collision_event(entity, other_entity, row, column)
        end
      end

      # Find all entities at a specific grid position
      # @param row [Integer] Row position
      # @param column [Integer] Column position
      # @return [Array<Entity>] Entities at the position
      def find_entities_at_position(row, column)
        # Get all entities with position components
        position_entities = entities_with(:position)

        # Filter for entities at the specified position
        position_entities.select do |entity|
          position = entity.get_component(:position)
          position.row == row && position.column == column
        end
      end

      # Emit a collision event between two entities
      # @param entity [Entity] The first entity involved in the collision
      # @param other_entity [Entity] The second entity involved in the collision
      # @param row [Integer] Row position of the collision
      # @param column [Integer] Column position of the collision
      def emit_collision_event(entity, other_entity, row, column)
        emit_event(:entities_collided, {
          entity_id: entity.id,
          other_entity_id: other_entity.id,
          position: { row: row, column: column }
        })
      end
    end
  end
end