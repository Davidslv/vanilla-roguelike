# frozen_string_literal: true

require_relative '../lib/vanilla'

module Vanilla
  module Web
    # WebGame builds and drives a game World for the browser front-end.
    #
    # It deliberately reuses the SAME systems and priorities that
    # Vanilla::Game#setup_world registers, with two seams inverted for the web:
    #
    #   * No InputSystem (priority 1) — that system BLOCKS on raw stdin.
    #     Instead input arrives from the browser and is fed through
    #     Vanilla::InputHandler directly (which queues a Command on the World).
    #
    #   * No terminal RenderSystem (priority 10) — that system prints ANSI to
    #     stdout. Instead WebRenderer serialises the same grid/FOV view into a
    #     string + structured HUD that the browser draws.
    #
    # The terminal game (Vanilla::Game) is left completely untouched.
    class WebGame
      attr_reader :world, :seed, :difficulty

      def initialize(options = {})
        @difficulty = options[:difficulty] || 1
        @seed = options[:seed] || Random.new_seed
        @dev_mode = options[:dev_mode] || false
        @logger = Vanilla::Logger.instance
        @turn = 0

        setup_world
        Vanilla::ServiceRegistry.register(:game, self)
      end

      # Vanilla.game_turn reads this off the registered :game service.
      attr_reader :turn

      # Generate the maze and prime FOV so the first frame shows the player.
      # Mirrors Vanilla::Game#start, minus rendering + the blocking loop.
      def start
        srand(@seed)
        @maze_system.update(nil)
        @fov_system&.update(nil)
        self
      end

      # Feed one browser keypress and advance the simulation by one resolved
      # step.
      #
      # Flow (matches the terminal game's command/update ordering):
      #   1. InputHandler maps the key to a Command and queues it on the World.
      #   2. world.update(nil) runs all sim systems in priority order, then
      #      processes the command queue (MoveCommand#execute calls
      #      MovementSystem#move directly), then drains events.
      #
      # MessageSystem selection mode (combat / loot menus) is honoured: when a
      # menu is open, a matching key is routed to the menu instead of producing
      # a movement command, just like the terminal loop.
      def handle_key(key)
        key = key.to_s
        message_system = Vanilla::ServiceRegistry.get(:message_system)

        if message_system&.selection_mode?
          message_system.handle_input(key)
          # Drain queued commands/events produced by the menu action.
          @world.update(nil)
          message_system.update(nil)
        else
          @input_handler.handle_input(key)
          @world.update(nil)
          @turn += 1
        end
        self
      end

      def quit?
        @world.quit?
      end

      private

      # Same construction as Vanilla::Game#setup_world, but excluding
      # InputSystem and the terminal RenderSystem.
      def setup_world
        @world = Vanilla::World.new
        @event_manager = Vanilla::Events::EventManager.new(store_config: { file: true })
        Vanilla::ServiceRegistry.register(:event_manager, @event_manager)

        @player = Vanilla::EntityFactory.create_player(0, 0, dev_mode: @dev_mode)
        @world.add_entity(@player)

        @maze_system = Vanilla::Systems::MazeSystem.new(@world, difficulty: @difficulty, seed: @seed)
        @world.add_system(@maze_system, 0)

        # NOTE: InputSystem (priority 1) intentionally omitted — driven via InputHandler.
        @world.add_system(Vanilla::Systems::MovementSystem.new(@world), 2)
        @fov_system = Vanilla::Systems::FOVSystem.new(@world)
        @world.add_system(@fov_system, 2.5)
        @world.add_system(Vanilla::Systems::MonsterAISystem.new(@world), 2.6)
        @world.add_system(Vanilla::Systems::CombatSystem.new(@world), 3)
        @world.add_system(Vanilla::Systems::CollisionSystem.new(@world), 3)
        @world.add_system(Vanilla::Systems::LootSystem.new(@world), 3)
        @world.add_system(Vanilla::Systems::MonsterSystem.new(@world, player: @player), 4)

        message_system = Vanilla::Systems::MessageSystem.new(@world)
        @world.add_system(message_system, 5)
        Vanilla::ServiceRegistry.register(:message_system, message_system)

        # NOTE: terminal RenderSystem (priority 10) intentionally omitted — the
        # browser renders via WebRenderer.

        @input_handler = Vanilla::InputHandler.new(@world)
      end
    end
  end
end
