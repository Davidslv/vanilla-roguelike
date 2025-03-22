module Vanilla
  module Components
    # Component for managing an entity's inventory of items
    # Used primarily by the player, but can be used by other entities like chests
    class InventoryComponent < Component
      # @return [Array<Entity>] Items in the inventory
      attr_reader :items

      # @return [Integer] Maximum number of items this inventory can hold
      attr_reader :max_size

      # Initialize a new inventory component
      # @param max_size [Integer] The maximum number of items this inventory can hold
      def initialize(max_size: 20)
        @items = []
        @max_size = max_size
        super()
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

      # Get the current number of items
      # @return [Integer] The number of items in inventory
      def size
        @items.size
      end

      # Add an item to the inventory without any logic
      # @param item [Entity] The item entity to add
      # @return [Boolean] Whether the item was successfully added
      def add_item(item)
        return false if full?
        @items << item
        true
      end

      # Remove an item from the inventory without any logic
      # @param item [Entity] The item entity to remove
      # @return [Entity, nil] The removed item, or nil if not found
      def remove_item(item)
        index = @items.find_index(item)
        return nil unless index
        @items.delete_at(index)
      end

      # Remove an item by index
      # @param index [Integer] Index of the item to remove
      # @return [Entity, nil] The removed item, or nil if index out of bounds
      def remove_item_at(index)
        return nil if index < 0 || index >= @items.size
        @items.delete_at(index)
      end

      # Get an item by index
      # @param index [Integer] Index of the item to get
      # @return [Entity, nil] The item, or nil if index out of bounds
      def get_item_at(index)
        return nil if index < 0 || index >= @items.size
        @items[index]
      end

      # Find an item by its ID
      # @param id [String] The unique ID of the item to find
      # @return [Entity, nil] The found item, or nil if not found
      def find_by_id(id)
        @items.find { |item| item.id == id }
      end

      # Convert to hash for serialization
      # @return [Hash] The component data as a hash
      def data
        {
          max_size: @max_size,
          items: @items.map(&:to_hash)
        }
      end

      # Create from hash for deserialization
      # @param hash [Hash] The hash data to create from
      # @return [InventoryComponent] The created component
      def self.from_hash(hash)
        new(max_size: hash[:max_size] || 20)
      end
    end

    # Register this component
    Component.register(InventoryComponent)
  end
end