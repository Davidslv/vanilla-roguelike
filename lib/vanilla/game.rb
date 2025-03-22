module Vanilla
  # The main Game class that initializes and runs the game
  # This class has been refactored to follow the ECS architecture
  class Game
    attr_reader :world, :running, :movement_system, :render_system, :message_system

    # Initialize a new game
    # @param options [Hash] Configuration options
    def initialize(options = {})
      # Set up configuration
      @logger = options[:logger] || Vanilla::Logger.instance
      @seed = options[:seed]
      @difficulty = options[:difficulty] || 1
      @running = false
      @last_update_time = Time.now

      # Check for test mode
      test_mode = ENV['VANILLA_TEST_MODE'] == 'true' || options[:test_mode]

      # Create the ECS world
      @world = Vanilla::World.new

      # Register systems in priority order
      register_systems

      # Create initial level
      initialize_level

      # Register the game in the service registry for compatibility
      # But first, clear any existing registration to prevent leaks
      Vanilla::ServiceRegistry.clear if test_mode
      Vanilla::ServiceRegistry.register(:game, self)
      @logger.info("Game initialized with ECS architecture")
    end

    # Start the game loop
    def start
      @running = true
      @last_update_time = Time.now

      print_title_screen

      # Main game loop
      while @running
        # Process a single turn
        process_turn
      end

      # Clean up resources
      cleanup
    end

    # Process a single game turn
    def process_turn
      # Calculate delta time
      current_time = Time.now
      delta_time = current_time - @last_update_time
      @last_update_time = current_time

      # Process input and update world
      @world.update(delta_time)

      # Update grid with entities for compatibility
      if @world.current_level
        @world.current_level.update_grid_with_entities(@world.entities.values)
      end

      # Check for exit condition
      @running = false if @world.keyboard.key_pressed?(:q)

      # Limit frame rate
      sleep_time = [0, (1.0 / 30) - delta_time].max
      sleep(sleep_time) if sleep_time > 0
    end

    # Clean up and exit the game
    def exit_game
      @running = false
      cleanup
    end

    # Get the current player entity
    # @return [Entity] The player entity
    def player
      @world.find_entity_by_tag(:player)
    end

    # Get the current level
    # @return [Level] The current level
    def level
      @world.current_level
    end

    # Alias for level to maintain backward compatibility
    def current_level
      level
    end

    # Set the current level
    # @param new_level [Level] The new level to set
    def current_level=(new_level)
      old_level = @world.current_level
      @world.set_level(new_level)

      # Log the level transition message if we have a message system
      if @message_system && @message_system.respond_to?(:log_message)
        @message_system.log_message("You descended to level #{new_level.difficulty}.")
      end
    end

    # Transition to the next level with increased difficulty
    def next_level
      @difficulty += 1
      @logger.info("Transitioning to level #{@difficulty}")

      # Use the command queue for level transition
      @world.queue_command(:change_level, {
        difficulty: @difficulty,
        player_id: player.id
      })
    end

    private

    # Register all game systems in the correct order
    def register_systems
      # Input processing
      @world.add_system(Vanilla::Systems::InputSystem.new(@world), 1)

      # Game logic systems
      @world.add_system(Vanilla::Systems::MovementSystem.new(@world), 2)
      @world.add_system(Vanilla::Systems::CollisionSystem.new(@world), 3)

      # Rendering systems
      @world.add_system(Vanilla::Systems::RenderSystem.new(@world), 9)
      @world.add_system(Vanilla::Systems::MessageSystem.new(@world), 10)

      @logger.debug("Systems registered with the world")
    end

    # Initialize the first level
    def initialize_level
      level_generator = Vanilla::LevelGenerator.new
      starting_level = level_generator.generate(@difficulty)
      @world.set_level(starting_level)

      # Create player entity
      player = Vanilla::EntityFactory.create_player(
        @world,
        starting_level.entrance_row,
        starting_level.entrance_column,
        "Hero"
      )

      # Create stairs entity
      Vanilla::EntityFactory.create_stairs(
        @world,
        starting_level.exit_row,
        starting_level.exit_column
      )

      # Add some monsters based on difficulty
      spawn_monsters

      # Update grid with initial entities
      @world.current_level.update_grid_with_entities(@world.entities.values)

      @logger.info("Initial level created with difficulty #{@difficulty}")
    end

    # Spawn monsters based on current difficulty
    def spawn_monsters
      # Simple formula: 2 monsters + difficulty
      monster_count = 2 + @difficulty

      # Spawn monsters at random locations
      monster_count.times do
        # Find a valid position (not a wall, not occupied)
        row, column = find_valid_spawn_position

        # Create a monster
        monster_type = [:goblin, :troll].sample
        Vanilla::EntityFactory.create_monster(@world, row, column, monster_type)
      end

      @logger.debug("Spawned #{monster_count} monsters")
    end

    # Find a valid position to spawn an entity
    # @return [Array<Integer>] Row and column coordinates
    def find_valid_spawn_position
      grid = @world.current_level.grid
      max_attempts = 100

      max_attempts.times do
        row = rand(grid.rows)
        column = rand(grid.columns)

        # Skip if it's a wall
        next unless grid[row, column] && Vanilla::Support::TileType.walkable?(grid[row, column].tile)

        # Skip if there's an entity at this position
        entities_at_position = @world.query_entities([:position]).select do |entity|
          pos = entity.get_component(:position)
          pos.row == row && pos.column == column
        end

        # If no entities at this position, it's valid
        return [row, column] if entities_at_position.empty?
      end

      # Fallback to a random position if we couldn't find a valid one
      [rand(grid.rows), rand(grid.columns)]
    end

    # Clean up resources
    def cleanup
      @logger.info("Cleaning up resources")
      # Any cleanup needed
    end

    # Display game title
    def print_title_screen
      puts ""
      puts "========================================================="
      puts "===             VANILLA ROGUELIKE GAME               ==="
      puts "===            (ECS Architecture Edition)            ==="
      puts "========================================================="
      puts "===  Use arrow keys to move                          ==="
      puts "===  Press 'q' to quit                               ==="
      puts "===  Difficulty: #{@difficulty.to_s.ljust(35)}  ==="
      puts "===  Seed: #{@seed.to_s.ljust(40)}  ==="
      puts "========================================================="
      puts ""
    end
  end
end