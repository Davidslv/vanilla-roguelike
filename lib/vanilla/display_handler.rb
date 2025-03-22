module Vanilla
  # Handles display output for the game
  class DisplayHandler
    def initialize
      # Initialize display state
      @buffer = {}
    end

    # Clear the display
    def clear
      @buffer.clear
    end

    # Draw a character at a specific position
    # @param char [String] The character to draw
    # @param row [Integer] The row to draw at
    # @param column [Integer] The column to draw at
    # @param color [Symbol, nil] Optional color for the character
    def draw_char(char, row, column, color = nil)
      @buffer[[row, column]] = { char: char, color: color }
    end

    # Refresh the display
    def refresh
      # Implementation depends on the actual display system
      # This would render the buffer to the screen
    end

    # Get the current buffer
    # @return [Hash] The current display buffer
    def buffer
      @buffer
    end
  end
end