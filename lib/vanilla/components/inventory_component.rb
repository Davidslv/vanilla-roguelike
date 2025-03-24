module Vanilla
  module Components
    # Component for managing an entity's inventory of items
    # Used primarily by the player, but can be used by other entities like chests
    class InventoryComponent
      attr_reader :items, :max_size

      # Initialize a new inventory component
      # @param max_size [Integer] The maximum number of items this inventory can hold
      def initialize(max_size: 20)
        @items = []
        @max_size = max_size
      end

      # Get the component type
      # @return [Symbol] The component type
      def type
        :inventory
      end

      # Check if the inventory is full
      # @return [Boolean] Whether the inventory is at max capacity
      def full?
        @items.size >= @max_size
      end

      # Add an item to the inventory
      # @param item [Entity] The item entity to add
      # @return [Boolean] Whether the item was successfully added
      def add(item)
        return false if full?

        # If the item is stackable, try to stack it with existing items
        if item.has_component?(:item) && item.get_component(:item).stackable?
          existing_item = find_stackable_item(item)
          if existing_item
            existing_item.get_component(:item).increase_stack
            return true
          end
        end

        @items << item
        true
      end

      # Remove an item from the inventory
      # @param item [Entity] The item entity to remove
      # @return [Entity, nil] The removed item, or nil if not found
      def remove(item)
        index = @items.find_index(item)
        return nil unless index

        # If stackable with more than 1 in stack, reduce stack size instead of removing
        if item.has_component?(:item) && item.get_component(:item).stackable? &&
           item.get_component(:item).stack_size > 1
          item.get_component(:item).decrease_stack
          return item
        end

        @items.delete_at(index)
      end

      # Check if the inventory contains an item of a specific type
      # @param item_type [Symbol] The type of item to check for
      # @return [Boolean] Whether an item of the specified type exists
      def has?(item_type)
        @items.any? do |item|
          item.has_component?(:item) && item.get_component(:item).item_type == item_type
        end
      end

      # Count the number of items of a specific type
      # @param item_type [Symbol] The type of item to count
      # @return [Integer] The number of items of that type (including stack sizes)
      def count(item_type)
        @items.sum do |item|
          if item.has_component?(:item) && item.get_component(:item).item_type == item_type
            item.get_component(:item).stack_size
          else
            0
          end
        end
      end

      # Find an item by its ID
      # @param id [String] The unique ID of the item to find
      # @return [Entity, nil] The found item, or nil if not found
      def find_by_id(id)
        @items.find { |item| item.id == id }
      end

      # Convert to hash for serialization
      # @return [Hash] The component data as a hash
      def to_hash
        {
          type: type,
          max_size: @max_size,
          items: @items.map(&:to_hash)
        }
      end

      # Create from hash for deserialization
      # @param hash [Hash] The hash data to create from
      # @return [InventoryComponent] The created component
      def self.from_hash(hash)
        component = new(max_size: hash[:max_size])

        # Items will be handled separately by the entity that owns this component
        component
      end

      private

      # Find a stackable item of the same type
      # @param item [Entity] The item to find a stack for
      # @return [Entity, nil] A matching item that can be stacked with, or nil
      def find_stackable_item(item)
        return nil unless item.has_component?(:item)

        item_component = item.get_component(:item)
        item_type = item_component.item_type

        @items.find do |inv_item|
          inv_item.has_component?(:item) &&
          inv_item.get_component(:item).item_type == item_type &&
          inv_item.get_component(:item).stackable?
        end
      end
    end

    # Register this component
    Component.register(InventoryComponent)
  end
end
