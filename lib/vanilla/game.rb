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
      @level = LevelGenerator.new.generate(@difficulty, @seed)
      @world.set_level(@level)

      @player = Vanilla::EntityFactory.create_player(0, 0)
      @world.add_entity(@player)
      @level.add_entity(@player)

      @monster_system = Vanilla::Systems::MonsterSystem.new(@world, player: @player, logger: @logger)
      @monster_system.spawn_monsters(@difficulty)

      # Note: InputSystem is referenced but not provided; using game loop for now
      @world.add_system(Vanilla::Systems::MovementSystem.new(@world), 1)
      @world.add_system(Vanilla::Systems::RenderSystem.new(@world, @difficulty, @seed), 2)
      @world.add_system(@monster_system, 3)

      Vanilla::ServiceRegistry.register(:message_system, Vanilla::Systems::MessageSystem.new(@world))
    end

    def game_loop
      loop do
        input = @display.keyboard_handler.wait_for_input
        @logger.debug("Game loop input: #{input.inspect}")

        # Exit with "q" or CTRL+C
        break if input == "q" || input == "\u0003"

        direction = input_to_direction(input)
        if direction
          @player.get_component(:input).set_move_direction(direction)
          @world.update(nil)  # Process movement and queued commands
          @turn += 1
          render
          @world.update(nil)  # Ensure any post-movement commands (e.g., level change) are processed
          render  # Redraw after potential level change
        end
      end
    end

    def render
      @world.systems.find { |s, _| s.is_a?(Vanilla::Systems::RenderSystem) }[0].update(nil)
    end

    def input_to_direction(input)
      # Ignore escape sequences and control characters except Ctrl+C
      return nil if input =~ /\e/ || (input =~ /\p{Cntrl}/ && input != "\u0003")

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
