# frozen_string_literal: true
module Vanilla
  module Components
    # Component for items that can unlock doors, chests, or other locked objects
    class KeyComponent
      attr_reader :key_id, :lock_type, :one_time_use

      # Initialize a new key component
      # @param key_id [String] Unique identifier for the key matched to the lock
      # @param lock_type [Symbol] Type of lock this key opens (:door, :chest, :gate, etc.)
      # @param one_time_use [Boolean] Whether the key is consumed after use
      def initialize(key_id, lock_type = :door, one_time_use = true)
        @key_id = key_id
        @lock_type = lock_type
        @one_time_use = one_time_use
      end

      # Get the component type
      # @return [Symbol] The component type
      def type
        :key
      end

      # Check if this key matches a specific lock
      # @param lock_id [String] The ID of the lock to check
      # @param lock_type [Symbol] The type of the lock to check
      # @return [Boolean] Whether this key can open that lock
      def matches?(lock_id, lock_type = nil)
        # Match by ID and optionally by type
        matches_id = (@key_id == lock_id)
        matches_type = (lock_type.nil? || @lock_type == lock_type)

        matches_id && matches_type
      end

      # Use the key to unlock something
      # @param lock_id [String] The ID of the lock to open
      # @param lock_type [Symbol] The type of lock to open
      # @return [Boolean] Whether the unlock was successful
      def unlock(lock_id, lock_type = nil)
        return false unless matches?(lock_id, lock_type)

        # Notify via message system if available
        message_system = Vanilla::ServiceRegistry.get(:message_system) rescue nil
        if message_system
          message_system.log_message("items.key.unlock",
                                     metadata: { lock_type: lock_type || @lock_type },
                                     importance: :success,
                                     category: :item)
        end

        # Return whether the key should be consumed
        @one_time_use
      end

      # Get descriptive text for the key
      # @return [String] Description of what this key unlocks
      def description
        consumed_text = @one_time_use ? " (consumed on use)" : ""
        "Opens a #{@lock_type}#{consumed_text}"
      end

      # Convert to hash for serialization
      # @return [Hash] The component data as a hash
      def to_hash
        {
          type: type,
          key_id: @key_id,
          lock_type: @lock_type,
          one_time_use: @one_time_use
        }
      end

      # Create from hash for deserialization
      # @param hash [Hash] The hash data to create from
      # @return [KeyComponent] The created component
      def self.from_hash(hash)
        new(
          hash[:key_id] || "generic_key",
          hash[:lock_type] || :door,
          hash[:one_time_use].nil? ? true : hash[:one_time_use]
        )
      end
    end

    # Register this component
    Component.register(KeyComponent)
  end
end
