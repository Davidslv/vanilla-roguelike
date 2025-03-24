module Vanilla
  module MapUtils
    # CellType implements the Flyweight pattern for cell types
    # It stores the intrinsic (shared) state of cells, such as
    # the tile character and properties like walkability
    class CellType
      attr_reader :key, :tile_character, :properties

      # Initialize a new cell type
      # @param key [Symbol] The key identifier for this cell type
      # @param tile_character [String] The character used to render this cell type
      # @param properties [Hash] Additional properties for this cell type
      def initialize(key, tile_character, properties = {})
        @key = key
        @tile_character = tile_character
        @properties = properties.freeze
      end

      # Check if this cell type is walkable
      # @return [Boolean] True if walkable, false otherwise
      def walkable?
        @properties.fetch(:walkable, true)
      end

      # Check if this cell type represents stairs
      # @return [Boolean] True if stairs, false otherwise
      def stairs?
        @properties.fetch(:stairs, false)
      end

      # Check if this cell type represents a player
      # @return [Boolean] True if player, false otherwise
      def player?
        @properties.fetch(:player, false)
      end

      # Get the character to render for this cell type
      # @return [String] The tile character
      def to_s
        @tile_character
      end
    end
  end
end
