module Vanilla
  class Game
    attr_reader :turn, :world

    def initialize(options = {})
      @difficulty = options[:difficulty] || 1
      @seed = options[:seed] || Random.new_seed
      @logger = Vanilla::Logger.instance
      @turn = 0
      setup_world
      Vanilla::ServiceRegistry.register(:game, self)
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
      @display = Vanilla::DisplayHandler.new
      level = LevelGenerator.new.generate(@difficulty, @seed)
      @world.set_level(level)

      @player = Vanilla::EntityFactory.create_player(0, 0)
      @world.add_entity(@player)
      level.add_entity(@player)

      @monster_system = Vanilla::Systems::MonsterSystem.new(grid: level.grid, player: @player, logger: @logger)
      @monster_system.spawn_monsters(@difficulty)

      @world.add_system(Vanilla::Systems::InputSystem.new(@world), 1)
      @world.add_system(Vanilla::Systems::MovementSystem.new(@world), 2)
      @world.add_system(Vanilla::Systems::RenderSystem.new(@world, @difficulty, @seed), 3)
      @world.add_system(@monster_system, 4)

      Vanilla::ServiceRegistry.register(:message_system, Vanilla::Systems::MessageSystem.new(@world))
    end

    def game_loop
      loop do
        @turn += 1
        input = @display.keyboard_handler.wait_for_input
        break if input == "q"
        @player.get_component(:input).set_move_direction(input_to_direction(input))
        @world.update(nil)
        render
      end
    end

    def render
      @world.systems.find { |s, _| s.is_a?(Vanilla::Systems::RenderSystem) }[0].update(nil)
    end

    def input_to_direction(input)
      case input
      when "h" then :west
      when "j" then :south
      when "k" then :north
      when "l" then :east
      else nil
      end
    end
  end
end
