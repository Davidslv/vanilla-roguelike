# frozen_string_literal: true

module Vanilla
  module Systems
    # System for handling interactions between entities and items in the game world
    class ItemInteractionSystem
      # Create a new item interaction system
      # @param inventory_system [InventorySystem] The inventory system to use
      def initialize(inventory_system)
        @inventory_system = inventory_system
        @message_system = Vanilla::ServiceRegistry.get(:message_system) rescue nil
      end

      # Process available items at a cell when an entity moves there
      # @param entity [Entity] The entity that moved
      # @param level [Level] The current game level
      # @param row [Integer] The row coordinate
      # @param column [Integer] The column coordinate
      # @return [Boolean] Whether any items were found
      def process_items_at_location(entity, level, row, column)
        return false unless entity && level

        # Find all item entities at this position
        items = find_items_at_position(level, row, column)
        return false if items.empty?

        # Log a message about finding items
        if @message_system
          if items.size == 1
            item = items.first
            item_name = item.has_component?(:item) ? item.get_component(:item).name : "unknown item"
            @message_system.log_message("items.found.single",
                                        { item: item_name },
                                        importance: :normal,
                                        category: :item)
          else
            @message_system.log_message("items.found.multiple",
                                        { count: items.size },
                                        importance: :normal,
                                        category: :item)
          end
        end

        # Auto-pickup implementation could go here
        # For now, just return true to indicate items were found
        true
      end

      # Pickup a specific item at the entity's location
      # @param entity [Entity] The entity picking up the item
      # @param level [Level] The current game level
      # @param item [Entity] The specific item to pick up
      # @return [Boolean] Whether the item was successfully picked up
      def pickup_item(entity, level, item)
        return false unless entity && level && item
        return false unless entity.has_component?(:position)
        return false unless entity.has_component?(:inventory)
        return false unless item.has_component?(:position)

        # Check if the entity is at the same position as the item
        entity_pos = entity.get_component(:position)
        item_pos = item.get_component(:position)

        unless entity_pos.row == item_pos.row && entity_pos.column == item_pos.column
          if @message_system
            @message_system.log_message("items.not_here",
                                        importance: :warning,
                                        category: :item)
          end
          return false
        end

        # Add the item to the entity's inventory
        result = @inventory_system.add_item(entity, item)

        if result
          # Remove the item from the level
          level.remove_entity(item)
        end

        result
      end

      # Pick up all items at the entity's location
      # @param entity [Entity] The entity picking up items
      # @param level [Level] The current game level
      # @return [Integer] The number of items successfully picked up
      def pickup_all_items(entity, level)
        return 0 unless entity && level
        return 0 unless entity.has_component?(:position)

        entity_pos = entity.get_component(:position)
        items = find_items_at_position(level, entity_pos.row, entity_pos.column)

        # Try to pick up each item
        picked_up_count = 0

        items.each do |item|
          if pickup_item(entity, level, item)
            picked_up_count += 1
          end
        end

        # Log a summary message
        if picked_up_count > 0 && @message_system
          if picked_up_count == 1
            @message_system.log_message("items.picked_up.single",
                                        importance: :normal,
                                        category: :item)
          else
            @message_system.log_message("items.picked_up.multiple",
                                        category: :item,
                                        importance: :normal)
          end
        elsif picked_up_count == 0 && items.any? && @message_system
          @message_system.log_message("items.inventory_full",
                                      importance: :warning,
                                      category: :item)
        end

        picked_up_count
      end

      private

      # Find all item entities at a specific position
      # @param level [Level] The current game level
      # @param row [Integer] The row coordinate
      # @param column [Integer] The column coordinate
      # @return [Array<Entity>] The items found at that position
      def find_items_at_position(level, row, column)
        # Get all entities from the level that:
        # 1. Have a position component at the specified row and column
        # 2. Have an item component
        level.all_entities.select do |entity|
          entity.has_component?(:position) &&
          entity.has_component?(:item) &&
          entity.get_component(:position).row == row &&
          entity.get_component(:position).column == column
        end
      end
    end
  end
end
