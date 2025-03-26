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
      render
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
      @level = LevelGenerator.new.generate(@difficulty, @seed)
      @world.set_level(@level)

      @player = Vanilla::EntityFactory.create_player(0, 0)
      @logger.debug("[Game] Adding player to world: #{@player.id}")
      @world.add_entity(@player)
      @level.add_entity(@player)

      @monster_system = Vanilla::Systems::MonsterSystem.new(@world, player: @player, logger: @logger)
      @monster_system.spawn_monsters(@difficulty)

      # Note: InputSystem must have the highest priority (zero)
      @world.add_system(Vanilla::Systems::InputSystem.new(@world), 0)
      @world.add_system(Vanilla::Systems::MovementSystem.new(@world), 1)
      @world.add_system(Vanilla::Systems::RenderSystem.new(@world, @difficulty, @seed), 2)
      @world.add_system(@monster_system, 3)

      Vanilla::ServiceRegistry.register(:message_system, Vanilla::Systems::MessageSystem.new(@world))
    end

    def game_loop
      @turn = 0

      until @world.quit?
        @world.update(nil)
        render
        @turn += 1
      end
    end

    def render
      @world.systems.find { |s, _| s.is_a?(Vanilla::Systems::RenderSystem) }[0].update(nil)
    end
  end
end
