require 'pry'

module Vanilla
  # required to use STDIN.getch
  # in order to avoid pressing enter to submit input to the game
  require 'io/console'

  # Patch STDIN with a ready? method if it doesn't exist
  unless STDIN.respond_to?(:ready?)
    def STDIN.ready?
      ready_status = IO.select([STDIN], nil, nil, 0)
      ready_status && ready_status[0].include?(STDIN)
    end
  end

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
  require_relative 'vanilla/logger'
  require_relative 'vanilla/level'

  # map
  require_relative 'vanilla/map_utils'
  require_relative 'vanilla/map'

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

  # message system
  require_relative 'vanilla/messages'

  # I18n for localization
  require 'i18n'

  # Setup I18n if it hasn't been set up already (like in tests)
  if I18n.load_path.empty?
    I18n.load_path += Dir[File.expand_path('../config/locales/*.yml', __dir__)]
    I18n.default_locale = :en
  end

  # Have a seed for the random number generator
  # This is used to generate the same map for the same seed
  # This is useful for testing
  # This is a global variable so that it can be accessed by the map generator
  # and the game loop
  $seed = nil
  $game_instance = nil

  # Get the current game turn
  # @return [Integer] The current game turn or 0 if the game is not running
  def self.game_turn
    $game_instance&.turn || 0
  end

  # Get the current event manager
  # @return [EventManager] The current event manager or nil if not available
  def self.event_manager
    $game_instance&.instance_variable_get(:@event_manager)
  end

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

      # Initialize render system
      @render_system = Systems::RenderSystemFactory.create

      # Input handler translates raw keyboard input into game commands
      @input_handler = InputHandler.new(@logger, @event_manager, @render_system)

      # Initialize message system
      @message_manager = Messages::MessageManager.new(@logger, @render_system)

      # Set turn counter
      @turn = 0

      # Store reference to current game instance
      $game_instance = self
    end

    # Get the current turn number
    # @return [Integer] The current turn number
    attr_reader :turn

    # Start the game by initializing the first level and entering the game loop
    # This is the main entry point after initialization
    # @return [void]
    def start
      @logger.info("Starting game loop")

      # Record game start event for debugging and analytics
      @event_manager.publish_event(Events::Types::GAME_STARTED)

      # Welcome message
      @message_manager.log_translated("game.welcome", importance: :success)

      # Add some additional messages to ensure the message panel is visible
      @message_manager.log_translated("ui.prompt_move", importance: :info)
      @message_manager.log_translated("exploration.enter_room",
                                     importance: :info,
                                     category: :exploration,
                                     metadata: { room_type: "dimly lit" })

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

      # Display goodbye message
      @message_manager.log_translated("game.goodbye")

      # Clear global reference
      $game_instance = nil
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

      # Set up message panel below the map area
      # Position it just below the grid
      grid_rows = level.grid.rows
      grid_cols = level.grid.columns
      panel_height = 5 # Show 5 messages at a time

      # Log message panel setup
      @logger.info("Setting up message panel at row #{grid_rows + 1}, width #{grid_cols * 4}, height #{panel_height}")

      # Ensure message panel is positioned with correct width to match the grid rendering
      @message_manager.setup_panel(
        0,                   # x position (left edge)
        grid_rows + 1,       # y position (below the grid)
        grid_cols * 3 + 1,   # width (match grid width in terminal cell units)
        panel_height         # height (show 5 messages)
      )

      # Add a startup message to make the panel visible
      @message_manager.log_translated("game.startup_hint",
                                     importance: :info,
                                     category: :system,
                                     metadata: { difficulty: difficulty })

      # Add a movement hint
      @message_manager.log_translated("ui.prompt_move",
                                     importance: :info,
                                     category: :ui)

      # Initial render of the level
      all_entities = level.all_entities + monster_system.monsters
      @render_system.render(all_entities, level.grid)

      # Render message panel
      @message_manager.render(@render_system)

      # Store the monster system with the level for later access
      level.instance_variable_set(:@monster_system, monster_system)

      level
    end

    # The main game loop that implements the Game Loop pattern
    # This loop continues until the player exits or the game ends
    # @param level [Level] the current game level
    # @return [void]
    def game_loop(level)
      # Flag to track exit request
      exit_requested = false

      loop do
        # 1. START FRAME - mark the beginning of a new turn
        @event_manager.publish_event(Events::Types::TURN_STARTED)

        # 2. PROCESS INPUT - get and process player input
        exit_requested = false

        # Clear any buffered input before getting new input
        # This helps prevent issues after level transitions
        while STDIN.ready?
          STDIN.read(1)
        end

        # Allow a small delay to prevent input immediately after transition
        sleep(0.1)

        command = process_input(level)

        # Check if player wants to exit the game
        if command.is_a?(Vanilla::Commands::ExitCommand)
          exit_requested = true
          break
        end

        # 3. UPDATE GAME STATE - update game world and check conditions
        monster_system = level.instance_variable_get(:@monster_system)

        # Update monster positions according to AI
        monster_system.update

        # Handle collisions between player and monsters
        handle_collisions(level, monster_system)

        # 4. RENDER - update the display to reflect the new state
        all_entities = level.all_entities + monster_system.monsters
        @render_system.render(all_entities, level.grid)

        # Render message panel
        @message_manager.render(@render_system)

        # Check for stairs and level transition
        if level.player_at_stairs?
          @logger.info("Player at stairs - transitioning to new level")
          level = handle_level_transition(level)

          # Re-render the new level
          monster_system = level.instance_variable_get(:@monster_system)
          all_entities = level.all_entities + monster_system.monsters
          @render_system.render(all_entities, level.grid)

          # Re-render message panel
          @message_manager.render(@render_system)

          # Display a helpful message about controls
          @message_manager.log_translated("ui.level_change_hint",
                                         category: :system,
                                         importance: :info)
        end

        # END FRAME - mark the end of the turn
        @event_manager.publish_event(Events::Types::TURN_ENDED)
        @turn += 1

        # Exit check
        break if exit_requested
      end
    end

    # Process player input and convert it to game commands
    # @param level [Level] the current game level
    # @return [Command] the command based on player input
    def process_input(level)
      # Get raw keyboard input
      key = STDIN.getch

      # First try to handle input with message system
      if handled_by_message_system = try_handle_with_message_system(key)
        return Vanilla::Commands::NoOpCommand.new(@logger, "Input handled by message system")
      end

      # Process into a game command - pass player and grid, not the level
      # The input handler will execute the command internally
      command = @input_handler.handle_input(key, level.player, level.grid)

      # Return the executed command
      command
    end

    # Try to handle input with the message system
    # @param key [String] The raw input key
    # @return [Boolean] Whether the input was handled by the message system
    def try_handle_with_message_system(key)
      # Check if player wants to quit the game
      if key == "q" || key == "Q"
        @logger.info("Player requesting to quit game")
        exit_command = Vanilla::Commands::ExitCommand.new
        exit_command.execute
        return true
      end

      # Check for tab key to toggle message selection mode
      if key == "\t"
        @message_manager.toggle_selection_mode
        return true
      end

      # Special handling for arrow keys
      if key == "\e" && STDIN.ready?
        # It's an escape sequence - probably an arrow key
        bracket = STDIN.read(1)
        return false unless bracket == "["

        arrow = STDIN.read(1)
        arrow_sym = KEYBOARD_ARROWS[arrow.to_sym]

        return @message_manager.handle_input(arrow_sym) if @message_manager.selection_mode
        return false
      end

      # Handle enter key
      if key == "\r" && @message_manager.selection_mode
        return @message_manager.handle_input(:enter)
      end

      # For all other keys
      @message_manager.handle_input(key)
    end

    # Handle collisions between player and monsters
    # @param level [Level] the current game level
    # @param monster_system [MonsterSystem] the monster system for the level
    # @return [void]
    def handle_collisions(level, monster_system)
      if monster_system.player_collision?
        # Get the player's position
        player_pos = level.player.get_component(:position)

        # Get the monster at the player's position
        monster = monster_system.monster_at(player_pos.row, player_pos.column)
        return unless monster  # Safety check

        @logger.info("Player collided with monster at [#{player_pos.row}, #{player_pos.column}]")

        # Get the monster type - monsters have monster_type not name
        monster_type = monster.monster_type || "monster"

        # Log a message about the collision
        @message_manager.log_translated("combat.player_hit",
                                       category: :combat,
                                       metadata: { enemy: monster_type, damage: 1 })

        # Add combat damage event
        @event_manager.publish_event(Events::Types::COMBAT_DAMAGE, {
          attacker: level.player,
          defender: monster,
          damage: 1
        })
      end
    end

    # Handle transition to a new level when the player reaches stairs
    # @param current_level [Level] the current game level
    # @return [Level] the new game level
    def handle_level_transition(current_level)
      # Calculate new difficulty
      current_difficulty = current_level.difficulty
      new_difficulty = current_difficulty + 1

      # Log a message about finding stairs
      @logger.info("Found stairs leading to depth #{new_difficulty}")
      @message_manager.log_translated("exploration.find_stairs",
                                     category: :exploration,
                                     importance: :success)

      # Create event for level change - use only serializable data
      @event_manager.publish_event(Events::Types::LEVEL_CHANGED, {
        level_difficulty: current_difficulty,
        new_difficulty: new_difficulty,
        player_stats: {
          position: "stairs",
          movement_count: @turn
        }
      })

      # Generate the new level with increased difficulty
      @logger.info("Transitioning to level with difficulty #{new_difficulty}")

      # Try to clear the screen - but handle case where method isn't available
      begin
        if @render_system.respond_to?(:clear_screen)
          @render_system.clear_screen
        else
          # Fallback - print several newlines to visually separate levels
          puts "\n" * 5
          puts "===== DESCENDING TO LEVEL #{new_difficulty} =====\n\n"
        end
      rescue => e
        @logger.warn("Could not clear screen, but continuing: #{e.message}")
      end

      # Render message panel to show transition message
      @message_manager.render(@render_system)

      # Add a small delay to make the transition visible
      sleep(0.5)

      # Initialize new level
      new_level = initialize_level(difficulty: new_difficulty)
      @logger.info("Level transition complete to depth #{new_difficulty}")

      return new_level
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
