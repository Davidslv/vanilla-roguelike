# frozen_string_literal: true

require_relative "system"

module Vanilla
  module Systems
    # Field of View System using simple circle-based algorithm with line-of-sight checks
    # Calculates which tiles are visible from an entity's position
    class FOVSystem < System
      def initialize(world, grid = nil)
        super(world)
        @grid = grid
      end

      def update(delta_time)
        # Get grid from world's current level (dynamically)
        @grid ||= @world.current_level&.grid
        return unless @grid # Skip if no grid available yet

        entities_with(:visibility, :position).each do |entity|
          # Skip FOV calculation if dev mode enabled
          next if dev_mode_active?(entity)

          calculate_fov(entity)
          update_explored_tiles(entity)
        end
      end

      # Calculate field of view for an entity
      # Uses a simple circle algorithm: check all tiles within radius
      # and verify line of sight using Bresenham-style line tracing
      def calculate_fov(entity)
        position = entity.get_component(:position)
        visibility = entity.get_component(:visibility)
        radius = visibility.vision_radius

        # Clear current visible tiles
        visibility.clear_visible_tiles

        # Player's tile is always visible
        visibility.add_visible_tile(position.row, position.column)

        # Check all tiles in a square around the player
        (-radius..radius).each do |dr|
          (-radius..radius).each do |dc|
            target_row = position.row + dr
            target_col = position.column + dc

            # Skip tiles outside the circle (use squared distance)
            distance_sq = dr * dr + dc * dc
            next if distance_sq > radius * radius

            # Skip out of bounds
            next unless in_bounds?(target_row, target_col)

            # Check if there's a clear line of sight to this tile
            if has_line_of_sight?(position.row, position.column, target_row, target_col)
              visibility.add_visible_tile(target_row, target_col)
            end
          end
        end
      end

      private

      # Check if there's a clear line of sight between two points
      # Uses Bresenham's line algorithm
      def has_line_of_sight?(from_row, from_col, to_row, to_col)
        # Use Bresenham's line algorithm to trace the path
        points = bresenham_line(from_row, from_col, to_row, to_col)

        # Check each point along the line (except the target)
        points[0..-2].each do |row, col|
          # If we hit a blocking tile before reaching the target, no line of sight
          return false if blocks_vision?(row, col)
        end

        # We reached the target without hitting a blocker
        true
      end

      # Bresenham's line algorithm - returns array of [row, col] points
      def bresenham_line(row0, col0, row1, col1)
        points = []

        dx = (col1 - col0).abs
        dy = (row1 - row0).abs

        sx = col0 < col1 ? 1 : -1
        sy = row0 < row1 ? 1 : -1

        err = dx - dy
        row = row0
        col = col0

        loop do
          points << [row, col]

          break if row == row1 && col == col1

          e2 = 2 * err

          if e2 > -dy
            err -= dy
            col += sx
          end

          if e2 < dx
            err += dx
            row += sy
          end
        end

        points
      end

      # Update explored tiles based on currently visible tiles
      def update_explored_tiles(entity)
        visibility = entity.get_component(:visibility)
        visibility.explored_tiles.merge(visibility.visible_tiles)
      end

      # Check if dev mode is active for this entity
      def dev_mode_active?(entity)
        dev_mode = entity.get_component(:dev_mode)
        dev_mode&.fov_disabled || false
      end

      # Check if coordinates are within grid bounds
      def in_bounds?(row, col)
        @grid.in_bounds?(row, col)
      end

      # Check if a tile blocks vision (e.g., walls)
      def blocks_vision?(row, col)
        @grid.blocks_vision?(row, col)
      end

      # Query entities with specific components
      def entities_with(*component_types)
        @world.query_entities(component_types)
      end
    end
  end
end
