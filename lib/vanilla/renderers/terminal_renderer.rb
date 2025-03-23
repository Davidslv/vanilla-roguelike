module Vanilla
  module Renderers
    class TerminalRenderer
      def clear
        system("clear")
      end

      def draw_grid(grid)
        grid_output = ["Level Map:"]
        grid.rows.times do |row|
          row_str = ""
          grid.columns.times do |col|
            cell = grid[row, col]
            row_str += cell.tile || "."
          end
          grid_output << row_str
        end
        # Print all lines at once to avoid extra spacing
        print grid_output.join("\n") + "\n"
      end

      def draw_title_screen(difficulty, seed)
        print "Vanilla Roguelike - Difficulty: #{difficulty} - Seed: #{seed}\n"
        print "-" * 40 + "\n"
      end

      def present
        # No-op for puts-based rendering
      end
    end
  end
end
