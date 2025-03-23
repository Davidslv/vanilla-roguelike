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
        @output = ""
      end

      def clear
        @buffer = nil
        @message_buffer = {}
        @color_buffer = {}
        @title_lines = []

        @output = "\e[H\e[2J" # Start with clear
      end

      def draw_grid(grid)
        @grid = grid
        @buffer = Array.new(grid.rows) { Array.new(grid.columns, '.') }
        grid.each_cell do |cell|
          pos = cell.position
          @buffer[pos[0]][pos[1]] = cell.tile || '.'
        end
        @logger.debug("Grid buffer:\n#{@buffer.map(&:join).join("\n")}") # Log to file, not STDOUT
      end

      def draw_character(row, column, character, color = nil)
        if @buffer && row >= 0 && row < @buffer.size && column >= 0 && column < @buffer.first.size
          @buffer[row][column] = character
          @color_buffer[[row, column]] = color if color
        else
          @message_buffer[[row, column]] = character
          @color_buffer[[row, column]] = color if color
          @logger.debug("Outside grid: '#{character}' at [#{row},#{column}]")
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

      def present
        return unless @grid && @buffer

        @title_lines.each { |line| @output << "#{line}\n" }
        @output << "\n"

        # Render grid
        @output << "+" + "---+" * @grid.columns + "\n"
        @grid.rows.times do |row|
          top = "|"
          bottom = "+"
          @grid.columns.times do |col|
            char = @buffer[row][col]
            color = @color_buffer[[row, col]]
            body = color ? "#{color_code(color)}#{char}#{reset_color}" : char
            body = " #{body} " if body.size == 1
            east_boundary = col + 1 < @grid.columns ? "|" : "|"
            south_boundary = row + 1 < @grid.rows ? "---" : "---"
            top << body << east_boundary
            bottom << south_boundary << "+"
          end
          @output << top << "\n" << bottom << "\n"
        end

        # Messages
        @output << "\n=== MESSAGES ===\n"
        message_system = Vanilla::Messages::MessageSystem.instance
        messages = message_system&.get_recent_messages(10) || []
        if messages.empty?
          @output << "No messages yet.\n"
        else
          @output << "Latest messages:\n" << "-" * 40 << "\n"
          messages.each { |msg| @output << "#{msg.importance.to_s.upcase}: #{msg.translated_text}\n" }
        end

        print @output
        $stdout.flush
      end

      # Get ANSI color code for the given color symbol
      # @param color_sym [Symbol] The color symbol
      # @return [String] The ANSI color code
      def color_code(color_sym)
        return ""
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
    end
  end
end
