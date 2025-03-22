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
  require_relative 'vanilla/message_system'

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
  $seed = nil

  # Service registry to replace global variables
  # Implementation of Service Locator pattern
  class ServiceRegistry
    class << self
      def register(service_name, instance)
        services[service_name] = instance
      end

      def get(service_name)
        services[service_name]
      end

      def unregister(service_name)
        services.delete(service_name)
      end

      def services
        @services ||= {}
      end

      def reset
        @services = {}
      end
    end
  end

  # Get the current game turn
  # @return [Integer] The current game turn or 0 if the game is not running
  def self.game_turn
    game = ServiceRegistry.get(:game)
    game&.turn || 0
  end

  # Get the current event manager
  # @return [EventManager] The current event manager or nil if not available
  def self.event_manager
    game = ServiceRegistry.get(:game)
    game&.instance_variable_get(:@event_manager)
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

      # Initialize message system using the facade
      @message_system = Messages::MessageSystem.new(@logger, @render_system)

      # Set turn counter
      @turn = 0

      # Store reference to current game instance
      ServiceRegistry.register(:game, self)
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

      # Welcome message - use critical importance to make it more visible
      @message_system.log_message("game.welcome",
                                 importance: :critical,
                                 category: :system)

      # Add some additional messages to ensure the message panel is visible
      @message_system.log_message("ui.prompt_move",
                                 importance: :warning,
                                 category: :ui)

      @message_system.log_message("exploration.enter_room",
                                 importance: :success,
                                 category: :exploration,
                                 metadata: { room_type: "dimly lit" })

      # Make intro messages visible before the level is generated
      puts "\n\n=== WELCOME TO VANILLA ROGUELIKE ===\n\n"
      puts "Loading game..."
      puts "Hint: Look below the map for game messages!\n\n"
      sleep(0.8)

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
      @message_system.log_message("game.goodbye")

      # Clear global reference
      ServiceRegistry.unregister(:game)
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
      # Position it just below the grid - the key issue is grid rendering
      # takes 2 rows per grid cell plus border, so we need to position messages at:
      # y = grid.rows * 2 + 1 (for the bottom border)
      grid_rows = level.grid.rows
      grid_cols = level.grid.columns
      panel_height = 5 # Show 5 messages at a time

      # Calculate actual terminal rows based on grid size
      # Each grid cell is 1 row for content and 1 row for bottom border
      # Plus 1 row for the top border
      terminal_rows = grid_rows * 2 + 1

      # Log message panel setup
      @logger.info("Setting up message panel at terminal row #{terminal_rows}, width #{grid_cols * 4}, height #{panel_height}")

      # Ensure message panel is positioned with correct width to match the grid rendering
      @message_system.setup_panel(
        0,                   # x position (left edge)
        terminal_rows,       # y position (below the grid) - this is the key fix
        grid_cols * 4,       # width (match grid width in terminal cell units)
        panel_height         # height (show 5 messages)
      )

      # Add a startup message to make the panel visible
      @message_system.log_message("game.startup_hint",
                                     importance: :info,
                                     category: :system,
                                     metadata: { difficulty: difficulty })

      # Add a movement hint
      @message_system.log_message("ui.prompt_move",
                                     importance: :info,
                                     category: :ui)

      # Initial render of the level
      all_entities = level.all_entities + monster_system.monsters
      @render_system.render(all_entities, level.grid)

      # Render message panel
      @message_system.render(@render_system)

      # Store the monster system with the level for later access
      level.instance_variable_set(:@monster_system, monster_system)

      level
    end

    # Clear the screen and ensure enough terminal space for messages
    def clear_screen_with_space_for_messages
      # First clear the screen
      @render_system.clear if @render_system.respond_to?(:clear)

      # Add extra newlines to ensure messages are visible even on small terminals
      puts "\n" * 5
    end

    # The main game loop that implements the Game Loop pattern
    # This loop continues until the player exits or the game ends
    # @param level [Level] the current game level
    # @return [void]
    def game_loop(level)
      # Flag to track exit request
      exit_requested = false

      # Start game loop following classic pattern:
      # 1. Process Input
      # 2. Update Game State
      # 3. Render
      loop do
        # PHASE 1: START FRAME - mark the beginning of a new turn
        @event_manager.publish_event(Events::Types::TURN_STARTED)

        # Clear any buffered input before getting new input
        clear_input_buffer

        # PHASE 2: PROCESS INPUT - get and process player input
        command = process_input(level)

        # Check if player wants to exit the game
        if command.is_a?(Vanilla::Commands::ExitCommand)
          exit_requested = true
          break
        end

        # PHASE 3: UPDATE - update all game systems
        monster_system = update_systems(level)

        # PHASE 4: RENDER - draw updated game state to screen
        render_game_state(level, monster_system)

        # PHASE 5: HANDLE LEVEL TRANSITIONS if needed
        if level.player_at_stairs?
          level = transition_to_new_level(level)
          monster_system = level.instance_variable_get(:@monster_system)

          # Re-render after level transition
          render_game_state(level, monster_system)

          # Display level change hint
          @message_system.log_message("ui.level_change_hint",
                                    category: :system,
                                    importance: :info)
        end

        # PHASE 6: END FRAME - mark the end of the turn
        @event_manager.publish_event(Events::Types::TURN_ENDED)
        @turn += 1

        # Exit check
        break if exit_requested
      end
    end

    # Clear input buffer to prevent buffered inputs
    def clear_input_buffer
      while STDIN.ready?
        STDIN.read(1)
      end
      # Small delay to prevent input immediately after transition
      sleep(0.1)
    end

    # Update all game systems
    # @param level [Level] Current game level
    # @return [MonsterSystem] Updated monster system
    def update_systems(level)
      monster_system = level.instance_variable_get(:@monster_system)
      monster_system.update
      handle_collisions(level, monster_system)
      monster_system
    end

    # Render the current game state
    # @param level [Level] Current game level
    # @param monster_system [MonsterSystem] Monster system for the level
    def render_game_state(level, monster_system)
      # Clear screen and ensure enough space for messages
      clear_screen_with_space_for_messages

      # Render all entities
      all_entities = level.all_entities + monster_system.monsters
      @render_system.render(all_entities, level.grid)

      # Render message panel
      @message_system.render(@render_system)
    end

    # Handle transition to a new level
    # @param current_level [Level] Current game level
    # @return [Level] New game level
    def transition_to_new_level(current_level)
      new_difficulty = current_level.difficulty + 1

      # Clear screen and show transition messages
      clear_screen_with_space_for_messages

      # Log transition events
      @logger.info("Found stairs leading to depth #{new_difficulty}")
      @message_system.log_success("exploration.find_stairs")
      @message_system.log_message("exploration.find_stairs",
                               importance: :critical,
                               category: :exploration)

      # Create event for level change
      @event_manager.publish_event(Events::Types::LEVEL_CHANGED, {
        level_difficulty: current_level.difficulty,
        new_difficulty: new_difficulty,
        player_stats: { position: "stairs", movement_count: @turn }
      })

      # Show transition animation
      monster_system = current_level.instance_variable_get(:@monster_system)
      all_entities = current_level.all_entities + monster_system.monsters
      @render_system.render(all_entities, current_level.grid)
      @message_system.render(@render_system)

      # Delay to make transition visible
      sleep(0.8)

      # Initialize new level
      new_level = initialize_level(difficulty: new_difficulty)
      @logger.info("Level transition complete to depth #{new_difficulty}")

      new_level
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
        @message_system.toggle_selection_mode
        return true
      end

      # Special handling for arrow keys
      if key == "\e" && STDIN.ready?
        # It's an escape sequence - probably an arrow key
        bracket = STDIN.read(1)
        return false unless bracket == "["

        arrow = STDIN.read(1)
        arrow_sym = KEYBOARD_ARROWS[arrow.to_sym]

        return @message_system.handle_input(arrow_sym) if @message_system.selection_mode
        return false
      end

      # Handle enter key
      if key == "\r" && @message_system.selection_mode
        return @message_system.handle_input(:enter)
      end

      # For all other keys
      @message_system.handle_input(key)
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

        # Pause briefly to make sure player notices the collision
        sleep(0.1)

        # Log a message about the collision - make it a critical message for visibility
        @message_system.log_message("combat.player_hit",
                                       category: :combat,
                                       importance: :critical,
                                       metadata: { enemy: monster_type, damage: 1 })

        # Also add a direct warning message that's more visible
        @message_system.log_message("combat.enemy_hit",
                                       category: :combat,
                                       importance: :warning,
                                       metadata: { enemy: monster_type, damage: 1 })

        # Add combat damage event
        @event_manager.publish_event(Events::Types::COMBAT_DAMAGE, {
          attacker: level.player,
          defender: monster,
          damage: 1
        })

        # Force a re-render after collision to ensure messages are visible
        all_entities = level.all_entities + monster_system.monsters
        @render_system.render(all_entities, level.grid)
        @message_system.render(@render_system)
      end
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
