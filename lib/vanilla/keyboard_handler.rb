require 'io/console'

module Vanilla
  # Handles keyboard input for the game

  class KeyboardHandler
    # Initialize a new keyboard handler
    def initialize
      @pressed_keys = {}

      @key_map = {
        'k' => :k,      # UP
        'j' => :j,      # DOWN
        'h' => :h,      # LEFT
        'l' => :l,      # RIGHT
        'q' => :q,      # quit
        'i' => :i       # inventory
      }

      @input_queue = Queue.new

      # Register our handlers
      start_input_thread
    end

    def wait_for_input
      # Blocks until input is available
      @input_queue.pop
    end

    private

    def start_input_thread
      Thread.new do
        loop do
          input += STDIN.getch
          key = @key_map[input] || input.to_sym
          @input_queue << key
        end
      end
    end
  end
end
