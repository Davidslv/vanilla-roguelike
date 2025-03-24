# frozen_string_literal: true

module Vanilla
  module Components
    # Component for items that can be equipped by entities
    class EquippableComponent < Component
      attr_reader :slot, :stat_modifiers
      attr_accessor :equipped

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

      # Convert to hash for serialization
      # @return [Hash] The component data as a hash
      def to_hash
        {
          type: type,
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

      def validate_slot
        raise ArgumentError, "Invalid slot: #{@slot}. Valid slots: #{SLOTS.join(', ')}" unless SLOTS.include?(@slot)
      end
    end

    # Register this component
    Component.register(EquippableComponent)
  end
end
