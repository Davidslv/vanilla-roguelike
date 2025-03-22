module Vanilla
  module Components
    # Component for managing temporary effects/buffs on entities
    class EffectComponent < Component
      # @return [Array<Hash>] Active effects on the entity
      attr_reader :active_effects

      # Initialize a new effect component
      # @param active_effects [Array<Hash>] Initial active effects
      def initialize(active_effects = [])
        @active_effects = active_effects.dup
        super()
      end

      # Get the component type
      # @return [Symbol] The component type
      def type
        :effect
      end

      # Add a new effect without logic
      # @param effect [Hash] The effect to add
      # @return [Array<Hash>] The updated active effects
      def add_effect_data(effect)
        @active_effects << effect
        @active_effects
      end

      # Remove an effect by its index without logic
      # @param index [Integer] The index of the effect to remove
      # @return [Hash, nil] The removed effect or nil if not found
      def remove_effect_at(index)
        return nil if index < 0 || index >= @active_effects.size
        @active_effects.delete_at(index)
      end

      # Remove all effects matching a predicate
      # @param predicate [Proc] Block that returns true for effects to remove
      # @return [Array<Hash>] The removed effects
      def remove_effects_by(&predicate)
        removed = []
        @active_effects.reject! do |effect|
          if predicate.call(effect)
            removed << effect
            true
          else
            false
          end
        end
        removed
      end

      # Set the entire effects array
      # @param effects [Array<Hash>] The new effects array
      # @return [Array<Hash>] The new active effects
      def set_active_effects(effects)
        @active_effects = effects.dup
        @active_effects
      end

      # Get additional data for serialization
      # @return [Hash] additional data to include in serialization
      def data
        {
          active_effects: @active_effects
        }
      end

      # Create from hash for deserialization
      # @param hash [Hash] The hash data to create from
      # @return [EffectComponent] The created component
      def self.from_hash(hash)
        new(hash[:active_effects] || [])
      end
    end

    # Register this component
    Component.register(EffectComponent)
  end
end