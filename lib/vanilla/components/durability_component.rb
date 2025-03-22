module Vanilla
  module Components
    # Component for items that have durability and can wear out with use
    class DurabilityComponent < Component
      # @return [Integer] The maximum durability value
      attr_reader :max_durability

      # @return [Integer] The current durability value
      attr_reader :current_durability

      # Initialize a new durability component
      # @param max_durability [Integer] The maximum durability value
      # @param current_durability [Integer, nil] The current durability (defaults to max)
      def initialize(max_durability, current_durability = nil)
        super()
        @max_durability = max_durability
        @current_durability = current_durability || max_durability
      end

      # Get the component type
      # @return [Symbol] The component type
      def type
        :durability
      end

      # Modify the current durability
      # @param amount [Integer] Amount to change (positive or negative)
      # @return [Integer] The new durability value
      def modify_durability(amount)
        @current_durability += amount
        @current_durability = 0 if @current_durability < 0
        @current_durability = @max_durability if @current_durability > @max_durability
        @current_durability
      end

      # Set the current durability directly
      # @param value [Integer] The new durability value
      # @return [Integer] The new durability value (clamped to valid range)
      def set_durability(value)
        @current_durability = [[0, value].max, @max_durability].min
        @current_durability
      end

      # Get additional data for serialization
      # @return [Hash] additional data to include in serialization
      def data
        {
          max_durability: @max_durability,
          current_durability: @current_durability
        }
      end

      # Create from hash for deserialization
      # @param hash [Hash] The hash data to create from
      # @return [DurabilityComponent] The created component
      def self.from_hash(hash)
        new(
          hash[:max_durability] || 0,
          hash[:current_durability]
        )
      end
    end

    # Register this component
    Component.register(DurabilityComponent)
  end
end