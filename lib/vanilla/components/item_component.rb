# frozen_string_literal: true

module Vanilla
  module Components
    # Component for items that can be picked up, used, and stored in inventory
    class ItemComponent < Components::Component
      attr_reader :name, :description, :item_type, :weight, :value
      attr_accessor :stack_size

      # Initialize a new item component
      # @param name [String] The display name of the item
      # @param description [String] The item description
      # @param item_type [Symbol] The type of item (:weapon, :armor, :potion, etc.)
      # @param weight [Integer] The weight of the item
      # @param value [Integer] The value of the item in currency
      # @param stackable [Boolean] Whether the item can be stacked
      # @param stack_size [Integer] The current stack size for stackable items
      def initialize(name:,
                     description: "",
                     item_type: :misc,
                     weight: 1,
                     value: 0,
                     stackable: false,
                     stack_size: 1)
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

      # Convert to hash for serialization
      # @return [Hash] The component data as a hash
      def to_hash
        {
          type: type,
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
