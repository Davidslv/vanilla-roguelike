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

      # Check if the item still has charges remaining
      # @return [Boolean] Whether the item has charges left
      def has_charges?
        @charges > 0
      end

      # Consume the item and apply its effects
      # @param entity [Entity] The entity consuming the item
      # @return [Boolean] Whether the item was successfully consumed
      def consume(entity)
        return false unless has_charges?
        return false unless entity

        # Apply each effect to the entity
        success = apply_effects(entity)

        # Reduce charges only if the effects were applied
        if success
          @charges -= 1
        end

        success
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

      # Apply the effects of the consumable to an entity
      # @param entity [Entity] The entity to apply effects to
      # @return [Boolean] Whether the effects were successfully applied
      def apply_effects(entity)
        # Get the message system if it exists
        message_system = Vanilla::ServiceRegistry.get(:message_system) rescue nil

        # Track success of applying effects
        all_applied = true

        # Apply each effect
        @effects.each do |effect|
          applied = case effect[:type]
                   when :heal
                     heal_entity(entity, effect[:amount])
                   when :damage
                     damage_entity(entity, effect[:amount], effect[:damage_type])
                   when :buff
                     apply_buff(entity, effect[:stat], effect[:amount], effect[:duration])
                   when :teleport
                     teleport_entity(entity)
                   else
                     false
                   end

          # If any effect fails, the overall consumption fails
          all_applied = false unless applied

          # Log the effect if successful and message system exists
          if applied && message_system
            message_system.log_message("items.effect.#{effect[:type]}",
                                     {category: :item, importance: :success,
                                      metadata: {amount: effect[:amount], stat: effect[:stat]}})
          end
        end

        all_applied
      end

      # Heal an entity
      # @param entity [Entity] The entity to heal
      # @param amount [Integer] The amount to heal
      # @return [Boolean] Whether the healing was applied
      def heal_entity(entity, amount)
        # For now just log the healing - actual health system will be implemented later
        true
      end

      # Damage an entity
      # @param entity [Entity] The entity to damage
      # @param amount [Integer] The amount of damage
      # @param damage_type [Symbol] The type of damage
      # @return [Boolean] Whether the damage was applied
      def damage_entity(entity, amount, damage_type = :physical)
        # For now just log the damage - actual damage system will be implemented later
        true
      end

      # Apply a stat buff to an entity
      # @param entity [Entity] The entity to buff
      # @param stat [Symbol] The stat to buff
      # @param amount [Integer] The amount to increase the stat
      # @param duration [Integer] How many turns the buff lasts
      # @return [Boolean] Whether the buff was applied
      def apply_buff(entity, stat, amount, duration)
        # For now just log the buff - actual buff system will be implemented later
        true
      end

      # Teleport an entity to a random location
      # @param entity [Entity] The entity to teleport
      # @return [Boolean] Whether the teleport was successful
      def teleport_entity(entity)
        # For now just log the teleport - actual teleport will be implemented later
        true
      end
    end

    # Register this component with the Component registry
    Component.register(ConsumableComponent)
  end
end