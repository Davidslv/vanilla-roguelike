# frozen_string_literal: true

module Vanilla
  class Game
    attr_reader :turn, :world, :level

    # --- Initialization ---
    def initialize(options = {})
      @difficulty = options[:difficulty] || 1
      @seed = options[:seed] || Random.new_seed
      @dev_mode = options[:dev_mode] || options[:fov_disabled] || false
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
      # Run FOV system once before first render to ensure player is visible
      @fov_system&.update(nil)
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
      @event_manager = Vanilla::Events::EventManager.new(store_config: { file: true })

      # Should EventManager be registered as a service? or should it be a singleton?
      Vanilla::ServiceRegistry.register(:event_manager, @event_manager)

      @player = Vanilla::EntityFactory.create_player(0, 0, dev_mode: @dev_mode)
      @world.add_entity(@player)

      # Maze system is first to run and needed in game loop
      @maze_system = Vanilla::Systems::MazeSystem.new(@world, difficulty: @difficulty, seed: @seed)
      @world.add_system(@maze_system, 0) # Run first to generate maze

      @world.add_system(Vanilla::Systems::InputSystem.new(@world), 1)
      @world.add_system(Vanilla::Systems::MovementSystem.new(@world), 2)
      # FOV System runs after movement (priority 2.5) - will get grid dynamically
      @fov_system = Vanilla::Systems::FOVSystem.new(@world)
      @world.add_system(@fov_system, 2.5)
      @world.add_system(Vanilla::Systems::CombatSystem.new(@world), 3)
      @world.add_system(Vanilla::Systems::CollisionSystem.new(@world), 3)
      @world.add_system(Vanilla::Systems::LootSystem.new(@world), 3)
      @world.add_system(Vanilla::Systems::MonsterSystem.new(@world, player: @player), 4)
      message_system = Vanilla::Systems::MessageSystem.new(@world)
      @world.add_system(message_system, 5) # Add MessageSystem to world systems so update() is called
      Vanilla::ServiceRegistry.register(:message_system, message_system)
      @world.add_system(Vanilla::Systems::RenderSystem.new(@world, @difficulty, @seed), 10) # Render last
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
          # Process events and messages immediately after input to avoid frame delay
          @world.send(:process_events) if @world.respond_to?(:process_events, true)
          message_system.update(nil) # Process message queue immediately
          # Render immediately after processing input to show updated menu state
          render
          @world.update(nil) # Process queued commands (but don't re-render systems)
        else
          @logger.debug("[Game] Running game loop, turn: #{@turn}")
          @world.update(nil)
          @turn += 1
          render
        end
        @logger.debug("[Game] Game#game_loop - Rendered, turn: #{@turn}")
      end
    end

    def render
      @world.systems.find { |s, _| s.is_a?(Vanilla::Systems::RenderSystem) }[0].update(nil)
    end
  end
end
