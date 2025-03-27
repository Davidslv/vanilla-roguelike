# frozen_string_literal: true

require_relative 'system'

module Vanilla
  module Systems
    # System that handles collision detection and response
    class CollisionSystem < System
      # Initialize the collision system
      # @param world [World] The world this system belongs to
      def initialize(world)
        super
        @logger = Vanilla::Logger.instance
        @logger.debug("[CollisionSystem] Initializing")
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

        # Get position from data or entity
        if data[:new_position]
          row = data[:new_position][:row]
          column = data[:new_position][:column]
        elsif entity.has_component?(:position)
          position = entity.get_component(:position)
          row = position.row
          column = position.column
        else
          @logger.debug("[CollisionSystem] No position component found for entity #{entity_id}")
          return
        end

        # Find entities at the same position
        entities_at_position = find_entities_at_position(row, column)
        entities_at_position.each do |other_entity|
          next if other_entity.id == entity_id

          # Emit collision event
          emit_event(:entities_collided, {
                       entity_id: entity_id,
                       other_entity_id: other_entity.id,
                       position: { row: row, column: column }
                     })

          handle_specific_collisions(entity, other_entity)
        end
      end

      private

      # Find all entities at a specific position
      # @param row [Integer] The row position
      # @param column [Integer] The column position
      # @return [Array<Entity>] Entities at the specified position
      def find_entities_at_position(row, column)
        entities_with(:position).select do |entity|
          pos = entity.get_component(:position)
          pos.row == row && pos.column == column
        end
      end

      # Handle specific collision types
      # @param entity [Entity] The first entity
      # @param other_entity [Entity] The second entity
      def handle_specific_collisions(entity, other_entity)
        # Handle player-stairs collision
        @logger.debug("[CollisionSystem] Handling specific collisions for entity #{entity.id} and #{other_entity.id}")
        if (entity.has_tag?(:player) && other_entity.has_tag?(:stairs)) ||
           (entity.has_tag?(:stairs) && other_entity.has_tag?(:player))
          player = entity.has_tag?(:player) ? entity : other_entity
          @logger.debug("[CollisionSystem] Level transition requested for player #{player.id}")
          emit_event(:level_transition_requested, { player_id: player.id })
        end

        # Handle player-item collision for pickup
        if (entity.has_tag?(:player) && other_entity.has_tag?(:item)) ||
           (entity.has_tag?(:item) && other_entity.has_tag?(:player))
          player = entity.has_tag?(:player) ? entity : other_entity
          item = entity.has_tag?(:item) ? entity : other_entity

          if player.has_component?(:inventory) && item.has_component?(:item)
            item_name = item.get_component(:item).name

            emit_event(:item_picked_up, {
                         player_id: player.id,
                         item_id: item.id,
                         item_name: item_name
                       })

            # Queue command to add item to inventory and remove from world
            @world.queue_command(:add_to_inventory, {
                                   player_id: player.id,
                                   item_id: item.id
                                 })

            @world.queue_command(:remove_entity, {
                                   entity_id: item.id
                                 })
          end
        end
      end
    end
  end
end
