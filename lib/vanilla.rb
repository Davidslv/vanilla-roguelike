require 'singleton'
require 'io/console'
require 'securerandom'

# Set fixed seed for reproducible games
# Comment out to get new random worlds each time
$seed = 12345

# Core module definitions
require_relative 'vanilla/logger'
require_relative 'vanilla/support/tile_type'
require_relative 'vanilla/level'
require_relative 'vanilla/map'
require_relative 'vanilla/input_handler'

# Component system
require_relative 'vanilla/components'

# Entity system
require_relative 'vanilla/entities'

# Systems
require_relative 'vanilla/systems'

# Renderers
require_relative 'vanilla/renderers'

# Map utils
require_relative 'vanilla/map_utils'

# Algorithms
require_relative 'vanilla/algorithms'

# Events
require_relative 'vanilla/events'

# Fiber Concurrency
require_relative 'vanilla/fiber_concurrency'

module Vanilla
  # Main game class that initializes and runs the game
  class Game
    # Initialize a new game instance
    # This sets up all required systems and components
    # @return [void]
    def initialize
      # Initialize the FiberConcurrency system
      Vanilla::FiberConcurrency.initialize

      # Use the FiberLogger instead of the regular logger
      @logger = Vanilla::FiberConcurrency.logger
      @logger.info("Starting Vanilla game")

      # Create event manager for the game to handle events
      @event_manager = Events::EventManager.new(@logger)

      # Initialize the render system which handles drawing to the terminal
      @render_system = Vanilla::Systems::RenderSystemFactory.create

      # Create input handler to process player commands
      @input_handler = InputHandler.new(@logger, @event_manager, @render_system)
    end

    # Start the game by initializing the first level and entering the game loop
    # This is the main entry point after initialization
    # @return [void]
    def start
      @logger.info("Starting game loop")

      # Record game start event for debugging and analytics
      @event_manager.publish_event(Events::Types::GAME_STARTED)

      # Initialize the first level
      level = initialize_level(difficulty: 1)

      # Enter the main game loop - this will continue until the player exits
      game_loop(level)
    end

    # Perform cleanup operations when the game ends
    # This ensures resources are properly released
    # @return [void]
    def cleanup
      @event_manager.publish_event(Events::Types::GAME_ENDED)
      @event_manager.close

      # Shutdown the fiber concurrency system
      Vanilla::FiberConcurrency.shutdown

      @logger.info("Player exiting game")
    end

    private

    # Initialize a new level with the specified difficulty
    # This creates the level, spawns monsters, and prepares it for play
    # @param difficulty [Integer] the difficulty level (affects monster count and strength)
    # @return [Level, MonsterSystem] the initialized level and its monster system
    def initialize_level(difficulty:)
      # Generate a new random level
      level = Vanilla::Level.random(difficulty: difficulty)
      @logger.info("Level created")

      # Create a monster system for this level
      monster_system = Vanilla::Systems::MonsterSystem.new(
        grid: level.grid,
        player: level.player,
        logger: @logger
      )

      # Add monsters to the level
      monster_system.spawn_monsters(level.difficulty)
      @logger.info("Spawned initial monsters")

      # Store the monster system with the level for later reference
      level.instance_variable_set(:@monster_system, monster_system)

      level
    end

    # Main game loop that handles input, updates, and rendering
    # This loop continues until the player exits or the game ends
    # @param level [Level] the current game level
    # @return [void]
    def game_loop(level)
      loop do
        # 1. START FRAME - mark the beginning of a new turn
        @event_manager.publish_event(Events::Types::TURN_STARTED)

        # 2. PROCESS INPUT - get and process player input
        command = process_input(level)

        # Check if player wants to exit the game
        break if command.is_a?(Vanilla::Commands::ExitCommand)

        # 3. UPDATE GAME STATE - update game world and check conditions
        monster_system = level.instance_variable_get(:@monster_system)

        # Update monster positions according to AI
        monster_system.update

        # Handle collisions between player and monsters
        handle_collisions(level, monster_system)

        # 4. RENDER - update the display to reflect the new state
        all_entities = level.all_entities + monster_system.monsters
        @render_system.render(all_entities, level.grid)

        # 5. LEVEL TRANSITION - check if player advances to next level
        level = handle_level_transition(level) if level.player.found_stairs?

        # 6. END FRAME - mark the end of this turn
        @event_manager.publish_event(Events::Types::TURN_ENDED)

        # 7. PROCESS FIBER EVENTS - allow fiber-based tasks to run
        Vanilla::FiberConcurrency.tick
      end
    end

    # Process player input and convert it to game commands
    # @param level [Level] the current game level
    # @return [Command] the command that was executed
    def process_input(level)
      # Get raw keyboard input
      key = STDIN.getch

      # Use the input handler to create the appropriate command
      command = @input_handler.handle_input(key, level.player, level.grid)

      # Execute the command and return it
      command.execute
      command
    end

    # Handle collisions between the player and monsters
    # This includes combat and other interactions
    # @param level [Level] the current game level
    # @param monster_system [MonsterSystem] the monster system for this level
    # @return [void]
    def handle_collisions(level, monster_system)
      if monster_system.player_collision?
        @logger.info("Player encountered a monster!")

        # Get the monster at the player's position
        monster = monster_system.monster_at(level.player.coordinates)

        # Have the monster attack the player (implement combat later)
        # monster.attack(level.player)
      end
    end

    # Handle level transitions when the player finds stairs
    # This creates a new level with increased difficulty
    # @param current_level [Level] the current game level
    # @return [Level] the new game level
    def handle_level_transition(current_level)
      # Calculate new difficulty
      current_difficulty = current_level.difficulty
      next_difficulty = current_difficulty + 1

      @logger.info("Player found stairs, advancing to level #{next_difficulty}")

      # Initialize the new level
      initialize_level(difficulty: next_difficulty)
    end
  end

  # Run a new game
  # This is the entry point for the entire application
  # @return [void]
  def self.run
    game = Game.new
    game.start
    game.cleanup
  rescue => e
    puts "An error occurred: #{e.message}"
    puts e.backtrace
    exit(1)
  end
end
