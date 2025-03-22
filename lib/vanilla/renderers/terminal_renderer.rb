module Vanilla
  module Renderers
    class TerminalRenderer < Renderer
      def initialize
        @buffer = nil
        @grid = nil
        @header = ""
        @message_buffer = {} # Separate buffer for messages below the grid
      end

      def clear
        # Clear internal buffer
        @buffer = nil
        @message_buffer = {}
        system("clear")
      end

      def clear_screen
        # Clear the terminal
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
        # Log when called with positions outside the grid
        if @grid && (row >= @grid.rows || column >= @grid.columns * 3)
          puts "DEBUG: Drawing outside grid at [#{row},#{column}]: '#{character}'"
        end

        # For characters within the grid bounds, use the grid buffer
        if @buffer && row >= 0 && row < @buffer.size && column >= 0 && column < @buffer.first.size
          @buffer[row][column] = character
          return
        end

        # For characters outside grid bounds (like message panel), use message buffer
        @message_buffer[[row, column]] = character
      end

      def present
        return unless @grid

        # Print header
        puts @header
        puts "-" * 35
        puts "\n"

        # Render grid
        output = "+" + "---+" * @grid.columns + "\n"

        @grid.rows.times do |row_idx|
          top = "|"
          bottom = "+"

          @grid.columns.times do |col_idx|
            cell = @grid[row_idx, col_idx]
            next unless cell

            # Use our buffer content instead of grid.contents_of
            body = @buffer ? @buffer[row_idx][col_idx] : ' '
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

        # Print grid
        puts output

        # Now render message area if there are any messages
        unless @message_buffer.empty?
          # Find the bounds for the message area
          min_row = @message_buffer.keys.map { |pos| pos[0] }.min || 0
          max_row = @message_buffer.keys.map { |pos| pos[0] }.max || 0
          min_col = @message_buffer.keys.map { |pos| pos[1] }.min || 0
          max_col = @message_buffer.keys.map { |pos| pos[1] }.max || 0

          puts "DEBUG: Message area bounds - rows: #{min_row}..#{max_row}, cols: #{min_col}..#{max_col}"

          # Create a 2D array for the message area
          height = max_row - min_row + 1
          width = max_col - min_col + 1

          message_grid = Array.new(height) { Array.new(width, ' ') }

          # Fill in the message characters
          @message_buffer.each do |pos, char|
            row, col = pos
            local_row = row - min_row
            local_col = col - min_col

            if local_row >= 0 && local_row < height && local_col >= 0 && local_col < width
              message_grid[local_row][local_col] = char
            end
          end

          # Convert to strings and print
          message_lines = message_grid.map(&:join)
          puts "\n" # Extra space before messages
          puts message_lines
        end
      end
    end
  end
end