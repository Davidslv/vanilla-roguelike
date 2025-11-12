# frozen_string_literal: true

require_relative "component"
require "set"

module Vanilla
  module Components
    # Component that tracks field of view and exploration state
    # Stores which tiles are currently visible and which have been explored
    class VisibilityComponent < Component
      attr_accessor :vision_radius, :visible_tiles, :explored_tiles, :blocks_vision

      def initialize(vision_radius: 8, blocks_vision: false)
        super()
        @vision_radius = vision_radius
        @visible_tiles = Set.new
        @explored_tiles = Set.new
        @blocks_vision = blocks_vision
      end

      def type
        :visibility
      end

      # Add a tile to the visible set
      def add_visible_tile(row, col)
        @visible_tiles.add([row, col])
      end

      # Clear all currently visible tiles
      def clear_visible_tiles
        @visible_tiles.clear
      end

      # Check if a tile is currently visible
      def tile_visible?(row, col)
        @visible_tiles.include?([row, col])
      end

      # Check if a tile has been explored
      def tile_explored?(row, col)
        @explored_tiles.include?([row, col])
      end

      def to_hash
        {
          vision_radius: @vision_radius,
          blocks_vision: @blocks_vision,
          visible_tiles: @visible_tiles.to_a,
          explored_tiles: @explored_tiles.to_a
        }
      end

      def self.from_hash(hash)
        component = new(
          vision_radius: hash[:vision_radius],
          blocks_vision: hash[:blocks_vision]
        )
        component.visible_tiles = Set.new(hash[:visible_tiles] || [])
        component.explored_tiles = Set.new(hash[:explored_tiles] || [])
        component
      end
    end
  end
end
