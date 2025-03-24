# frozen_string_literal: true
module Vanilla
  module Support
    class TileType
      VALUES = [
        EMPTY   = ' '.freeze,
        WALL    = '#'.freeze,
        DOOR    = '/'.freeze,
        FLOOR   = '.'.freeze,
        PLAYER  = '@'.freeze,
        MONSTER = 'M'.freeze,
        STAIRS  = '%'.freeze,
        VERTICAL_WALL = '|'.freeze,
        GOLD    = '$'.freeze
      ].freeze

      def self.values
        VALUES
      end

      # Check if the provided tile is a valid tile type
      # @param tile [String] The tile character to check
      # @return [Boolean] true if the tile is valid, false otherwise
      def self.valid?(tile)
        VALUES.include?(tile)
      end

      def self.walkable?(tile)
        return false unless valid?(tile)

        # FIX: Treat MONSTER as walkable tile
        # Temporary workaround: Treat MONSTER as walkable until a combat system is implemented.
        # This ensures players can navigate mazes when the only path to stairs crosses a monster.
        [MONSTER, EMPTY, FLOOR, DOOR, STAIRS, GOLD].include?(tile)
      end

      # Check if the tile is a wall type (blocks movement)
      # @param tile [String] The tile character to check
      # @return [Boolean] true if the tile is a wall type, false otherwise
      def self.wall?(tile)
        return false unless valid?(tile)

        [WALL, VERTICAL_WALL].include?(tile)
      end
    end
  end
end
