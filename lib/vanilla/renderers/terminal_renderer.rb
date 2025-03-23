module Vanilla
  module Renderers
    class TerminalRenderer < Renderer
      def initialize
        @buffer = nil
        @grid = nil
        @header = ""
        @message_buffer = {}
        @color_buffer = {}
        @title_lines = []
        @logger = Vanilla::Logger.instance
      end

      def clear
        @buffer = nil
        @message_buffer = {}
        @color_buffer = {}
        @title_lines = []

        clear_screen # Clear and move cursor to top-left
      end

      def clear_screen
        print "\e[H\e[2J"
      end

      def draw_grid(grid)
        @grid = grid
        @buffer = Array.new(grid.rows) { Array.new(grid.columns, '.') }
        grid.each_cell do |cell|
          pos = cell.position
          @buffer[pos[0]][pos[1]] = cell.tile || '.' # Use tile (e.g., '#')
        end

        @header = "Seed: #{$seed} | Rows: #{grid.rows} | Columns: #{grid.columns}"
      end

      def draw_character(row, column, character, color = nil)
        if @buffer && row >= 0 && row < @buffer.size && column >= 0 && column < @buffer.first.size
          @buffer[row][column] = character
          @color_buffer[[row, column]] = color if color
        else
          @message_buffer[[row, column]] = character
          @color_buffer[[row, column]] = color if color
          @logger.debug("Drawing '#{character}' outside grid at [#{row},#{column}]") if $DEBUG
        end
      end

      def draw_title_screen(difficulty, seed)
        @title_lines = [
          "=========================================================",
          "===             VANILLA ROGUELIKE GAME               ===",
          "===            (ECS Architecture Edition)            ===",
          "=========================================================",
          "===  Use arrow keys to move                          ===",
          "===  Press 'q' to quit                               ===",
          "===  Difficulty: #{difficulty.to_s.ljust(35)}  ===",
          "===  Seed: #{seed.to_s[0..40].ljust(40)}  ===",
          "========================================================="
        ]
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
        return unless @grid && @buffer

        # Render title
        @title_lines.each { |line| puts line }
        puts "\n"

        # Render grid
        output = "+" + "---+" * @grid.columns + "\n"
        @grid.rows.times do |row|
          top = "|"
          bottom = "+"
          @grid.columns.times do |col|
            cell = @grid[row, col]
            next unless cell
            char = @buffer[row][col]
            color = @color_buffer[[row, col]]
            body = color ? "#{color_code(color)}#{char}#{reset_color}" : char
            body = " #{body} " if body.size == 1
            east_cell = @grid[row, col + 1]
            south_cell = @grid[row + 1, col]
            east_boundary = (east_cell && cell.linked?(east_cell) ? " " : "|")
            south_boundary = (south_cell && cell.linked?(south_cell) ? "   " : "---")
            top << body << east_boundary
            bottom << south_boundary << "+"
          end
          output << top << "\n" << bottom << "\n"
        end
        puts output

        # Messages
        puts "\n=== MESSAGES ===\n"
        message_system = Vanilla::Messages::MessageSystem.instance
        if message_system && !message_system.get_recent_messages(10).empty?
          puts "Latest messages:"
          puts "-" * 40
          message_system.get_recent_messages(10).each do |msg|
            text = "#{msg.importance.to_s.upcase}: #{msg.translated_text}"
            puts text
          end
        else
          puts "No messages yet."
        end
      end

      # def present
      #   return unless @grid
      #   return unless @buffer

      #   # Print header
      #   puts @header
      #   puts "-" * 35
      #   puts "\n"

      #   # Render grid
      #   output = "+" + "---+" * @grid.columns + "\n"

      #   @grid.rows.times do |row_idx|
      #     top = "|"
      #     bottom = "+"

      #     @grid.columns.times do |col_idx|
      #       cell = @grid[row_idx, col_idx]
      #       next unless cell

      #       # Use our buffer content instead of grid.contents_of
      #       body = @buffer ? @buffer[row_idx][col_idx] : ' '
      #       body = " #{body} " if body.size == 1
      #       body = " #{body}" if body.size == 2

      #       east_cell = @grid[row_idx, col_idx + 1]
      #       south_cell = @grid[row_idx + 1, col_idx]

      #       east_boundary = (east_cell && cell.linked?(east_cell) ? " " : "|")
      #       south_boundary = (south_cell && cell.linked?(south_cell) ? "   " : "---")
      #       corner = "+"

      #       top << body << east_boundary
      #       bottom << south_boundary << corner
      #     end

      #     output << top << "\n"
      #     output << bottom << "\n"
      #   end

      #   # Print grid
      #   puts output

      #   # Add a very obvious separator for the message area
      #   puts "\n=== MESSAGES ===\n"

      #   # DIRECT MESSAGE ACCESS - use the MessageSystem facade
      #   # This follows proper Service Locator pattern
      #   message_system = Vanilla::Messages::MessageSystem.instance
      #   if message_system
      #     messages = message_system.get_recent_messages(10)

      #     if messages && !messages.empty?
      #       # Direct rendering of messages - bypassing the buffer
      #       puts "Latest messages:"
      #       puts "-" * 40

      #       messages.each do |msg|
      #         text = if msg.is_a?(Vanilla::Messages::Message)
      #             "#{msg.importance.to_s.upcase}: #{msg.translated_text}"
      #           else
      #             "#{msg[:importance].to_s.upcase}: #{msg[:text]}"
      #           end

      #         # Format by importance
      #         formatted = case (msg.is_a?(Vanilla::Messages::Message) ? msg.importance : msg[:importance])
      #                    when :critical, :danger then "!! #{text}"
      #                    when :warning then "* #{text}"
      #                    when :success then "+ #{text}"
      #                    else "> #{text}"
      #                    end

      #         puts formatted
      #       end
      #     else
      #       puts "No messages available yet. Play the game to see messages here."
      #     end
      #   # Fallback to message buffer rendering
      #   elsif !@message_buffer.empty?
      #     # Use existing message buffer rendering code
      #     if $DEBUG
      #       msg_pos = @message_buffer.keys.map(&:first).uniq.sort
      #       puts "DEBUG: Rendering #{@message_buffer.size} message chars at rows #{msg_pos.first}-#{msg_pos.last}"
      #     end

      #     # We'll take a different approach - collect all characters by row/col
      #     message_area = {}

      #     @message_buffer.each do |pos, char|
      #       row, col = pos
      #       message_area[row] ||= {}
      #       message_area[row][col] = char
      #     end

      #     # Sort rows and render each one
      #     message_area.keys.sort.each do |row|
      #       # Get the max column for this row
      #       max_col = message_area[row].keys.max || 0

      #       # Create a line with the characters
      #       line = ""
      #       (0..max_col).each do |col|
      #         line << (message_area[row][col] || " ")
      #       end

      #       # Print the line - make sure lines aren't empty
      #       puts line unless line.strip.empty?
      #     end
      #   else
      #     # If no messages, show a default
      #     puts "No messages yet. Play the game to see messages here."
      #   end
      # end
    end
  end
end
