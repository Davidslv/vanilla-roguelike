module Vanilla
  module Components
    # Component for items that can unlock doors, chests, or other locked objects
    class KeyComponent < Component
      # @return [String] Unique identifier for the key matched to the lock
      attr_reader :key_id

      # @return [Symbol] Type of lock this key opens (:door, :chest, :gate, etc.)
      attr_reader :lock_type

      # @return [Boolean] Whether the key is consumed after use
      attr_reader :one_time_use

      # Initialize a new key component
      # @param key_id [String] Unique identifier for the key matched to the lock
      # @param lock_type [Symbol] Type of lock this key opens (:door, :chest, :gate, etc.)
      # @param one_time_use [Boolean] Whether the key is consumed after use
      def initialize(key_id, lock_type = :door, one_time_use = true)
        super()
        @key_id = key_id
        @lock_type = lock_type
        @one_time_use = one_time_use
      end

      # Get the component type
      # @return [Symbol] The component type
      def type
        :key
      end

      # Get additional data for serialization
      # @return [Hash] additional data to include in serialization
      def data
        {
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