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
      begin
        while @running
          # Process a single turn
          process_turn
        end
      rescue Interrupt
        puts "\nGame interrupted. Exiting gracefully..."
        @running = false
      ensure
        # Clean up resources
        cleanup
      end
    end

    # Process a single game turn
    def process_turn
      # Calculate delta time
      current_time = Time.now
      delta_time = current_time - @last_update_time
      @last_update_time = current_time

      begin
        # Add debug output to see what's happening
        puts "Processing turn, press 'q' to quit" if @running && @world.entities.values.size > 0

        # Directly check for 'q' keypress first
        if STDIN.ready? && STDIN.getch.downcase == 'q'
          puts "Q key pressed, exiting..."
          @running = false
          return
        end

        # Process input and update world
        @world.update(delta_time)

        # Force refresh display every few frames
        @render_system.update(delta_time) if @render_system

        # Update grid with entities for compatibility
        if @world.current_level
          @world.current_level.update_grid_with_entities(@world.entities.values)
        end

        # Explicit check for exit condition
        if @world.keyboard && @world.keyboard.key_pressed?(:q)
          puts "Quit key detected, exiting game..."
          @running = false
        end

        # Ensure the whole UI is refreshed
        STDOUT.flush

        # Limit frame rate but don't sleep too long
        sleep_time = [0, (1.0 / 10) - delta_time].max
        sleep(sleep_time) if sleep_time > 0
      rescue Interrupt
        # Handle Ctrl+C properly
        puts "\nGame interrupted with Ctrl+C. Exiting..."
        @running = false
      rescue StandardError => e
        # Log the actual error
        puts "\nERROR in game turn: #{e.class}: #{e.message}"
        puts e.backtrace[0..5].join("\n")
        @logger.error("Game error: #{e.class}: #{e.message}")
        @logger.error(e.backtrace.join("\n"))

        # Don't exit immediately, give us a chance to see the error
        puts "Press Enter to continue or 'q' to quit..."
        @running = false if gets.chomp.downcase == 'q'
      end
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

      # Create the render system explicitly rather than through factory
      # to ensure it's properly configured
      @render_system = Vanilla::Systems::RenderSystem.new(@world)
      @world.add_system(@render_system, 9)

      # Message system with a higher priority (rendered last)
      @message_system = Vanilla::Systems::MessageSystem.new(@world)
      @world.add_system(@message_system, 10)

      # Make these accessible to other parts of the game
      Vanilla::ServiceRegistry.register(:render_system, @render_system)
      Vanilla::ServiceRegistry.register(:message_system, @message_system)

      @logger.debug("Systems registered with the world")
    end

    # Initialize the first level
    def initialize_level
      @logger.info("Creating level with difficulty: #{@difficulty}")

      # Create a level using the generator
      level_generator = Vanilla::LevelGenerator.new
      starting_level = level_generator.generate(@difficulty)

      # Set the level in the world
      @logger.info("Setting level in world")
      @world.set_level(starting_level)

      # Verify level was set successfully
      if !@world.current_level || !@world.current_level.grid
        @logger.error("Failed to set level in world - level or grid is nil")
        @running = false
        return
      end

      # Create the player entity at the entrance position
      @logger.info("Creating player at [#{starting_level.entrance_row}, #{starting_level.entrance_column}]")
      player = Vanilla::EntityFactory.create_player(
        @world,
        starting_level.entrance_row,
        starting_level.entrance_column,
        "Hero"
      )

      # Verify player was created
      if !player || !@world.find_entity_by_tag(:player)
        @logger.error("Failed to create or add player entity to world")
        @running = false
        return
      end

      # Create stairs entity at the exit position
      @logger.info("Creating stairs at [#{starting_level.exit_row}, #{starting_level.exit_column}]")
      stairs = Vanilla::EntityFactory.create_stairs(
        @world,
        starting_level.exit_row,
        starting_level.exit_column
      )

      # Verify stairs were created
      if !stairs || !@world.find_entity_by_tag(:stairs)
        @logger.error("Failed to create or add stairs entity to world")
        @running = false
        return
      end

      # Add monsters based on difficulty
      @logger.info("Spawning monsters for difficulty #{@difficulty}")
      spawn_monsters

      # Update grid with all entities
      @logger.info("Updating grid with #{@world.entities.size} entities")
      @world.current_level.update_grid_with_entities(@world.entities.values)

      # Final validation
      if @world.entities.empty?
        @logger.error("No entities were created during initialization")
        @running = false
        return
      end

      @logger.info("Level initialization complete with #{@world.entities.size} entities")
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