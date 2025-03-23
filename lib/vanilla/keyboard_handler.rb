require 'io/console'

module Vanilla
  # Handles keyboard input for the game

  # TODO: DO NOT MonkeyPatch!
  # Patch STDIN with a ready? method if it doesn't exist
  unless STDIN.respond_to?(:ready?)
    def STDIN.ready?
      ready_status = IO.select([STDIN], nil, nil, 0)
      ready_status && ready_status[0].include?(STDIN)
    end
  end

  class KeyboardHandler
    # Initialize a new keyboard handler
    def initialize
      @pressed_keys = {}
      @raw_input = nil

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

      # Check if input is available
      if STDIN.ready?
        # Read a character without waiting
        input = STDIN.getch

        # Handle different inputs
        case input
        when "\e"
          # This could be an arrow key (which is a 3-char sequence)
          if STDIN.ready?
            input += STDIN.getch
            if input == "\e[" && STDIN.ready?
              input += STDIN.getch
              # Check if it's an arrow key
              if input.length == 3 && Vanilla::KEYBOARD_ARROWS.key?(input[2].to_sym)
                arrow_key = Vanilla::KEYBOARD_ARROWS[input[2].to_sym]
                @pressed_keys[arrow_key] = true
              end
            end
          end
        else
          # Regular key press
          key_sym = @key_map[input]
          @pressed_keys[key_sym] = true if key_sym
        end
      end
    end
  end
end
