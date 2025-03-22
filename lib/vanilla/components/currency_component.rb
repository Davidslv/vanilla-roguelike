module Vanilla
  module Components
    # Component for items that represent currency or valuable treasures
    class CurrencyComponent < Component
      # @return [Symbol] The type of currency (:gold, :silver, etc.)
      attr_reader :currency_type

      # @return [Integer] The monetary value of the currency
      attr_reader :value

      # Initialize a new currency component
      # @param value [Integer] The monetary value of the currency
      # @param currency_type [Symbol] The type of currency (:gold, :silver, etc.)
      def initialize(value, currency_type = :gold)
        super()
        @value = value
        @currency_type = currency_type
      end

      # Get the component type
      # @return [Symbol] The component type
      def type
        :currency
      end

      # Set the value
      # @param new_value [Integer] The new monetary value
      # @return [Integer] The updated value
      def set_value(new_value)
        @value = [0, new_value].max
        @value
      end

      # Modify the value
      # @param amount [Integer] The amount to change by (positive or negative)
      # @return [Integer] The updated value
      def modify_value(amount)
        @value = [0, @value + amount].max
        @value
      end

      # Get additional data for serialization
      # @return [Hash] additional data to include in serialization
      def data
        {
          value: @value,
          currency_type: @currency_type
        }
      end

      # Create from hash for deserialization
      # @param hash [Hash] The hash data to create from
      # @return [CurrencyComponent] The created component
      def self.from_hash(hash)
        new(
          hash[:value] || 0,
          hash[:currency_type] || :gold
        )
      end
    end

    # Register this component
    Component.register(CurrencyComponent)
  end
end