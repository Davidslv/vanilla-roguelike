# frozen_string_literal: true

module Vanilla
  module Components
    # Component for managing temporary effects/buffs on entities
    class EffectComponent
      attr_reader :active_effects

      # Initialize a new effect component
      # @param active_effects [Array<Hash>] Initial active effects
      def initialize(active_effects = [])
        @active_effects = active_effects
      end

      # Get the component type
      # @return [Symbol] The component type
      def type
        :effect
      end

      # Add a new effect to the entity
      # @param effect_type [Symbol] The type of effect (:heal, :buff, etc.)
      # @param effect_value [Integer] The magnitude of the effect
      # @param duration [Integer] How many turns the effect lasts (0 for instant)
      # @param source [String, Symbol] What caused this effect (item name, spell, etc.)
      # @param metadata [Hash] Additional effect data
      # @return [Hash] The added effect
      def add_effect(effect_type, effect_value, duration = 0, source = nil, metadata = {})
        # Create the effect hash
        effect = {
          type: effect_type,
          value: effect_value,
          duration: duration,
          source: source,
          metadata: metadata,
          applied_at: Vanilla.game_turn
        }

        # Add to active effects if it has a duration
        if duration > 0
          @active_effects << effect

          # Notify via message system if available
          message_system = Vanilla::ServiceRegistry.get(:message_system) rescue nil
          if message_system
            message_system.log_message("effects.applied",
                                       metadata: {
                                         effect_type: effect_type,
                                         value: effect_value,
                                         source: source
                                       },
                                       importance: :normal,
                                       category: :effect)
          end
        end

        effect
      end

      # Remove an effect by its index
      # @param index [Integer] The index of the effect to remove
      # @return [Hash, nil] The removed effect or nil if not found
      def remove_effect(index)
        return nil if index < 0 || index >= @active_effects.size

        removed = @active_effects.delete_at(index)

        # Notify via message system if available
        message_system = Vanilla::ServiceRegistry.get(:message_system) rescue nil
        if message_system && removed
          message_system.log_message("effects.removed",
                                     metadata: {
                                       effect_type: removed[:type],
                                       source: removed[:source]
                                     },
                                     importance: :normal,
                                     category: :effect)
        end

        removed
      end

      # Remove all effects from a specific source
      # @param source [String, Symbol] The source of effects to remove
      # @return [Array<Hash>] The removed effects
      def remove_effects_by_source(source)
        removed = []

        @active_effects.reject! do |effect|
          if effect[:source] == source
            removed << effect
            true
          else
            false
          end
        end

        # Notify via message system if available
        message_system = Vanilla::ServiceRegistry.get(:message_system) rescue nil
        if message_system && !removed.empty?
          message_system.log_message("effects.removed_source",
                                     metadata: { source: source, count: removed.size },
                                     importance: :normal,
                                     category: :effect)
        end

        removed
      end

      # Remove all expired effects based on the current turn
      # @return [Array<Hash>] The expired effects that were removed
      def remove_expired_effects
        current_turn = Vanilla.game_turn
        expired = []

        @active_effects.reject! do |effect|
          # Check if the effect has expired
          if effect[:duration] > 0 && effect[:applied_at] + effect[:duration] <= current_turn
            expired << effect
            true
          else
            false
          end
        end

        # Notify via message system if available
        message_system = Vanilla::ServiceRegistry.get(:message_system) rescue nil
        if message_system && !expired.empty?
          expired.each do |effect|
            message_system.log_message("effects.expired",
                                       metadata: {
                                         effect_type: effect[:type],
                                         source: effect[:source]
                                       },
                                       importance: :normal,
                                       category: :effect)
          end
        end

        expired
      end

      # Get all effects of a specific type
      # @param effect_type [Symbol] The type of effect to look for
      # @return [Array<Hash>] All effects of that type
      def get_effects_by_type(effect_type)
        @active_effects.select { |effect| effect[:type] == effect_type }
      end

      # Check if there are any active effects
      # @return [Boolean] Whether there are any active effects
      def has_active_effects?
        !@active_effects.empty?
      end

      # Get the total modifier for a specific stat from all active effects
      # @param stat [Symbol] The stat to get modifiers for
      # @return [Integer] The sum of all stat modifiers
      def get_stat_modifier(stat)
        @active_effects.sum do |effect|
          if effect[:type] == :buff && effect[:metadata][:stat] == stat
            effect[:value]
          else
            0
          end
        end
      end

      # Update effects (remove expired ones)
      # Called once per game turn
      def update
        remove_expired_effects
      end

      # Convert to hash for serialization
      # @return [Hash] The component data as a hash
      def to_hash
        {
          type: type,
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
