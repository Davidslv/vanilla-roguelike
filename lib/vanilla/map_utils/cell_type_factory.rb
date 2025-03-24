# frozen_string_literal: true
require_relative 'cell_type'

module Vanilla
  module MapUtils
    # CellTypeFactory implements the Flyweight pattern factory
    # It creates and manages CellType instances, ensuring that
    # identical types are reused rather than duplicated
    class CellTypeFactory
      # Initialize a new factory and setup standard types
      def initialize
        @types = {}
        setup_standard_types
      end

      # Get a cell type by its key identifier
      # @param key [Symbol] The key for the cell type
      # @return [CellType] The requested cell type
      # @raise [ArgumentError] If the key is unknown
      def get_cell_type(key)
        @types[key] or raise ArgumentError, "Unknown cell type: #{key}"
      end

      # Get a cell type by its tile character
      # @param tile_character [String] The tile character
      # @return [CellType] The cell type for this character, or the empty type if not found
      def get_by_character(tile_character)
        # Find the type with matching tile character or default to empty
        @types.values.find { |t| t.tile_character == tile_character } || @types[:empty]
      end

      # Register a new cell type
      # @param key [Symbol] The identifier for this type
      # @param tile_character [String] The character used to render this type
      # @param properties [Hash] Additional properties for this type
      # @return [CellType] The newly created cell type
      def register(key, tile_character, properties = {})
        @types[key] = CellType.new(key, tile_character, properties)
      end

      private

      # Setup the standard cell types used in the game
      def setup_standard_types
        register(:empty, Vanilla::Support::TileType::EMPTY, walkable: true)
        register(:wall, Vanilla::Support::TileType::WALL, walkable: false)
        register(:player, Vanilla::Support::TileType::PLAYER, walkable: true, player: true)
        register(:stairs, Vanilla::Support::TileType::STAIRS, walkable: true, stairs: true)
        register(:door, Vanilla::Support::TileType::DOOR, walkable: true)
        register(:floor, Vanilla::Support::TileType::FLOOR, walkable: true)
        register(:monster, Vanilla::Support::TileType::MONSTER, walkable: false)
        register(:vertical_wall, Vanilla::Support::TileType::VERTICAL_WALL, walkable: false)
      end
    end
  end
end
