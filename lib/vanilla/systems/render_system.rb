require_relative 'system'

module Vanilla
  module Systems
    # System that handles rendering entities to the display
    class RenderSystem < System
      # Initialize a new render system
      # @param world [World] The world this system belongs to
      def initialize(world)
        super
        @renderer = Vanilla::Renderers::TerminalRenderer.new
        @logger = Vanilla::Logger.instance
      end

      # Update method called once per frame
      # @param delta_time [Float] Time since last update
      def update(delta_time)
        # Clear screen
        @renderer.clear

        # Draw level grid
        render_grid

        # Get all entities with position and render components
        renderables = entities_with(:position, :render)

        # Sort by render layer
        renderables.sort_by! do |entity|
          entity.get_component(:render).layer || 0
        end

        # Draw entities
        renderables.each do |entity|
          position = entity.get_component(:position)
          render = entity.get_component(:render)

          @renderer.draw_character(
            position.row,
            position.column,
            render.char,
            render.color
          )
        end

        # Update display
        @renderer.present
      end

      # Clear the screen completely (for transitions, etc.)
      # @return [void]
      def clear_screen
        @renderer.clear_screen
      end

      private

      # Render the level grid
      def render_grid
        grid = @world.current_level&.grid
        return unless grid

        @renderer.draw_grid(grid)
      end
    end
  end
end