# frozen_string_literal: true

module Vanilla
  module Web
    # WebRenderer serialises the game World into a JSON-friendly frame for the
    # browser. The ASCII grid logic mirrors
    # Vanilla::Renderers::TerminalRenderer#draw_grid (same FOV / wall / tile
    # rules) so the browser shows EXACTLY what the terminal shows — it just
    # returns a String instead of printing, and bundles a structured HUD +
    # message log alongside it.
    class WebRenderer
      def initialize(world, seed:, difficulty:)
        @world = world
        @seed = seed
        @difficulty = difficulty
      end

      # @return [Hash] a frame: { grid:, hud:, messages:, selection_mode: }
      def frame
        {
          grid: render_grid,
          hud: hud,
          messages: messages,
          selection_mode: selection_mode?
        }
      end

      private

      def render_grid
        grid = @world.current_level&.grid
        return '(no grid)' unless grid

        player = @world.find_entity_by_tag(:player)
        visibility = player&.get_component(:visibility)
        dev_mode = player&.get_component(:dev_mode)
        fov_active = visibility && !(dev_mode.respond_to?(:fov_disabled) && dev_mode.fov_disabled)

        lines = ["+#{'---+' * grid.columns}"]

        grid.rows.times do |row|
          row_cells = "|"
          row_walls = "+"
          grid.columns.times do |col|
            cell = grid[row, col]
            cells_str, walls_str = render_cell(grid, cell, row, col, visibility, fov_active)
            row_cells += cells_str
            row_walls += walls_str
          end
          lines << row_cells
          lines << row_walls
        end

        lines.join("\n")
      end

      # Returns [cell_segment, wall_segment] for one cell, mirroring the
      # terminal renderer's FOV/wall rules.
      def render_cell(grid, cell, row, col, visibility, fov_active)
        last_col = col == grid.columns - 1
        east_wall = if last_col
                      "|"
                    else
                      cell.linked?(cell.east) ? " " : "|"
                    end
        south_wall = cell.linked?(cell.south) ? "   +" : "---+"

        unless fov_active
          return ["#{tile_segment(cell)}#{east_wall}", south_wall]
        end

        is_visible = visibility.tile_visible?(row, col)
        is_explored = visibility.tile_explored?(row, col)

        if is_visible
          ["#{tile_segment(cell)}#{east_wall}", south_wall]
        elsif is_explored
          [" #{dimmed_tile_for_cell(cell)} #{east_wall}", south_wall]
        else
          ["   #{last_col ? '|' : ' '}", "   +"]
        end
      end

      def tile_segment(cell)
        " #{cell.tile || '.'} "
      end

      # Mirrors TerminalRenderer#dimmed_tile_for_cell — hide actors in explored
      # but not-currently-visible cells.
      def dimmed_tile_for_cell(cell)
        tile = cell.tile
        case tile
        when Vanilla::Support::TileType::PLAYER,
             Vanilla::Support::TileType::MONSTER,
             Vanilla::Support::TileType::STAIRS
          Vanilla::Support::TileType::FLOOR
        else
          tile || '.'
        end
      end

      def hud
        player = @world.get_entity_by_name('Player')
        health = player&.get_component(:health)
        position = player&.get_component(:position)
        level = @world.current_level

        {
          seed: @seed.to_s,
          difficulty: level&.difficulty || @difficulty,
          algorithm: level&.algorithm&.to_s&.split('::')&.last || 'Unknown',
          rows: level&.grid&.rows,
          columns: level&.grid&.columns,
          hp: health&.current_health,
          max_hp: health&.max_health,
          player_row: position&.row,
          player_column: position&.column
        }
      end

      def messages
        message_system = Vanilla::ServiceRegistry.get(:message_system)
        return [] unless message_system

        message_system.get_recent_messages(12).map do |m|
          text = m.respond_to?(:translated_text) ? m.translated_text : m.content
          { text: text.to_s, category: m.category.to_s, importance: m.importance.to_s }
        end
      rescue StandardError
        []
      end

      def selection_mode?
        message_system = Vanilla::ServiceRegistry.get(:message_system)
        !!message_system&.selection_mode?
      end
    end
  end
end
