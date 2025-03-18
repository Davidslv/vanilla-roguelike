require 'pry'

module Vanilla
  # required to use STDIN.getch
  # in order to avoid pressing enter to submit input to the game
  require 'io/console'

  # Keyboard arrow keys are compose of 3 characters
  #
  # UP    -> \e[A
  # DOWN  -> \e[B
  # RIGHT -> \e[C
  # LEFT  -> \e[D
  KEYBOARD_ARROWS = {
    A: :KEY_UP,
    B: :KEY_DOWN,
    C: :KEY_RIGHT,
    D: :KEY_LEFT
  }.freeze

  # Systems
  require_relative 'vanilla/systems'

  # game
  require_relative 'vanilla/input_handler'
  require_relative 'vanilla/draw'
  require_relative 'vanilla/logger'
  require_relative 'vanilla/level'

  # map
  require_relative 'vanilla/map_utils'
  require_relative 'vanilla/map'

  # output
  require_relative 'vanilla/output/terminal'

  # renderers
  require_relative 'vanilla/renderers'

  # algorithms
  require_relative 'vanilla/algorithms'

  # support
  require_relative 'vanilla/support/tile_type'

  # components (entity component system)
  require_relative 'vanilla/components'

  # entities
  require_relative 'vanilla/entities'
  require_relative 'vanilla/entities/player'

  # event system
  require_relative 'vanilla/events'

  # Have a seed for the random number generator
  # This is used to generate the same map for the same seed
  # This is useful for testing
  # This is a global variable so that it can be accessed by the map generator
  # and the game loop
  $seed = nil

  # Game class implements the core game loop pattern and orchestrates the game's
  # main components. It manages the game lifecycle from initialization to cleanup.
  #
  # The Game Loop pattern provides a way to:
  # 1. Process player input
  # 2. Update game state
  # 3. Render the updated state
  # 4. Repeat until the game ends
  #
  # This implementation uses a turn-based approach appropriate for roguelike games,
  # where updates happen in discrete steps rather than in real-time.
  class Game
    # Initialize a new game instance with all required systems
    # @return [Game] a new Game instance
    def initialize
      @logger = Vanilla::Logger.instance
      @logger.info("Starting Vanilla game")

      # Initialize event system with file storage for debugging and analytics
      @event_manager = Events::EventManager.new(@logger)

      # Input handler translates raw keyboard input into game commands
      @input_handler = InputHandler.new(@logger, @event_manager)

      # Initialize render system
      @render_system = Systems::RenderSystemFactory.create
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

      # Spawn monsters appropriate for this difficulty level
      monster_system.spawn_monsters(difficulty)
      @logger.info("Spawned initial monsters")

      # Initial render of the level
      all_entities = [level.player] + monster_system.monsters
      @render_system.render(all_entities, level.grid)

      # Store the monster system with the level for later access
      level.instance_variable_set(:@monster_system, monster_system)

      level
    end

    # The main game loop that implements the Game Loop pattern
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
        all_entities = [level.player] + monster_system.monsters
        @render_system.render(all_entities, level.grid)

        # 5. LEVEL TRANSITION - check if player advances to next level
        level = handle_level_transition(level) if level.player.found_stairs?

        # 6. END FRAME - mark the end of this turn
        @event_manager.publish_event(Events::Types::TURN_ENDED)
      end
    end

    # Process player input and convert it to game commands
    # @param level [Level] the current game level
    # @return [Command] the command that was executed
    def process_input(level)
      # Get raw keyboard input
      key = STDIN.getch

      # Handle multi-character input sequences (arrow keys)
      second_key = STDIN.getch if key == "\e"
      key = STDIN.getch if second_key == "["
      key = KEYBOARD_ARROWS[key.intern] || key

      # Process input through the input handler
      @input_handler.handle_input(key, level.player, level.grid)
    end

    # Handle collisions between player and game entities
    # @param level [Level] the current game level
    # @param monster_system [MonsterSystem] the monster management system
    # @return [void]
    def handle_collisions(level, monster_system)
      if monster_system.player_collision?
        player_pos = level.player.get_component(:position)
        @logger.info("Player encountered a monster!")

        # TODO: Handle combat mechanics
        # In the future, this will handle combat mechanics
        # For now, it just logs the encounter
      end
    end

    # Handle transition to a new level when player finds stairs
    # @param current_level [Level] the current level being completed
    # @return [Level] the new level
    def handle_level_transition(current_level)
      # Calculate new difficulty
      current_difficulty = current_level.difficulty
      next_difficulty = current_difficulty + 1

      @logger.info("Player found stairs, advancing to level #{next_difficulty}")

      # Publish level change event
      @event_manager.publish_event(
        Events::Types::LEVEL_CHANGED,
        current_level,
        { old_level: current_difficulty, new_level: next_difficulty }
      )

      # Initialize the next level with increased difficulty
      initialize_level(difficulty: next_difficulty)
    end
  end

  # Entry point for starting the game
  # Creates a new Game instance and manages its lifecycle
  # @return [void]
  def self.run
    game = Game.new
    begin
      game.start
    ensure
      game.cleanup
    end
  end

end
