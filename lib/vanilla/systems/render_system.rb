# frozen_string_literal: true

module Vanilla
  module Systems
    class RenderSystem < System
      def initialize(world, difficulty, seed)
        super(world)
        @renderer = Vanilla::Renderers::TerminalRenderer.new
        @difficulty = difficulty
        @seed = seed
        @logger = Vanilla::Logger.instance
        @logger.debug("[RenderSystem] Initializing with difficulty: #{difficulty}, seed: #{seed}")
      end

      def update(_delta_time)
        @renderer.clear
        render_grid
        render_messages
        @renderer.present
      end

      private

      def render_grid
        grid = @world.current_level&.grid
        @renderer.draw_grid(grid, @world.current_level&.algorithm&.demodulize || "Unknown")
      end

      def render_messages
        message_system = Vanilla::ServiceRegistry.get(:message_system)
        message_system&.render(self) # Delegate to MessagePanel
      end
    end
  end
end
