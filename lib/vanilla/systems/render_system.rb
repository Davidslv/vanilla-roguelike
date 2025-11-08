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
        update_renderer_info
        render_grid
        render_messages
        @renderer.present
      end

      private

      def update_renderer_info
        # Set game info (seed and difficulty)
        @renderer.set_game_info(seed: @seed, difficulty: @difficulty)
        
        # Get player health
        player = @world.get_entity_by_name('Player')
        if player
          health_component = player.get_component(:health)
          if health_component
            @renderer.set_player_health(current: health_component.current_health, max: health_component.max_health)
          end
        end
      end

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
