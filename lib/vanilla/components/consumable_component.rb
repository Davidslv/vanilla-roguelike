# frozen_string_literal: true

module Vanilla
  module Components
    # Component for items that can be consumed/used and have effects
    class ConsumableComponent < Component
      attr_reader :charges, :effects, :auto_identify

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

      # Convert to hash for serialization
      # @return [Hash] The component data as a hash
      def to_hash
        {
          type: type,
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
