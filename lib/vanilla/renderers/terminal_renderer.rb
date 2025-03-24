# frozen_string_literal: true
# lib/vanilla/renderers/terminal_renderer.rb
module Vanilla
  module Renderers
    class TerminalRenderer
      def clear
        system("clear")
      end

      def draw_grid(grid, algorithm)
        output = ["Vanilla Roguelike - Difficulty: 1 - Seed: #{$seed}",
                  "Seed: #{$seed} | Rows: #{grid.rows} | Columns: #{grid.columns} | Algorithm: #{algorithm}",
                  "-" * 35]

        # Add top border
        top_border = "+"
        grid.columns.times { top_border += "---+"; }
        output << top_border

        grid.rows.times do |row|
          row_cells = "|"
          row_walls = "+"
          grid.columns.times do |col|
            cell = grid[row, col]
            row_cells += " #{cell.tile || '.'} "
            row_cells += (col == grid.columns - 1) ? "|" : (cell.linked?(cell.east) ? " " : "|")
            row_walls += cell.linked?(cell.south) ? "   +" : "---+"
          end
          output << row_cells
          output << row_walls
        end

        print output.join("\n") + "\n"
      end

      def draw_title_screen(difficulty, seed)
        # Moved to draw_grid
      end

      def present
      end
    end
  end
end
