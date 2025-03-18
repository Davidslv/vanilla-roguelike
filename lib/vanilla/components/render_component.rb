module Vanilla
  module Components
    class RenderComponent < Component
      attr_reader :character, :color, :layer

      def initialize(character:, color: nil, layer: 0)
        @character = character
        @color = color
        @layer = layer
        super()
      end

      def type
        :render
      end

      def data
        {
          character: @character,
          color: @color,
          layer: @layer
        }
      end

      def self.from_hash(hash)
        new(
          character: hash[:character],
          color: hash[:color],
          layer: hash[:layer] || 0
        )
      end
    end

    # Register component
    Component.register(RenderComponent)
  end
end