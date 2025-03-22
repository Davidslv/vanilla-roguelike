module Vanilla
  # Handles keyboard input for the game
  class KeyboardHandler
    attr_reader :last_key_pressed

    # Initialize a new keyboard handler
    def initialize
      @pressed_keys = {}
      @raw_input = nil
      @last_key_pressed = nil
      @logger = Vanilla::Logger.instance

      # Make sure STDIN is properly configured for raw input
      begin
        require 'io/console'
        STDIN.echo = false
        # Only use raw mode if not in test mode
        unless ENV['VANILLA_TEST_MODE'] == 'true'
          STDIN.raw!
          @logger.debug("Terminal set to raw mode for keyboard input")
        end
      rescue LoadError, StandardError => e
        @logger.warn("IO console configuration failed: #{e.message}")
        # fall back to basic input if io/console isn't available
      end

      # Define keyboard arrow constants
      @key_map = {
        'A' => :KEY_UP,
        'B' => :KEY_DOWN,
        'C' => :KEY_RIGHT,
        'D' => :KEY_LEFT,
        'h' => :KEY_LEFT,
        'j' => :KEY_DOWN,
        'k' => :KEY_UP,
        'l' => :KEY_RIGHT,
        'q' => :q,
        'Q' => :q,
        'i' => :i,
        'I' => :i,
        ' ' => :space
      }

      # Patch STDIN with ready? method if needed
      unless STDIN.respond_to?(:ready?)
        def STDIN.ready?
          IO.select([STDIN], nil, nil, 0) ? true : false
        end
        @logger.debug("Added ready? method to STDIN")
      end

      @logger.info("Keyboard handler initialized")
    end

    # Check if a key is currently pressed
    # @param key [Symbol] The key to check
    # @return [Boolean] True if the key is pressed
    def key_pressed?(key)
      scan_for_input
      @pressed_keys[key] || false
    end

    # Get all currently pressed keys
    # @return [Array<Symbol>] List of pressed key symbols
    def pressed_keys
      scan_for_input
      @pressed_keys.keys
    end

    # Set a key's pressed state
    # @param key [Symbol] The key to set
    # @param pressed [Boolean] Whether the key is pressed
    def set_key_pressed(key, pressed)
      @pressed_keys[key] = pressed
      @last_key_pressed = key if pressed
    end

    # Clear all pressed keys
    def clear
      @pressed_keys.clear
      @last_key_pressed = nil
    end

    # Manually check for a quit key - useful for getting out of stuck states
    # @return [Boolean] True if quit was requested
    def check_for_quit
      begin
        if STDIN.ready?
          char = STDIN.getch rescue nil
          if char && (char.downcase == 'q' || char == "\u0003") # q or Ctrl+C
            @logger.info("Manual quit detected: #{char.inspect}")
            return true
          end
        end
      rescue => e
        @logger.error("Error checking for quit: #{e.message}")
      end
      false
    end

    private

    # Scan for keyboard input using IO.console
    def scan_for_input
      # Reset pressed keys each frame for non-repetitive input
      @pressed_keys.clear

      begin
        # Skip in test mode to avoid console IO issues
        return if ENV['VANILLA_TEST_MODE'] == 'true'

        # Check if input is available without blocking
        if STDIN.ready?
          # Read a character without waiting
          input = STDIN.getch rescue nil

          # Exit immediately if Ctrl+C is pressed
          if input == "\u0003"
            @logger.info("Ctrl+C detected, setting quit flag")
            @pressed_keys[:q] = true
            @last_key_pressed = :q
            return
          end

          # For debugging
          @logger.debug("Input detected: #{input.inspect}") if ENV['VANILLA_DEBUG'] == 'true'

          # Handle different inputs
          case input
          when "\e"
            # This could be an arrow key (which is a 3-char sequence)
            sequence = ""
            2.times do
              if STDIN.ready?
                next_char = STDIN.getch rescue break
                sequence += next_char
              else
                break
              end
            end

            if sequence == "[A"
              @pressed_keys[:KEY_UP] = true
              @last_key_pressed = :KEY_UP
              @logger.debug("Up arrow detected")
            elsif sequence == "[B"
              @pressed_keys[:KEY_DOWN] = true
              @last_key_pressed = :KEY_DOWN
              @logger.debug("Down arrow detected")
            elsif sequence == "[C"
              @pressed_keys[:KEY_RIGHT] = true
              @last_key_pressed = :KEY_RIGHT
              @logger.debug("Right arrow detected")
            elsif sequence == "[D"
              @pressed_keys[:KEY_LEFT] = true
              @last_key_pressed = :KEY_LEFT
              @logger.debug("Left arrow detected")
            end
          when "q", "Q"
            # Ensure quit key is detected
            @pressed_keys[:q] = true
            @last_key_pressed = :q
            @logger.debug("Quit key detected")
          else
            # Handle regular keys from key map
            if mapped_key = @key_map[input]
              @pressed_keys[mapped_key] = true
              @last_key_pressed = mapped_key
              @logger.debug("Mapped key detected: #{mapped_key}")
            else
              # For any unmapped key, log it in debug mode
              @logger.debug("Unmapped key: #{input.inspect}")
            end
          end
        end
      rescue Errno::EAGAIN, Errno::EWOULDBLOCK
        # Non-blocking IO returned no data, that's normal
      rescue Errno::EINTR => e
        # Handle interrupt signal
        @logger.warn("Input interrupted: #{e.message}")
        @pressed_keys[:q] = true
      rescue IOError, StandardError => e
        # Handle any IO errors
        @logger.error("Input error: #{e.class}: #{e.message}")
        # Ensure we can exit if there's an input error
        @pressed_keys[:q] = true
      end
    end
  end
end