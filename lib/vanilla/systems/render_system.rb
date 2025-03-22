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
          render = entity.get_component(:render)
          render.respond_to?(:layer) ? render.layer || 0 : 0
        end

        # Draw entities
        renderables.each do |entity|
          position = entity.get_component(:position)
          render = entity.get_component(:render)

          character = render.respond_to?(:character) ? render.character : render.char
          color = render.color

          @renderer.draw_character(
            position.row,
            position.column,
            character,
            color
          )
        end

        # Update display
        @renderer.present
      end

      # Legacy render method for backward compatibility
      # @param entities [Array<Entity>] The entities to render
      # @param grid [Grid] The grid to render
      # @return [void]
      def render(entities, grid)
        # Clear screen
        @renderer.clear

        # Draw the provided grid
        @renderer.draw_grid(grid)

        # Filter entities that can be rendered
        renderables = entities.select do |entity|
          entity.has_component?(:position) && entity.has_component?(:render)
        end

        # Sort by render layer
        renderables.sort_by! do |entity|
          render = entity.get_component(:render)
          render.respond_to?(:layer) ? render.layer || 0 : 0
        end

        # Draw entities
        renderables.each do |entity|
          position = entity.get_component(:position)
          render = entity.get_component(:render)

          character = render.respond_to?(:character) ? render.character : render.char
          color = render.color

          @renderer.draw_character(
            position.row,
            position.column,
            character,
            color
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