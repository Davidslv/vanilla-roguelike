require 'io/console'

module Vanilla
  # Handles keyboard input for the game

  class KeyboardHandler
    # Initialize a new keyboard handler
    def initialize
      @pressed_keys = {}

      # Define keyboard arrow constants
      # @key_map = {
      #   'A' => :KEY_UP,
      #   'B' => :KEY_DOWN,
      #   'C' => :KEY_RIGHT,
      #   'D' => :KEY_LEFT,
      #   'h' => :h,
      #   'j' => :j,
      #   'k' => :k,
      #   'l' => :l,
      #   'q' => :q,
      #   'i' => :i,
      #   ' ' => :space
      # }

      @key_map = {
        'k' => :k,
        'j' => :j,
        'h' => :h,
        'l' => :l,
        # arrow keys
        "\e[A" => :up,
        "\e[B" => :down,
        "\e[C" => :right,
        "\e[D" => :left,

        'q' => :q,      # quit
        'i' => :i       # inventory
      }

      @input_queue = Queue.new

      # Register our handlers
      start_input_thread
    end

    # Check if a key is currently pressed
    # @param key [Symbol] The key to check
    # @return [Boolean] True if the key is pressed
    def key_pressed?(key)
      scan_for_input
      @pressed_keys[key] || false
    end

    def wait_for_input
      # Blocks until input is available
      @input_queue.pop
    end

    # Clear all pressed keys
    def clear
      @pressed_keys.clear
    end

    private

    def start_input_thread
      Thread.new do
        # ATTENTION: Monkey Patching STDIN
        # Define STDIN.ready? if not present
        unless STDIN.respond_to?(:ready?)
          def STDIN.ready?
            IO.select([self], nil, nil, 0)&.first&.include?(self)
          end
        end

        loop do
          input = STDIN.getch
          if input == "\e" && STDIN.ready?
            input += STDIN.getch
            input += STDIN.getch if STDIN.ready? # Arrow key sequence
          end
          key = @key_map[input] || input.to_sym
          @input_queue << key
        end
      end
    end

    def scan_for_input
      @pressed_keys.clear
      until @input_queue.empty?
        input = @input_queue.pop(non_block: true) rescue nil
        @pressed_keys[input] = true if input
      end
    end
  end
end
