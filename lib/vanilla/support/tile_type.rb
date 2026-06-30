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
        GOLD = '$'.freeze,
        DRAGON = 'D'.freeze
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

        # Actors share a cell when they meet: the player steps onto a MONSTER's
        # tile to attack it, and a hunting monster steps onto the PLAYER's tile
        # to reach them (which triggers the combat menu via collision). Both
        # actor tiles are therefore walkable.
        [MONSTER, PLAYER, EMPTY, FLOOR, DOOR, STAIRS, GOLD].include?(tile)
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
