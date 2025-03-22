module Vanilla
  module Components
    # Component for tracking whether an entity has found stairs
    class StairsComponent < Component
      # @return [Boolean] whether stairs have been found
      attr_reader :found_stairs

      alias found_stairs? found_stairs

      # Initialize a new stairs component
      # @param found_stairs [Boolean] whether stairs have been found
      def initialize(found_stairs: false)
        super()
        @found_stairs = found_stairs
      end

      # @return [Symbol] the component type
      def type
        :stairs
      end

      # Set the found_stairs status
      # @param value [Boolean] whether stairs have been found
      # @return [Boolean] the new found_stairs status
      def set_found_stairs(value)
        @found_stairs = !!value
      end

      # @return [Hash] serialized component data
      def data
        {
          found_stairs: @found_stairs
        }
      end

      # Create a stairs component from a hash
      # @param hash [Hash] serialized component data
      # @return [StairsComponent] deserialized component
      def self.from_hash(hash)
        new(found_stairs: hash[:found_stairs])
      end
    end

    # Register this component type
    Component.register(StairsComponent)
  end
end