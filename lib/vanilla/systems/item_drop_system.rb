# frozen_string_literal: true

module Vanilla
  module Systems
    # Puts an item from the player's inventory on the floor under them (#164).
    # Driven by DropItemCommand.
    class ItemDropSystem < System
      def initialize(world)
        super(world)
        @logger = Vanilla::Logger.instance
      end

      # Items are dropped through DropItemCommand, not on a tick.
      def update(_dt); end

      # @return [Boolean] true if the item was dropped
      def drop_item(entity, item)
        position = entity.get_component(:position)
        inventory = entity.get_component(:inventory)
        return false unless position && inventory&.remove(item)

        place(item, position)
        @world.add_entity(item)
        @world.current_level.add_entity(item)
        @world.current_level.update_grid_with_entity(item)

        emit_event(:item_dropped, { entity_id: entity.id, item_id: item.id })
        @logger.info("[ItemDropSystem] #{entity.id} dropped #{item.name}")
        true
      end

      private

      def place(item, position)
        if item.has_component?(:position)
          item.get_component(:position).set_position(position.row, position.column)
        else
          item.add_component(Vanilla::Components::PositionComponent.new(row: position.row, column: position.column))
        end
        return if item.has_component?(:render)

        item.add_component(Vanilla::Components::RenderComponent.new(character: Vanilla::Support::TileType::GOLD, color: :yellow))
      end
    end
  end
end
