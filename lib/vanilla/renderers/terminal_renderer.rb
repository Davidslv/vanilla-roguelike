module Vanilla
  module Renderers
    class TerminalRenderer < Renderer
      def initialize
        @buffer = nil
        @grid = nil
        @header = ""
        @message_buffer = {} # Separate buffer for messages below the grid
        @color_buffer = {}   # Store colors for characters outside the grid
        @logger = Vanilla::Logger.instance

        # Print initialization message for debugging
        @logger.debug("Terminal renderer initialized")
      end

      def clear
        # Clear internal buffer
        @buffer = nil
        @message_buffer = {}
        @color_buffer = {}

        # Use a direct approach for terminal clearing that works consistently
        begin
          # Skip in test mode
          return if ENV['VANILLA_TEST_MODE'] == 'true'

          # Clear terminal with simpler approach that works more consistently
          # First move to home position (0,0)
          print("\e[H")
          # Then clear entire screen
          print("\e[2J")
          # Ensure it's flushed
          STDOUT.flush

          @logger.debug("Screen cleared")
        rescue StandardError => e
          # If ANSI escape sequences fail, try a simpler approach
          puts "\n" * 50
          @logger.error("Error clearing screen: #{e.message}")
        rescue Interrupt
          # Handle Ctrl+C gracefully
          @logger.info("Interrupt received during screen clear")
        end
      end

      def clear_screen
        # Same as clear, but meant to be an explicit total clear
        clear
      end

      def draw_grid(grid)
        unless grid
          @logger.error("Attempted to draw nil grid")
          return false
        end

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

        # Store header info with proper seed display
        seed_display = $seed.nil? ? "random" : $seed.to_s
        @header = "Seed: #{seed_display} | Grid: #{grid.rows}x#{grid.columns}"

        @logger.debug("Grid prepared for rendering: #{grid.rows}x#{grid.columns}")

        true
      end

      def draw_character(row, column, character, color = nil)
        # Validate parameters
        unless character
          @logger.warn("Attempted to draw nil character at [#{row},#{column}]")
          character = '?'
        end

        # Debug logging for character placement
        @logger.debug("Drawing '#{character}' at [#{row},#{column}] with color #{color || 'none'}")

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
        # Make sure we have something to display
        if !@grid || !@buffer
          puts "⚠️  No grid or buffer to display"
          STDOUT.flush
          @logger.error("Cannot present: grid=#{@grid.nil? ? 'nil' : 'present'}, buffer=#{@buffer.nil? ? 'nil' : 'present'}")
          return
        end

        # Print header
        puts @header
        puts "-" * 50
        puts ""

        # Render grid - make sure we handle nil cells properly
        begin
          output = "+" + "---+" * @grid.columns + "\n"

          @grid.rows.times do |row_idx|
            top = "|"
            bottom = "+"

            @grid.columns.times do |col_idx|
              cell = @grid[row_idx, col_idx]

              # Handle nil cells gracefully
              unless cell
                @logger.warn("Nil cell at [#{row_idx},#{col_idx}]")
                top << " ? |"
                bottom << "---+"
                next
              end

              # Use our buffer content instead of grid.contents_of
              body = @buffer ? @buffer[row_idx][col_idx] : ' '
              body = " #{body} " if body.size == 1
              body = " #{body}" if body.size == 2

              east_cell = @grid[row_idx, col_idx + 1]
              south_cell = @grid[row_idx + 1, col_idx]

              # Check linked cells, using safe navigation to avoid nil errors
              east_boundary = (east_cell && cell.respond_to?(:linked?) && cell.linked?(east_cell) ? " " : "|")
              south_boundary = (south_cell && cell.respond_to?(:linked?) && cell.linked?(south_cell) ? "   " : "---")
              corner = "+"

              top << body << east_boundary
              bottom << south_boundary << corner
            end

            output << top << "\n"
            output << bottom << "\n"
          end

          # Print grid
          print output
          STDOUT.flush # Ensure output is displayed

          @logger.debug("Grid display output generated and printed")
        rescue => e
          puts "Error rendering grid: #{e.message}"
          @logger.error("Grid rendering error: #{e.class}: #{e.message}")
          @logger.error(e.backtrace.join("\n"))
        end

        # Add a very obvious separator for the message area
        puts "\n=== MESSAGES ==="
        STDOUT.flush # Ensure separator is displayed

        # Always show game controls
        puts "USE KEYBOARD CONTROLS:"
        puts "• Arrow keys: Move character"
        puts "• Q: Quit game"
        puts "• CTRL+C: Force exit"
        STDOUT.flush

        # Display messages from the message system if available
        begin
          message_system = Vanilla::ServiceRegistry.get(:message_system)

          if message_system && message_system.respond_to?(:get_recent_messages)
            messages = message_system.get_recent_messages(5) rescue []

            if messages && !messages.empty?
              puts "\nRECENT EVENTS:"
              puts "-" * 40

              messages.each do |msg|
                text = if msg.is_a?(Hash) && msg[:text]
                        msg[:text].to_s
                      elsif msg.respond_to?(:to_s)
                        msg.to_s
                      else
                        "Unknown message"
                      end

                puts "• #{text}"
              end
            end
          end
        rescue => e
          puts "Message system unavailable: #{e.message}"
          @logger.error("Message system error: #{e.class}: #{e.message}")
        end

        # Display entity debug info if in debug mode
        if ENV['VANILLA_DEBUG'] == 'true'
          begin
            world = nil
            game = Vanilla::ServiceRegistry.get(:game)
            world = game.world if game && game.respond_to?(:world)

            if world
              puts "\nDEBUG INFO:"
              puts "-" * 40
              puts "Entities: #{world.entities.size}"
              player = world.find_entity_by_tag(:player)
              if player
                pos = player.get_component(:position)
                puts "Player position: [#{pos&.row || '?'},#{pos&.column || '?'}]"
              else
                puts "Player not found"
              end

              stairs = world.find_entity_by_tag(:stairs)
              if stairs
                pos = stairs.get_component(:position)
                puts "Stairs position: [#{pos&.row || '?'},#{pos&.column || '?'}]"
              else
                puts "Stairs not found"
              end
            end
          rescue => e
            puts "Debug info error: #{e.message}"
          end
        end

        # Always flush to make sure everything is displayed
        STDOUT.flush
        @logger.debug("Display presentation complete")
      end
    end
  end
end