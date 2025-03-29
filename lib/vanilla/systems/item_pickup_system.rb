# frozen_string_literal: true

module Vanilla
  module Systems
    class ItemPickupSystem < System
      def initialize(world)
        super(world)
        @logger = Vanilla::Logger.instance
      end

      def update(_dt)
        # Process queued pickup commands
        @world.entities_with([:position, :inventory]).each do |entity|
          items_at_position = @world.query_entities([:item, :position]).select do |item|
            item_pos = item.get_component(:position)
            entity_pos = entity.get_component(:position)
            item_pos.row == entity_pos.row && item_pos.column == entity_pos.column
          end

          items_at_position.each do |item|
            inventory = entity.get_component(:inventory)
            next unless inventory.items.size < inventory.max_size

            inventory.items << item
            @world.remove_entity(item.id) # Remove from world, now in inventory
            @world.emit_event(:item_picked_up, { entity_id: entity.id, item_id: item.id })
            @logger.info("Item picked up: #{item.get_component(:item).name}")
          end
        end
      end
    end
  end
end
