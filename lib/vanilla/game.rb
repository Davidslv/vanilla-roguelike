# frozen_string_literal: true

module Vanilla
  class Game
    attr_reader :turn, :world, :level

    # --- Initialization ---
    def initialize(options = {})
      @difficulty = options[:difficulty] || 1
      @seed = options[:seed] || Random.new_seed
      @logger = Vanilla::Logger.instance
      @turn = 0

      setup_world
      Vanilla::ServiceRegistry.register(:game, self)

      # Handle SIGINT (Ctrl+C) gracefully
      Signal.trap("SIGINT") do
        @world.quit = true
        @logger.info("Received CTRL+C, quitting game")
        exit
      end
    end

    # --- Core Lifecycle Methods ---
    def start
      @logger.info("Starting game with seed: #{@seed}, difficulty: #{@difficulty}")
      srand(@seed)
      @logger.debug("[Game] Game#start - Starting @world.update(nil)")
      @maze_system.update(nil) # Generate initial maze
      @logger.debug("[Game] Game#start - Rendering")
      render
      @logger.debug("[Game] Game#start - Starting game loop")
      game_loop
    end

    def cleanup
      @logger.info("Game cleanup")
      @display&.cleanup
      Vanilla::ServiceRegistry.unregister(:game)
    end

    # --- Private Implementation Details ---
    private

    def setup_world
      @world = Vanilla::World.new
      @display = @world.display
      @player = Vanilla::EntityFactory.create_player(0, 0)
      @world.add_entity(@player)

      # Maze system is first to run and needed in game loop
      @maze_system = Vanilla::Systems::MazeSystem.new(@world, difficulty: @difficulty, seed: @seed)
      @world.add_system(@maze_system, 0) # Run first to generate maze

      @world.add_system(Vanilla::Systems::InputSystem.new(@world), 1)
      @world.add_system(Vanilla::Systems::MovementSystem.new(@world), 2)
      @world.add_system(Vanilla::Systems::CollisionSystem.new(@world), 3)
      @world.add_system(Vanilla::Systems::MonsterSystem.new(@world, player: @player), 4)
      @world.add_system(Vanilla::Systems::RenderSystem.new(@world, @difficulty, @seed), 10) # Render last

      Vanilla::ServiceRegistry.register(:message_system, Vanilla::Systems::MessageSystem.new(@world))
    end

    def game_loop
      @turn = 0
      @logger.debug("[Game] Starting game loop, turn: #{@turn}")
      message_system = Vanilla::ServiceRegistry.get(:message_system)
      input_system = @world.systems.find { |s, _| s.is_a?(Vanilla::Systems::InputSystem) }[0]

      until @world.quit?
        if message_system&.selection_mode?
          @logger.debug("[Game] In menu mode, waiting for input, turn: #{@turn}")
          input_system.update(nil) # Wait for input
          @world.update(nil) # Process queued commands
        else
          @logger.debug("[Game] Running game loop, turn: #{@turn}")
          @world.update(nil)
          @turn += 1
        end
        render
        @logger.debug("[Game] Game#game_loop - Rendered, turn: #{@turn}")
      end
    end

    def render
      @world.systems.find { |s, _| s.is_a?(Vanilla::Systems::RenderSystem) }[0].update(nil)
    end
  end
end
