module Vanilla
  module Inventory
    # Wrapper class for entities with item components
    # This provides a convenient interface for working with item entities
    class Item
      attr_reader :entity

      # Initialize a new item wrapper
      # @param entity [Entity] The entity to wrap
      def initialize(entity)
        @entity = entity

        # Ensure the entity has an item component
        unless entity.has_component?(:item)
          raise ArgumentError, "Entity must have an item component"
        end
      end

      # Get the item component
      # @return [ItemComponent] The item component
      def item_component
        @entity.get_component(:item)
      end

      # Get the item name
      # @return [String] The item name
      def name
        item_component.name
      end

      # Get the item description
      # @return [String] The item description
      def description
        item_component.description
      end

      # Check if the item is stackable
      # @return [Boolean] Whether the item can be stacked
      def stackable?
        item_component.stackable?
      end

      # Get the item type
      # @return [Symbol] The item type
      def type
        item_component.item_type
      end

      # Get the item weight
      # @return [Integer] The item weight
      def weight
        item_component.weight
      end

      # Get the item value
      # @return [Integer] The item value
      def value
        item_component.value
      end

      # Get the stack size
      # @return [Integer] The stack size
      def stack_size
        item_component.stack_size
      end

      # Check if the item is equippable
      # @return [Boolean] Whether the item can be equipped
      def equippable?
        @entity.has_component?(:equippable)
      end

      # Get the equippable component if it exists
      # @return [EquippableComponent, nil] The equippable component or nil
      def equippable_component
        @entity.get_component(:equippable) if equippable?
      end

      # Check if the item is consumable
      # @return [Boolean] Whether the item can be consumed
      def consumable?
        @entity.has_component?(:consumable)
      end

      # Get the consumable component if it exists
      # @return [ConsumableComponent, nil] The consumable component or nil
      def consumable_component
        @entity.get_component(:consumable) if consumable?
      end

      # Use the item on a target entity
      # @param target [Entity] The entity to use the item on
      # @return [Boolean] Whether the item was successfully used
      def use(target)
        if consumable?
          consumable_component.consume(target)
        elsif equippable?
          if equippable_component.equipped?
            equippable_component.unequip(target)
          else
            equippable_component.equip(target)
          end
        else
          item_component.use(target)
        end
      end

      # Convert to a string for debugging
      # @return [String] A string representation
      def to_s
        if equippable? && equippable_component.equipped?
          "[E] #{name} (#{type})"
        else
          "#{name} (#{type})"
        end
      end
    end
  end
end
