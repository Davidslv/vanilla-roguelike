module Vanilla
  # Handles keyboard input for the game
  class KeyboardHandler
    # Initialize a new keyboard handler
    def initialize
      @pressed_keys = {}
      @raw_input = nil

      # Make sure STDIN is properly configured for raw input
      begin
        require 'io/console'
        STDIN.echo = false
        STDIN.raw!
      rescue LoadError, StandardError
        # fall back to basic input if io/console isn't available
      end

      # Define keyboard arrow constants
      @key_map = {
        'A' => :KEY_UP,
        'B' => :KEY_DOWN,
        'C' => :KEY_RIGHT,
        'D' => :KEY_LEFT,
        'h' => :h,
        'j' => :j,
        'k' => :k,
        'l' => :l,
        'q' => :q,
        'i' => :i,
        ' ' => :space
      }

      # Register our handlers
      setup_input_handler
    end

    # Check if a key is currently pressed
    # @param key [Symbol] The key to check
    # @return [Boolean] True if the key is pressed
    def key_pressed?(key)
      scan_for_input
      @pressed_keys[key] || false
    end

    # Set a key's pressed state
    # @param key [Symbol] The key to set
    # @param pressed [Boolean] Whether the key is pressed
    def set_key_pressed(key, pressed)
      @pressed_keys[key] = pressed
    end

    # Clear all pressed keys
    def clear
      @pressed_keys.clear
    end

    private

    # Set up the input handler
    def setup_input_handler
      # Empty implementation - in a real app, we would set up handlers
    end

    # Scan for keyboard input using IO.console
    def scan_for_input
      # Reset pressed keys each frame for non-repetitive input
      @pressed_keys.clear

      begin
        # Skip in test mode to avoid console IO issues
        return if ENV['VANILLA_TEST_MODE'] == 'true'

        # Check if input is available without blocking
        return unless IO.select([STDIN], nil, nil, 0)

        # Read a character without waiting
        input = STDIN.read_nonblock(1) rescue return

        # Handle different inputs
        case input
        when "\e"
          # This could be an arrow key (which is a 3-char sequence)
          if IO.select([STDIN], nil, nil, 0.001)
            second_char = STDIN.read_nonblock(1) rescue return
            if second_char == "[" && IO.select([STDIN], nil, nil, 0.001)
              third_char = STDIN.read_nonblock(1) rescue return
              # Map the arrow key
              arrow_key = case third_char
                          when "A" then :KEY_UP
                          when "B" then :KEY_DOWN
                          when "C" then :KEY_RIGHT
                          when "D" then :KEY_LEFT
                          end
              @pressed_keys[arrow_key] = true if arrow_key
            end
          end
        else
          # Regular key press
          key_sym = @key_map[input]
          @pressed_keys[key_sym] = true if key_sym
        end
      rescue Errno::EINTR, Interrupt, IOError => e
        # Handle standard input interruptions gracefully
        @pressed_keys.clear
      end
    end
  end
end