module Vanilla
  module Components
    # Component for items that can be equipped by entities
    class EquippableComponent < Component
      # @return [Symbol] The equipment slot this item fits into
      attr_reader :slot

      # @return [Hash] Stats this item modifies when equipped
      attr_reader :stat_modifiers

      # @return [Boolean] Whether the item is currently equipped
      attr_reader :equipped

      # Valid equipment slots
      SLOTS = [:head, :body, :left_hand, :right_hand, :both_hands, :neck, :feet, :ring, :hands]

      # Initialize a new equippable component
      # @param slot [Symbol] The equipment slot this item fits into
      # @param stat_modifiers [Hash] Stats this item modifies when equipped
      # @param equipped [Boolean] Whether the item is currently equipped
      def initialize(slot:, stat_modifiers: {}, equipped: false)
        super()
        @slot = slot
        @stat_modifiers = stat_modifiers
        @equipped = equipped

        validate_slot
      end

      # Get the component type
      # @return [Symbol] The component type
      def type
        :equippable
      end

      # Check if the item is currently equipped
      # @return [Boolean] Whether the item is equipped
      def equipped?
        @equipped
      end

      # Set the equipped status
      # @param value [Boolean] Whether the item is equipped
      # @return [Boolean] The new equipped status
      def set_equipped(value)
        @equipped = !!value
      end

      # Get additional data for serialization
      # @return [Hash] additional data to include in serialization
      def data
        {
          slot: @slot,
          stat_modifiers: @stat_modifiers,
          equipped: @equipped
        }
      end

      # Create from hash for deserialization
      # @param hash [Hash] The hash data to create from
      # @return [EquippableComponent] The created component
      def self.from_hash(hash)
        new(
          slot: hash[:slot] || :misc,
          stat_modifiers: hash[:stat_modifiers] || {},
          equipped: hash[:equipped] || false
        )
      end

      private

      # Check if the specified slot is valid
      def validate_slot
        unless SLOTS.include?(@slot)
          raise ArgumentError, "Invalid equipment slot: #{@slot}. Valid slots are: #{SLOTS.join(', ')}"
        end
      end
    end

    # Register this component
    Component.register(EquippableComponent)
  end
end