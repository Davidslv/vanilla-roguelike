require_relative 'system'

module Vanilla
  module Systems
    # System that handles rendering entities to the display
    class RenderSystem < System
      # Initialize a new render system
      # @param world [World] The world this system belongs to
      def initialize(world, difficulty, seed)
        super(world)
        @renderer = Vanilla::Renderers::TerminalRenderer.new
        @logger = Vanilla::Logger.instance

        @difficulty = difficulty
        @seed = seed
      end

      # Update method called once per frame
      # @param delta_time [Float] Time since last update
      def update(_unused)
        # Clear screen
        @renderer.clear

        render_grid
        render_entities

        @renderer.draw_title_screen(@difficulty, @seed)
        # Update display
        @renderer.present
      end

      private

      def render_grid
        grid = @world.current_level&.grid
        return unless grid
        @renderer.draw_grid(grid)
      end

      def render_entities
        renderables = entities_with(:position, :render)
        renderables.sort_by! { |e| e.get_component(:render).layer || 0 }

        renderables.each do |entity|
          position = entity.get_component(:position)
          render = entity.get_component(:render)
          @renderer.draw_character(
            position.row,
            position.column,
            render.character,
            render.color
          )
        end
      end
    end
  end
end
