# frozen_string_literal: true
# Main entry point for the inventory system
# This file requires all individual inventory system components

module Vanilla
  # Load component definitions
  require_relative 'components/inventory_component'
  require_relative 'components/item_component'
  require_relative 'components/equippable_component'
  require_relative 'components/consumable_component'
  require_relative 'components/effect_component'
  require_relative 'components/durability_component'
  require_relative 'components/key_component'
  require_relative 'components/currency_component'

  # Load inventory subsystem files
  require_relative 'inventory/item'
  require_relative 'inventory/item_factory'
  require_relative 'inventory/item_registry'

  # Load systems
  require_relative 'systems/inventory_system'
  require_relative 'systems/item_interaction_system'
  require_relative 'systems/inventory_render_system'

  # Main Inventory module
  module Inventory
    # This facade class provides a simplified interface for the inventory subsystem
    class InventorySystemFacade
      attr_reader :inventory_system, :render_system, :item_interaction_system, :item_factory, :item_registry, :inventory_render_system

      def initialize(logger, render_system)
        @logger = logger
        @render_system = render_system
        @inventory_system = Vanilla::Systems::InventorySystem.new(logger)
        @item_interaction_system = Vanilla::Systems::ItemInteractionSystem.new(@inventory_system)
        @item_factory = Vanilla::Inventory::ItemFactory.new(logger)
        @item_registry = Vanilla::Inventory::ItemRegistry.new(logger)
        @inventory_render_system = Vanilla::Systems::InventoryRenderSystem.new(render_system, logger)
        @inventory_visible = false

        # Register this facade with the service registry
        Vanilla::ServiceRegistry.register(:inventory_system, self)
      end

      # Add an item to an entity's inventory
      # @param entity [Entity] The entity to add the item to
      # @param item [Entity] The item to add
      # @return [Boolean] Whether the item was successfully added
      def add_item_to_entity(entity, item)
        @inventory_system.add_item(entity, item)
      end

      # Remove an item from an entity's inventory
      # @param entity [Entity] The entity to remove the item from
      # @param item [Entity] The item to remove
      # @return [Boolean] Whether the item was successfully removed
      def remove_item_from_entity(entity, item)
        @inventory_system.remove_item(entity, item)
      end

      # Use an item from an entity's inventory
      # @param entity [Entity] The entity using the item
      # @param item [Entity] The item to use
      # @return [Boolean] Whether the item was successfully used
      def use_item(entity, item)
        @inventory_system.use_item(entity, item)
      end

      # Equip an item from an entity's inventory
      # @param entity [Entity] The entity equipping the item
      # @param item [Entity] The item to equip
      # @return [Boolean] Whether the item was successfully equipped
      def equip_item(entity, item)
        @inventory_system.equip_item(entity, item)
      end

      # Unequip an item from an entity
      # @param entity [Entity] The entity unequipping the item
      # @param item [Entity] The item to unequip
      # @return [Boolean] Whether the item was successfully unequipped
      def unequip_item(entity, item)
        @inventory_system.unequip_item(entity, item)
      end

      # Drop an item from an entity's inventory to the ground
      # @param entity [Entity] The entity dropping the item
      # @param item [Entity] The item to drop
      # @return [Boolean] Whether the item was successfully dropped
      def drop_item(entity, item, level)
        @inventory_system.drop_item(entity, item, level)
      end

      # Check for items at the entity's current position
      # @param entity [Entity] The entity to check for items at its position
      # @param level [Level] The current game level
      # @return [Boolean] Whether any items were picked up
      def check_for_items_at_position(entity, level)
        return false unless entity.has_component?(:position)

        position = entity.get_component(:position)
        @item_interaction_system.process_items_at_location(entity, level, position.row, position.column)
      end

      # Display the inventory UI for an entity
      # @param entity [Entity] The entity whose inventory to display
      def display_inventory(entity)
        @inventory_visible = true
        @inventory_render_system.render_inventory(entity)
      end

      # Hide the inventory UI
      def hide_inventory
        @inventory_visible = false
      end

      # Check if inventory UI is currently visible
      # @return [Boolean] Whether the inventory UI is visible
      def inventory_visible?
        @inventory_visible
      end

      # Toggle inventory view visibility
      # @param entity [Entity] The entity whose inventory to toggle
      # @return [Boolean] The new visibility state
      def toggle_inventory_view(entity)
        @inventory_visible = !@inventory_visible

        if @inventory_visible
          display_inventory(entity)
        end

        @inventory_visible
      end

      # Handle input when inventory is visible
      # @param key [String, Symbol] The input key
      # @param entity [Entity] The entity whose inventory is displayed
      # @return [Boolean] Whether the input was handled
      def handle_inventory_input(key, entity)
        return false unless @inventory_visible

        case key
        when "\e", :escape # ESC key
          hide_inventory
          return true
        when /[a-z]/
          # Letter selection
          index = key.ord - 'a'.ord
          return @inventory_render_system.select_item(entity, index)
        end

        false
      end

      # Cleanup and release resources
      def cleanup
        Vanilla::ServiceRegistry.unregister(:inventory_system)
      end
    end
  end
end
