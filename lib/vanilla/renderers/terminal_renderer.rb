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

        # Use a more robust way to clear the screen
        # that works cross-platform and handles errors
        begin
          # Skip in test mode
          return if ENV['VANILLA_TEST_MODE'] == 'true'

          # Try system clear command first
          system("clear") || system("cls") || print("\e[H\e[2J")
        rescue StandardError => e
          # If system commands fail, fall back to ANSI escape sequence
          print("\e[H\e[2J")
        rescue Interrupt
          # Handle Ctrl+C gracefully
          print("\e[H\e[2J")
          puts "Game interrupted. Continuing..."
        end
      end

      def clear_screen
        # Try system clear command first
        begin
          # Skip in test mode
          return if ENV['VANILLA_TEST_MODE'] == 'true'

          system("clear") || system("cls") || print("\e[H\e[2J")
        rescue StandardError => e
          # If system commands fail, fall back to ANSI escape sequence
          print("\e[H\e[2J")
        rescue Interrupt
          # Handle Ctrl+C gracefully
          print("\e[H\e[2J")
          puts "Game interrupted. Continuing..."
        end
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
        # Debug logging only for unusual positions, and only basic info
        if $DEBUG && row > @grid&.rows && character != '-' && character != '|' && ![' ', '#'].include?(character)
          puts "DEBUG: Drawing '#{character}' outside grid at [#{row},#{column}]"
        end

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
        return unless @buffer

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

        # Add a very obvious separator for the message area
        puts "\n=== MESSAGES ===\n"

        # DIRECT MESSAGE ACCESS - use the MessageSystem facade
        # This follows proper Service Locator pattern
        message_system = Vanilla::Messages::MessageSystem.instance
        if message_system
          messages = message_system.get_recent_messages(10)

          if messages && !messages.empty?
            # Direct rendering of messages - bypassing the buffer
            puts "Latest messages:"
            puts "-" * 40

            messages.each do |msg|
              text = if msg.is_a?(Vanilla::Messages::Message)
                  "#{msg.importance.to_s.upcase}: #{msg.translated_text}"
                else
                  "#{msg[:importance].to_s.upcase}: #{msg[:text]}"
                end

              # Format by importance
              formatted = case (msg.is_a?(Vanilla::Messages::Message) ? msg.importance : msg[:importance])
                         when :critical, :danger then "!! #{text}"
                         when :warning then "* #{text}"
                         when :success then "+ #{text}"
                         else "> #{text}"
                         end

              puts formatted
            end
          else
            puts "No messages available yet. Play the game to see messages here."
          end
        # Fallback to message buffer rendering
        elsif !@message_buffer.empty?
          # Use existing message buffer rendering code
          if $DEBUG
            msg_pos = @message_buffer.keys.map(&:first).uniq.sort
            puts "DEBUG: Rendering #{@message_buffer.size} message chars at rows #{msg_pos.first}-#{msg_pos.last}"
          end

          # We'll take a different approach - collect all characters by row/col
          message_area = {}

          @message_buffer.each do |pos, char|
            row, col = pos
            message_area[row] ||= {}
            message_area[row][col] = char
          end

          # Sort rows and render each one
          message_area.keys.sort.each do |row|
            # Get the max column for this row
            max_col = message_area[row].keys.max || 0

            # Create a line with the characters
            line = ""
            (0..max_col).each do |col|
              line << (message_area[row][col] || " ")
            end

            # Print the line - make sure lines aren't empty
            puts line unless line.strip.empty?
          end
        else
          # If no messages, show a default
          puts "No messages yet. Play the game to see messages here."
        end
      end
    end
  end
end