# frozen_string_literal: true

module Vanilla
  module Systems
    class ItemDropSystem < System
      def initialize(world)
        super(world)
        @logger = Vanilla::Logger.instance
      end

      def update(_dt)
        @world.entities_with([:inventory, :position]).each do |entity|
          # Assume drop commands are queued via events or commands
          @world.command_queue.each do |command_type, params|
            next unless command_type == :drop_item && params[:entity_id] == entity.id

            item = @world.get_entity(params[:item_id])
            next unless item

            inventory = entity.get_component(:inventory)
            next unless inventory.items.include?(item)

            inventory.items.delete(item)
            pos = entity.get_component(:position)
            item.get_component(:position)&.set_position(pos.row, pos.column)
            @world.add_entity(item)
            @world.emit_event(:item_dropped, { entity_id: entity.id, item_id: item.id })
            @logger.info("Item dropped: #{item.get_component(:item).name}")
          end
        end
      end
    end
  end
end
