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

      # Check if the item is currently equipped
      # @return [Boolean] Whether the item is equipped
      def equipped?
        @equipped
      end

      # Equip the item on the target entity
      # @param entity [Entity] The entity equipping the item
      # @return [Boolean] Whether the item was successfully equipped
      def equip(entity)
        return false if @equipped
        return false unless entity

        # Check if there's already an item in this slot
        if slot_occupied?(entity)
          # Can't equip this item until the slot is empty
          return false
        end

        # Apply stat modifiers
        apply_stat_modifiers(entity, @stat_modifiers)

        @equipped = true
        true
      end

      # Unequip the item from the target entity
      # @param entity [Entity] The entity unequipping the item
      # @return [Boolean] Whether the item was successfully unequipped
      def unequip(entity)
        return false unless @equipped
        return false unless entity

        # Remove stat modifiers
        remove_stat_modifiers(entity, @stat_modifiers)

        @equipped = false
        true
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

      # Check if the specified slot is valid
      def validate_slot
        unless SLOTS.include?(@slot)
          raise ArgumentError, "Invalid equipment slot: #{@slot}. Valid slots are: #{SLOTS.join(', ')}"
        end
      end

      # Check if the entity already has an item equipped in this slot
      # @param entity [Entity] The entity to check
      # @return [Boolean] Whether the slot is occupied
      def slot_occupied?(entity)
        return false unless entity.has_component?(:inventory)

        inventory = entity.get_component(:inventory)

        # Get all equipped items
        equipped_items = inventory.items.select do |item|
          item.has_component?(:equippable) &&
          item.get_component(:equippable).equipped? &&
          item.get_component(:equippable).slot == @slot
        end

        !equipped_items.empty?
      end

      # Apply stat modifiers to an entity
      # @param entity [Entity] The entity to modify
      # @param modifiers [Hash] The stat modifiers to apply
      def apply_stat_modifiers(entity, modifiers)
        # No-op for now - stats will be handled by a future stats component
      end

      # Remove stat modifiers from an entity
      # @param entity [Entity] The entity to modify
      # @param modifiers [Hash] The stat modifiers to remove
      def remove_stat_modifiers(entity, modifiers)
        # No-op for now - stats will be handled by a future stats component
      end
    end

    # Register this component
    Component.register(EquippableComponent)
  end
end