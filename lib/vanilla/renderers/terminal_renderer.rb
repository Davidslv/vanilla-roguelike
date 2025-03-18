module Vanilla
  module Renderers
    class TerminalRenderer < Renderer
      def initialize
        @buffer = nil
        @grid = nil
        @header = ""
      end

      def clear
        # Clear internal buffer
        @buffer = nil
        system("clear")
      end

      def draw_grid(grid)
        @grid = grid
        # Initialize buffer with grid dimensions
        @buffer = Array.new(grid.rows) { Array.new(grid.columns, ' ') }

        # Fill with basic grid content
        grid.rows.times do |row|
          grid.columns.times do |col|
            cell = grid[row, col]
            if cell
              # We'll use an empty space as default, actual cell content
              # will be overlaid by entities with render components
              @buffer[row][col] = ' '
            end
          end
        end

        # Store header info
        @header = "Seed: #{$seed} | Rows: #{grid.rows} | Columns: #{grid.columns}"
      end

      def draw_character(row, column, character, color = nil)
        return unless @buffer && row >= 0 && row < @buffer.size &&
                     column >= 0 && column < @buffer.first.size

        @buffer[row][column] = character
        # Color is stored for future implementation
      end

      def present
        return unless @buffer && @grid

        # Print header
        puts @header
        puts "-" * 35
        puts "\n"

        # Render based on the same logic as the original Terminal class
        output = "+" + "---+" * @grid.columns + "\n"

        @grid.rows.times do |row_idx|
          top = "|"
          bottom = "+"

          @grid.columns.times do |col_idx|
            cell = @grid[row_idx, col_idx]
            next unless cell

            # Use our buffer content instead of grid.contents_of
            body = @buffer[row_idx][col_idx]
            body = " #{body} " if body.size == 1
            body = " #{body}" if body.size == 2

            east_cell = @grid[row_idx, col_idx + 1]
            south_cell = @grid[row_idx + 1, col_idx]

            east_boundary = (east_cell && cell.linked?(east_cell) ? " " : "|")
            south_boundary = (south_cell && cell.linked?(south_cell) ? "   " : "---")
            corner = "+"

            top << body << east_boundary
            bottom << south_boundary << corner
          end

          output << top << "\n"
          output << bottom << "\n"
        end

        puts output
      end
    end
  end
end