# frozen_string_literal: true

module Vanilla
  module Renderers
    # The TerminalRenderer class handles drawing the game state to the terminal.
    # It's responsible for clearing the screen and rendering the game grid (e.g., maze layout)
    # as ASCII art, showing walls, paths, and tiles.
    # This class is part of the rendering system, taking data from the game world
    # and presenting it visually in a simple, text-based format.

    class TerminalRenderer < Renderer
      def initialize
        @seed = nil
        @difficulty = nil
        @player_health = nil
        @player_max_health = nil
      end

      def set_game_info(seed:, difficulty:)
        @seed = seed
        @difficulty = difficulty
      end

      def set_player_health(current:, max:)
        @player_health = current
        @player_max_health = max
      end

      # --- Core Lifecycle Methods ---
      def draw_grid(grid, algorithm, visibility: nil, dev_mode: nil)
        Vanilla::Logger.instance.warn("[TerminalRenderer] Drawing grid with algorithm: #{algorithm}")

        # Check if FOV is active
        fov_active = visibility && !(dev_mode&.fov_disabled)

        # Build status lines
        header_parts = []
        header_parts << "Vanilla Roguelike"

        if @seed
          header_parts << "Seed: #{@seed}"
        end

        # Add dev mode indicator if active
        if dev_mode&.fov_disabled
          header_parts << "DEV MODE: FOV OFF"
        end

        # Build HP and Level line
        player_info_parts = []
        if @player_health && @player_max_health
          health_percent = (@player_health.to_f / @player_max_health * 100).round
          player_info_parts << "HP: #{@player_health}/#{@player_max_health} (#{health_percent}%)"
        end

        if @difficulty
          player_info_parts << "Level: #{@difficulty}"
        end

        output = [
          header_parts.join(" | "),
          "Rows: #{grid.rows} | Columns: #{grid.columns} | Algorithm: #{algorithm}", # Grid info
          player_info_parts.join(" | "), # HP and Level on separate line
          "\n" # Spacing
        ]

        # Draw the top border: +---+---+... based on column count
        top_border = "+"
        grid.columns.times { top_border += "---+"; }
        output << top_border

        # For each row, draw cells and walls below them
        grid.rows.times do |row|
          row_cells = "|" # Start with left border
          row_walls = "+" # Start with corner
          grid.columns.times do |col|
            cell = grid[row, col]

            # Determine visibility state
            if fov_active
              is_visible = visibility.tile_visible?(row, col)
              is_explored = visibility.tile_explored?(row, col)

              if is_visible
                # Currently visible - render normally
                row_cells += " #{cell.tile || '.'} "
              elsif is_explored
                # Explored but not visible - render dimmed (walls only, no entities)
                # Show the terrain but replace entities with floor
                tile_char = dimmed_tile_for_cell(cell)
                row_cells += " #{tile_char} "
              else
                # Unexplored - render as blank
                row_cells += "   "
              end

              # Walls rendering
              if is_visible || is_explored
                # Show walls if tile has been explored
                row_cells += col == grid.columns - 1 ? "|" : (cell.linked?(cell.east) ? " " : "|")
                row_walls += cell.linked?(cell.south) ? "   +" : "---+"
              else
                # Unexplored walls
                row_cells += col == grid.columns - 1 ? "|" : " "
                row_walls += "   +"
              end
            else
              # FOV disabled - render normally
              row_cells += " #{cell.tile || '.'} "
              row_cells += col == grid.columns - 1 ? "|" : (cell.linked?(cell.east) ? " " : "|")
              row_walls += cell.linked?(cell.south) ? "   +" : "---+"
            end
          end
          output << row_cells # e.g., "| . | @ |"
          output << row_walls # e.g., "+---+   +"
        end

        print output.join("\n") + "\n" # Combine lines and print with final newline
      end

      def clear
        system("clear")
      end

      def present
        # TODO: To be decided ...
        # Currently the program is using #draw_grid to print the grid to the terminal
        # but it might be better to use #present to print the grid to the terminal
        # and #draw_grid to draw the grid to the screen buffer
        #
        # This will allow us to use the same code for both terminal and graphical output
        # and we can just swap out the #present method for a different implementation
        # for graphical output
      end

      private

      # Get dimmed tile character for explored but not visible cells
      # Shows terrain but not entities
      def dimmed_tile_for_cell(cell)
        tile = cell.tile

        # Check if tile represents an entity (player, monster, stairs)
        # These should be hidden when not visible
        case tile
        when Vanilla::Support::TileType::PLAYER,
             Vanilla::Support::TileType::MONSTER,
             Vanilla::Support::TileType::STAIRS
          # Replace entities with floor/empty
          Vanilla::Support::TileType::FLOOR
        else
          # Keep terrain tiles (floor, walls, etc.)
          tile || '.'
        end
      end
    end
  end
end
