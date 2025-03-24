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
      end

      def update(_delta_time)
        @renderer.clear
        @renderer.draw_title_screen(@difficulty, @seed)
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
        game = Vanilla::ServiceRegistry.get(:game)
        turn = game&.turn || 0
        print "\n=== MESSAGES ===\n"
        if message_system
          print "Turn #{turn}: Player moved.\n"
        else
          print "No messages yet. Play the game to see messages here.\n"
        end
      end
    end
  end
end
