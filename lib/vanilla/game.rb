# frozen_string_literal: true

# lib/vanilla/game.rb
module Vanilla
  class Game
    attr_reader :turn, :world, :level

    def initialize(options = {})
      @difficulty = options[:difficulty] || 1
      @seed = options[:seed] || Random.new_seed
      @logger = Vanilla::Logger.instance
      @turn = 0

      setup_world

      Vanilla::ServiceRegistry.register(:game, self)

      # Handle SIGINT (Ctrl+C)
      Signal.trap("SIGINT") do
        @world.quit = true
        @logger.info("Received CTRL+C, quitting game")
        exit
      end
    end

    def start
      @logger.info("Starting game with seed: #{@seed}, difficulty: #{@difficulty}")
      srand(@seed)

      @logger.debug("[Game] Game#start - Starting @world.update(nil)")
      @maze_system.update(nil)
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

    private

    def setup_world
      @world = Vanilla::World.new
      @display = @world.display

      @player = Vanilla::EntityFactory.create_player(0, 0)
      @world.add_entity(@player)

      # @monster_system = Vanilla::Systems::MonsterSystem.new(@world, player: @player, logger: @logger)
      @maze_system = Vanilla::Systems::MazeSystem.new(@world, difficulty: @difficulty, seed: @seed)

      @world.add_system(@maze_system, 0) # Run first to generate maze
      @world.add_system(Vanilla::Systems::InputSystem.new(@world), 1)
      @world.add_system(Vanilla::Systems::MovementSystem.new(@world), 2)
      @world.add_system(Vanilla::Systems::CollisionSystem.new(@world), 3)
      @world.add_system(Vanilla::Systems::RenderSystem.new(@world, @difficulty, @seed), 4)
      # @world.add_system(@monster_system, 4)

      # @monster_system.spawn_monsters(@difficulty)
      Vanilla::ServiceRegistry.register(:message_system, Vanilla::Systems::MessageSystem.new(@world))
    end

    def game_loop
      @turn = 0
      @logger.debug("[Game] Starting game loop, turn: #{@turn}")

      until @world.quit?
        @logger.debug("[Game] Updating, turn: #{@turn}")
        @world.update(nil)
        @logger.debug("[Game] Updated, turn: #{@turn}")
        render
        @logger.debug("[Game] Rendered, turn: #{@turn}")
        @turn += 1
        @logger.debug("[Game] Turn incremented, turn: #{@turn}")
      end
    end

    def render
      @world.systems.find { |s, _| s.is_a?(Vanilla::Systems::RenderSystem) }[0].update(nil)
    end
  end
end
