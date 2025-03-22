module Vanilla
  module Components
    # Component for items that can be picked up, used, and stored in inventory
    class ItemComponent < Component
      # @return [String] The display name of the item
      attr_reader :name

      # @return [String] The item description
      attr_reader :description

      # @return [Symbol] The type of item (:weapon, :armor, :potion, etc.)
      attr_reader :item_type

      # @return [Integer] The weight of the item
      attr_reader :weight

      # @return [Integer] The value of the item in currency
      attr_reader :value

      # @return [Boolean] Whether the item can be stacked
      attr_reader :stackable

      # @return [Integer] The current stack size for stackable items
      attr_reader :stack_size

      # Initialize a new item component
      # @param name [String] The display name of the item
      # @param description [String] The item description
      # @param item_type [Symbol] The type of item (:weapon, :armor, :potion, etc.)
      # @param weight [Integer] The weight of the item
      # @param value [Integer] The value of the item in currency
      # @param stackable [Boolean] Whether the item can be stacked
      # @param stack_size [Integer] The current stack size for stackable items
      def initialize(name:, description: "", item_type: :misc, weight: 1,
                     value: 0, stackable: false, stack_size: 1)
        super()
        @name = name
        @description = description
        @item_type = item_type
        @weight = weight
        @value = value
        @stackable = stackable
        @stack_size = stack_size
      end

      # Get the component type
      # @return [Symbol] The component type
      def type
        :item
      end

      # Check if the item is stackable
      # @return [Boolean] Whether the item can be stacked
      def stackable?
        @stackable
      end

      # Modify the stack size
      # @param amount [Integer] Amount to change the stack by (positive or negative)
      # @return [Integer] The new stack size
      def modify_stack(amount)
        if @stackable
          @stack_size = [@stack_size + amount, 1].max
        end
        @stack_size
      end

      # Set the stack size directly
      # @param size [Integer] The new stack size
      # @return [Integer] The new stack size
      def set_stack_size(size)
        @stack_size = [size, 1].max if @stackable
        @stack_size
      end

      # Get additional data for serialization
      # @return [Hash] additional data to include in serialization
      def data
        {
          name: @name,
          description: @description,
          item_type: @item_type,
          weight: @weight,
          value: @value,
          stackable: @stackable,
          stack_size: @stack_size
        }
      end

      # Create from hash for deserialization
      # @param hash [Hash] The hash data to create from
      # @return [ItemComponent] The created component
      def self.from_hash(hash)
        new(
          name: hash[:name] || "Unknown Item",
          description: hash[:description] || "",
          item_type: hash[:item_type] || :misc,
          weight: hash[:weight] || 1,
          value: hash[:value] || 0,
          stackable: hash[:stackable] || false,
          stack_size: hash[:stack_size] || 1
        )
      end
    end

    # Register this component
    Component.register(ItemComponent)
  end
end