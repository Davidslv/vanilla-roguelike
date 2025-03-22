module Vanilla
  module Renderers
    class TerminalRenderer < Renderer
      def initialize
        @buffer = nil
        @grid = nil
        @header = ""
        @message_buffer = {} # Separate buffer for messages below the grid
        @color_buffer = {}   # Store colors for characters outside the grid
      end

      def clear
        # Clear internal buffer
        @buffer = nil
        @message_buffer = {}
        @color_buffer = {}
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
        # For characters within the grid bounds, use the grid buffer
        if @buffer && row >= 0 && row < @buffer.size && column >= 0 && column < @buffer.first.size
          @buffer[row][column] = character
          return
        end

        # For characters outside grid bounds (like message panel), use message buffer
        @message_buffer[[row, column]] = character
        @color_buffer[[row, column]] = color if color
      end

      # Get ANSI color code for the given color symbol
      # @param color_sym [Symbol] The color symbol
      # @return [String] The ANSI color code
      def color_code(color_sym)
        case color_sym
        when :red
          "\e[31m"
        when :green
          "\e[32m"
        when :yellow
          "\e[33m"
        when :blue
          "\e[34m"
        when :magenta
          "\e[35m"
        when :cyan
          "\e[36m"
        when :white
          "\e[37m"
        else
          ""  # No color
        end
      end

      # Reset ANSI color codes
      # @return [String] The ANSI reset code
      def reset_color
        "\e[0m"
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

          # Create a 2D array for the message area
          height = max_row - min_row + 1
          width = max_col - min_col + 1

          message_lines = []

          # For each row in the message area
          height.times do |row|
            line = ""
            current_color = nil

            # For each column in the row
            width.times do |col|
              pos = [row + min_row, col + min_col]
              char = @message_buffer[pos] || ' '
              color = @color_buffer[pos]

              # Add color codes when color changes
              if color && color != current_color
                line << color_code(color)
                current_color = color
              elsif !color && current_color
                line << reset_color
                current_color = nil
              end

              line << char
            end

            # Reset color at end of line if needed
            line << reset_color if current_color

            message_lines << line
          end

          # Print the message area
          puts "\n" # Extra space before messages
          puts message_lines
        end
      end
    end
  end
end