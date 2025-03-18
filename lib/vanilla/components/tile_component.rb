module Vanilla
  module Components
    # Component for tracking an entity's visual representation
    class TileComponent < Component
      # @return [String] the visual representation character
      attr_reader :tile

      # Initialize a new tile component
      # @param tile [String] the tile character
      def initialize(tile: Vanilla::Support::TileType::EMPTY)
        change_tile(tile)
      end

      # @return [Symbol] the component type
      def type
        :tile
      end

      # Change the tile character
      # @param new_tile [String] the new tile character
      # @raise [ArgumentError] if the tile is invalid
      def change_tile(new_tile)
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