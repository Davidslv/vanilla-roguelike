# frozen_string_literal: true

# lib/vanilla/renderers/terminal_renderer.rb
module Vanilla
  module Renderers
    class TerminalRenderer
      def clear
        system("clear")
      end

      def draw_grid(grid, algorithm)
        Vanilla::Logger.instance.warn("[TerminalRenderer] Drawing grid with algorithm: #{algorithm}")
        output = [
          "Vanilla Roguelike - Difficulty: 1 - Seed: #{$seed}",
          "Rows: #{grid.rows} | Columns: #{grid.columns} | Algorithm: #{algorithm}",
          "\n"
        ]

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

      def present
      end
    end
  end
end
