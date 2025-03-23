module Vanilla
  module Renderers
    class TerminalRenderer
      def clear
        system("clear")
      end

      def draw_grid(grid)
        output = ["Seed: #{$seed} | Rows: #{grid.rows} | Columns: #{grid.columns}", "-" * 35]

        # Top border
        output << "+---+---+---+---+---+---+---+---+---+---+"

        # Draw each row
        grid.rows.times do |row|
          row_cells = "|"
          row_walls = "+"
          grid.columns.times do |col|
            cell = grid[row, col]
            # Cell content
            row_cells += " #{cell.tile || '.'} |"
            # Bottom wall
            row_walls += cell.linked?(cell.south) ? "   +" : "---+"
          end
          output << row_cells
          output << row_walls unless row == grid.rows - 1
        end

        print output.join("\n") + "\n"
      end

      def draw_title_screen(difficulty, seed)
        print "Vanilla Roguelike - Difficulty: #{difficulty} - Seed: #{seed}\n"
      end

      def present
        # No-op
      end
    end
  end
end
