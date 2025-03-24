# frozen_string_literal: true
module Vanilla
  module Renderers
    class Renderer
      def clear
        raise NotImplementedError, "Renderers must implement #clear"
      end

      def clear_screen
        raise NotImplementedError, "Renderers must implement #clear_screen"
      end

      def draw_grid(grid)
        raise NotImplementedError, "Renderers must implement #draw_grid"
      end

      def draw_character(row, column, character, color = nil)
        raise NotImplementedError, "Renderers must implement #draw_character"
      end

      def present
        raise NotImplementedError, "Renderers must implement #present"
      end
    end
  end
end
