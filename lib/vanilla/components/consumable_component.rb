module Vanilla
  module Components
    # Component for items that can be consumed/used and have effects
    class ConsumableComponent < Component
      # @return [Integer] Number of uses before the item is consumed
      attr_reader :charges

      # @return [Array<Hash>] Effects that occur when used
      attr_reader :effects

      # @return [Boolean] Whether the item is identified on pickup
      attr_reader :auto_identify

      # Initialize a new consumable component
      # @param charges [Integer] Number of uses before the item is consumed
      # @param effects [Array<Hash>] Effects that occur when used
      # @param auto_identify [Boolean] Whether the item is identified on pickup
      def initialize(charges: 1, effects: [], auto_identify: false)
        super()
        @charges = charges
        @effects = effects
        @auto_identify = auto_identify
      end

      # Get the component type
      # @return [Symbol] The component type
      def type
        :consumable
      end

      # Check if the item still has charges remaining
      # @return [Boolean] Whether the item has charges left
      def has_charges?
        @charges > 0
      end

      # Reduce the number of charges by one
      # @return [Integer] The new number of charges
      def use_charge
        @charges = [@charges - 1, 0].max
        @charges
      end

      # Add charges to the consumable
      # @param amount [Integer] Number of charges to add
      # @return [Integer] The new number of charges
      def add_charges(amount)
        @charges += amount if amount > 0
        @charges
      end

      # Get additional data for serialization
      # @return [Hash] additional data to include in serialization
      def data
        {
          charges: @charges,
          effects: @effects,
          auto_identify: @auto_identify
        }
      end

      # Create from hash for deserialization
      # @param hash [Hash] The hash data to create from
      # @return [ConsumableComponent] The created component
      def self.from_hash(hash)
        new(
          charges: hash[:charges] || 1,
          effects: hash[:effects] || [],
          auto_identify: hash[:auto_identify] || false
        )
      end
    end

    # Register this component with the Component registry
    Component.register(ConsumableComponent)
  end
end