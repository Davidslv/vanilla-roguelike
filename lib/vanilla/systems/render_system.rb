module Vanilla
  module Systems
    class RenderSystem
      def initialize(renderer)
        @renderer = renderer
        @logger = Vanilla::Logger.instance
      end

      # Clear the screen completely (for transitions, etc.)
      # @return [void]
      def clear_screen
        @renderer.clear_screen
      end

      def render(entities, grid)
        @logger.debug("Rendering scene with #{entities.size} entities")

        # Start with a fresh canvas
        @renderer.clear

        # Draw the grid first (background)
        @renderer.draw_grid(grid)

        # Find entities with both position and render components
        drawable_entities = entities.select do |entity|
          entity.has_component?(:position) && entity.has_component?(:render)
        end

        # Sort by layer (z-index) for proper drawing order
        drawable_entities.sort_by! { |e| e.get_component(:render).layer }

        # Draw each entity
        drawable_entities.each do |entity|
          render_component = entity.get_component(:render)
          position = entity.get_component(:position)

          @renderer.draw_character(
            position.row,
            position.column,
            render_component.character,
            render_component.color
          )
        end

        # Present the final rendered scene
        @renderer.present
      end
    end
  end
end