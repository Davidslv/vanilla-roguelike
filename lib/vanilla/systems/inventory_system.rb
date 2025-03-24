# frozen_string_literal: true
module Vanilla
  module Systems
    # System for managing entity inventories and item interactions
    class InventorySystem
      # Create a new inventory system
      # @param logger [Logger] The logger instance
      def initialize(logger)
        @logger = logger
        @message_system = Vanilla::ServiceRegistry.get(:message_system) rescue nil
      end

      # Add an item to an entity's inventory
      # @param entity [Entity] The entity to add the item to
      # @param item [Entity] The item to add
      # @return [Boolean] Whether the item was successfully added
      def add_item(entity, item)
        return false unless entity && item
        return false unless entity.has_component?(:inventory)

        inventory = entity.get_component(:inventory)
        result = inventory.add(item)

        if result
          log_message("items.add", { item: item_name(item) })
        else
          log_message("items.inventory_full", {}, importance: :warning)
        end

        result
      end

      # Remove an item from an entity's inventory
      # @param entity [Entity] The entity to remove the item from
      # @param item [Entity] The item to remove
      # @return [Entity, nil] The removed item, or nil if not found
      def remove_item(entity, item)
        return nil unless entity && item
        return nil unless entity.has_component?(:inventory)

        inventory = entity.get_component(:inventory)
        result = inventory.remove(item)

        if result
          log_message("items.remove", { item: item_name(item) })
        end

        result
      end

      # Use an item from an entity's inventory
      # @param entity [Entity] The entity using the item
      # @param item [Entity] The item to use
      # @return [Boolean] Whether the item was successfully used
      def use_item(entity, item)
        return false unless entity && item
        return false unless entity.has_component?(:inventory)
        return false unless entity.get_component(:inventory).items.include?(item)

        # Handle different item use cases
        result = if item.has_component?(:consumable)
          use_consumable(entity, item)
        elsif item.has_component?(:equippable)
          toggle_equip(entity, item)
        else
          # Default generic use behavior
          log_message("items.use", { item: item_name(item) })
          true
        end

        result
      end

      # Equip an item
      # @param entity [Entity] The entity equipping the item
      # @param item [Entity] The item to equip
      # @return [Boolean] Whether the item was successfully equipped
      def equip_item(entity, item)
        return false unless entity && item
        return false unless entity.has_component?(:inventory)
        return false unless entity.get_component(:inventory).items.include?(item)
        return false unless item.has_component?(:equippable)

        equippable = item.get_component(:equippable)

        # Check if already equipped
        return false if equippable.equipped?

        # Try to equip the item
        result = equippable.equip(entity)

        if result
          log_message("items.equip", { item: item_name(item) })
        else
          log_message("items.cannot_equip", { item: item_name(item) }, importance: :warning)
        end

        result
      end

      # Unequip an item
      # @param entity [Entity] The entity unequipping the item
      # @param item [Entity] The item to unequip
      # @return [Boolean] Whether the item was successfully unequipped
      def unequip_item(entity, item)
        return false unless entity && item
        return false unless entity.has_component?(:inventory)
        return false unless entity.get_component(:inventory).items.include?(item)
        return false unless item.has_component?(:equippable)

        equippable = item.get_component(:equippable)

        # Check if actually equipped
        return false unless equippable.equipped?

        # Try to unequip the item
        result = equippable.unequip(entity)

        if result
          log_message("items.unequip", { item: item_name(item) })
        end

        result
      end

      # Drop an item from an entity's inventory onto the current level
      # @param entity [Entity] The entity dropping the item
      # @param item [Entity] The item to drop
      # @param level [Level] The current game level
      # @return [Boolean] Whether the item was successfully dropped
      def drop_item(entity, item, level)
        return false unless entity && item && level
        return false unless entity.has_component?(:inventory)
        return false unless entity.has_component?(:position)

        # First try to unequip if it's equipped
        if item.has_component?(:equippable) && item.get_component(:equippable).equipped?
          unequip_item(entity, item)
        end

        # Remove from inventory
        removed_item = remove_item(entity, item)
        return false unless removed_item

        # Position the item at the entity's location on the level
        if removed_item.has_component?(:position)
          pos = entity.get_component(:position)
          removed_item.get_component(:position).move_to(pos.row, pos.column)
        else
          # Add a position component if it doesn't have one
          pos = entity.get_component(:position)
          removed_item.add_component(
            Vanilla::Components::PositionComponent.new(row: pos.row, column: pos.column)
          )
        end

        # Add the item to the level's entities
        level.add_entity(removed_item)

        log_message("items.drop", { item: item_name(item) })
        true
      end

      private

      # Get the name of an item
      # @param item [Entity] The item entity
      # @return [String] The name of the item
      def item_name(item)
        return "unknown item" unless item && item.has_component?(:item)

        item.get_component(:item).name
      end

      # Use a consumable item
      # @param entity [Entity] The entity using the item
      # @param item [Entity] The consumable item
      # @return [Boolean] Whether the item was successfully used
      def use_consumable(entity, item)
        consumable = item.get_component(:consumable)
        result = consumable.consume(entity)

        if result
          log_message("items.consume", { item: item_name(item) })

          # Remove the item if it's out of charges
          unless consumable.has_charges?
            remove_item(entity, item)
          end
        else
          log_message("items.cannot_use", { item: item_name(item) }, importance: :warning)
        end

        result
      end

      # Toggle equipment state of an item
      # @param entity [Entity] The entity toggling equipment
      # @param item [Entity] The equippable item
      # @return [Boolean] Whether the toggle was successful
      def toggle_equip(entity, item)
        equippable = item.get_component(:equippable)

        if equippable.equipped?
          unequip_item(entity, item)
        else
          equip_item(entity, item)
        end
      end

      # Log a message through the message system
      # @param key [String, Symbol] The message key to log
      # @param metadata [Hash] Additional metadata for the message
      # @param options [Hash] Additional options like importance
      def log_message(key, metadata = {}, options = {})
        return unless @message_system

        importance = options[:importance] || :normal
        category = options[:category] || :item

        @message_system.log_message(key, {
          category: category,
          importance: importance,
          metadata: metadata
        })
      end
    end
  end
end
