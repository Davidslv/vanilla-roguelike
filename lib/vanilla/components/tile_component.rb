module Vanilla
  module Components
    # Component for tracking an entity's visual representation
    #
    # @deprecated Use RenderComponent instead which provides better visual representation control
    class TileComponent < Component
      # @return [String] the visual representation character
      attr_reader :tile

      # Initialize a new tile component
      # @param tile [String] the tile character
      def initialize(tile: Vanilla::Support::TileType::EMPTY)
        super()
        # Log deprecation warning
        Vanilla::Logger.instance.warn("TileComponent is deprecated. Use RenderComponent instead.")
        set_tile(tile)
      end

      # @return [Symbol] the component type
      def type
        :tile
      end

      # Set the tile character
      # @param new_tile [String] the new tile character
      # @raise [ArgumentError] if the tile is invalid
      # @return [String] The tile character
      def set_tile(new_tile)
        unless Vanilla::Support::TileType.valid?(new_tile)
          raise ArgumentError, "Invalid tile type: #{new_tile}"
        end

        @tile = new_tile
      end

      # @return [Hash] serialized component data
      def data
        {
          tile: @tile
        }
      end

      # Create a tile component from a hash
      # @param hash [Hash] serialized component data
      # @return [TileComponent] deserialized component
      def self.from_hash(hash)
        new(tile: hash[:tile])
      end
    end

    # Register this component type
    Component.register(TileComponent)
  end
end