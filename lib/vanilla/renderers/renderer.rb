# frozen_string_literal: true

module Vanilla
  module Renderers
    # The Renderer class is a blueprint for drawing the game to the screen.
    # It’s not meant to be used directly—instead, it defines the essential methods that
    # all renderers (e.g., TerminalRenderer) must have to display the game world.
    # Think of it as a contract: any class inheriting from Renderer must implement these
    # methods to handle clearing the screen, drawing the grid and characters, and showing
    # the final result. This ensures consistency across different rendering styles
    # (e.g., terminal, graphical) while keeping the game logic separate from how it’s shown.

    class Renderer
      # --- Core Lifecycle Methods ---
      # These methods define the rendering pipeline: clear, draw, present.
      #

      protected

      # Clears any previous render state (e.g., wipe the screen).
      def clear
        raise NotImplementedError, "Renderers must implement #clear"
      end

      # Prepares the screen for a new frame (e.g., reset cursor or buffer).
      def clear_screen
        raise NotImplementedError, "Renderers must implement #clear_screen"
      end

      # Draws the game grid (e.g., maze layout) to the screen.
      def draw_grid(grid)
        raise NotImplementedError, "Renderers must implement #draw_grid"
      end

      # Draws a single character (e.g., player, item) at a specific position.
      def draw_character(row, column, character, color = nil)
        raise NotImplementedError, "Renderers must implement #draw_character"
      end

      # Presents the final rendered frame to the user (e.g., flush output).
      def present
        raise NotImplementedError, "Renderers must implement #present"
      end
    end
  end
end
