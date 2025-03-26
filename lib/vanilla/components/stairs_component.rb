# frozen_string_literal: true

module Vanilla
  module Components
    # Component for tracking whether an entity has found stairs
    class StairsComponent < Component
      # @return [Boolean] whether stairs have been found
      attr_accessor :found_stairs

      alias found_stairs? found_stairs

      # Initialize a new stairs component
      # @param found_stairs [Boolean] whether stairs have been found
      def initialize(found_stairs: false)
        super()
        @type = :stairs
      end

      # @return [Symbol] the component type
      def type
        @type
      end

      # @return [Hash] serialized component data
      def to_hash
        {
          type: @type,
        }
      end

      # Create a stairs component from a hash
      # @param hash [Hash] serialized component data
      # @return [StairsComponent] deserialized component
      def self.from_hash(hash)
        new
      end
    end

    # Register this component type
    Component.register(StairsComponent)
  end
end
