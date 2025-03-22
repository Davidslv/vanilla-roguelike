module Vanilla
  module Components
    # Component for items that represent currency or valuable treasures
    class CurrencyComponent
      attr_reader :currency_type
      attr_accessor :value

      # Initialize a new currency component
      # @param value [Integer] The monetary value of the currency
      # @param currency_type [Symbol] The type of currency (:gold, :silver, etc.)
      def initialize(value, currency_type = :gold)
        @value = value
        @currency_type = currency_type
      end

      # Get the component type
      # @return [Symbol] The component type
      def type
        :currency
      end

      # Combine with another currency component
      # @param other [CurrencyComponent] Another currency component to combine with
      # @return [Integer] The new value after combining
      def combine(other)
        return @value unless other.is_a?(CurrencyComponent) && other.currency_type == @currency_type

        @value += other.value
      end

      # Split off a portion of the currency
      # @param amount [Integer] The amount to split off
      # @return [Integer, nil] The amount split off, or nil if not enough
      def split(amount)
        return nil if amount > @value

        @value -= amount
        amount
      end

      # Get the display string for the currency
      # @return [String] A formatted string showing value and type
      def display_string
        case @currency_type
        when :gold
          "#{@value} gold coin#{@value > 1 ? 's' : ''}"
        when :silver
          "#{@value} silver coin#{@value > 1 ? 's' : ''}"
        when :copper
          "#{@value} copper coin#{@value > 1 ? 's' : ''}"
        when :gem
          "#{@value} #{@value > 1 ? 'gems' : 'gem'}"
        else
          "#{@value} #{@currency_type}"
        end
      end

      # Get the currency value adjusted by type
      # @return [Integer] The standardized value in gold
      def standard_value
        case @currency_type
        when :copper
          (@value.to_f / 100).ceil  # 100 copper = 1 gold
        when :silver
          (@value.to_f / 10).ceil   # 10 silver = 1 gold
        when :gold
          @value
        when :gem
          @value * 5                # 1 gem = 5 gold
        else
          @value
        end
      end

      # Convert to hash for serialization
      # @return [Hash] The component data as a hash
      def to_hash
        {
          type: type,
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