require 'pry'
require 'logger'
require 'set'
require 'securerandom'
require 'io/console'

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

  # World and ECS
  require_relative 'vanilla/world'
  require_relative 'vanilla/entity_factory'
  require_relative 'vanilla/keyboard_handler'
  require_relative 'vanilla/display_handler'
  require_relative 'vanilla/level_generator'

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

  # inventory system
  require_relative 'vanilla/inventory'

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
    @@services = {}

    def self.register(key, service)
      @@services[key] = service
    end

    def self.get(key)
      @@services[key]
    end

    def self.unregister(key)
      @@services.delete(key)
    end

    def self.clear
      @@services.clear
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
    attr_reader :level, :player, :monster_system, :scheduler, :render_system, :message_system, :inventory_system
    attr_accessor :game_over

    def initialize(options = {})
      @logger = options[:logger] || Logger.instance
      @screen_transition_delay = options[:screen_transition_delay] || 0.5
      @seed = options[:seed]
      @difficulty = options[:difficulty] || 1
      @scheduler = Scheduler.new
      @game_over = false
      @current_turn = 0

      # Initialize render system
      @render_system = Vanilla::Systems::RenderSystemFactory.create

      # Initialize message system using the facade
      @message_system = Messages::MessageSystem.new(@logger, @render_system)

      # Initialize inventory system
      @inventory_system = Inventory::InventorySystemFacade.new(@logger, @render_system)

      # Welcome message - use critical importance to make it more visible
      @message_system.log_message("game.welcome",
                                metadata: { difficulty: @difficulty },
                                importance: :critical,
                                category: :system)

      # Add some additional messages to ensure the message panel is visible
      @message_system.log_message("ui.prompt_move",
                                metadata: {},
                                importance: :info,
                                category: :system)

      @message_system.log_message("exploration.enter_room",
                                metadata: { room: "entrance" },
                                importance: :info,
                                category: :exploration)

      # Make intro messages visible before the level is generated
      clear_screen_with_space_for_messages
      print_title_screen
      puts "Hint: Look below the map for game messages!\n\n"

      # Initialize the level
      start_new_level
    end

    # Display game title
    def print_title_screen
      puts ""
      puts "========================================================="
      puts "===             VANILLA ROGUELIKE GAME               ==="
      puts "========================================================="
      puts "===  Use arrow keys or hjkl to move                  ==="
      puts "===  Press 'q' to quit                               ==="
      puts "===  Difficulty: #{@difficulty.to_s.ljust(35)}  ==="
      puts "===  Seed: #{@seed.to_s.ljust(40)}  ==="
      puts "========================================================="
      puts ""
    end

    # Exit the game and shut down cleanly
    def exit_game
      # Display goodbye message
      @message_system.log_message("game.goodbye")
      render # final render to show goodbye
      sleep 1
      clear_screen
      puts "Thanks for playing!"
      exit(0)
    end

    # Start the main game loop
    def start
      render
      until @game_over
        key = STDIN.getch
        handle_input(key)
      end
    end

    # Get the current game turn
    # @return [Integer] The current turn number
    def self.game_turn
      Vanilla.current_game.instance_variable_get(:@current_turn)
    end

    # Get the currently running game instance
    # @return [Game] The current game
    def self.current_game
      Vanilla::ServiceRegistry.get(:game)
    end

    public

    def cleanup
      @message_system.cleanup if @message_system
      @inventory_system.cleanup if @inventory_system
      ServiceRegistry.clear
    end

    private

    # Set up message panel below the map area
    def setup_message_panel
      # Map has row_count and column_count
      # Each grid cell takes 4 x 2 characters
      # So the map position on screen is actually column_count * 4 wide and row_count
      # takes 2 rows per grid cell plus border, so we need to position messages at:
      #   y = row_count * 2 + 1
      grid_rows = @level.grid.rows
      grid_cols = @level.grid.columns
      terminal_rows = grid_rows * 2 + 1
      panel_height = 5 # Show 5 messages at a time

      # Log message panel setup
      @logger.info("Setting up message panel at terminal row #{terminal_rows}, width #{grid_cols * 4}, height #{panel_height}")

      # Ensure message panel is positioned with correct width to match the grid rendering
      @message_system.setup_panel(
        0,                  # x position - left aligned
        terminal_rows,      # y position - just below the map
        grid_cols * 4,      # width matches the grid width
        panel_height         # height (show 5 messages)
      )

      # Add a startup message to make the panel visible
      @message_system.log_message("game.startup_hint",
                                  metadata: {},
                                  importance: :normal,
                                  category: :system)

      @message_system.log_message("ui.prompt_move",
                                  metadata: {},
                                  importance: :info,
                                  category: :system)
    end

    # Render the game state
    def render
      # Render the level
      @render_system.render(@level.all_entities, @level.grid)

      # Render message panel
      @message_system.render(@render_system)
    end

    # Clear the screen and ensure enough terminal space for messages
    def clear_screen_with_space_for_messages
      # First clear screen
      clear_screen

      # Add extra newlines to ensure messages are visible even on small terminals
      buffer_rows = 5

      buffer_rows.times do
        puts ""
      end
    end

    # Clear the screen using ANSI escape sequence
    def clear_screen
      print "\e[H\e[2J"
    end

    # Initialize a new level
    def start_new_level
      # Clear old services
      Vanilla::ServiceRegistry.clear
      @logger.debug("Cleared service registry")

      # Register the game in the service registry
      Vanilla::ServiceRegistry.register(:game, self)
      @logger.debug("Registered game in service registry")

      # Create a new level with fresh entities
      @level = Level.new(difficulty: @difficulty, seed: @seed)
      @logger.debug("Created new level with difficulty: #{@difficulty}")
      @player = @level.player
      @logger.debug("Retrieved player from level")

      # Set up the monster system
      @monster_system = Vanilla::Systems::MonsterSystem.new(grid: @level.grid, player: @player, logger: @logger)
      @monster_system.spawn_monsters(@difficulty)

      # Add inventory component to player if not already present
      unless @player.has_component?(:inventory)
        @player.add_component(Vanilla::Components::InventoryComponent.new)
      end

      # Add some starter items to the player's inventory
      add_starter_items_to_player if @difficulty == 1

      # Set up message panel
      setup_message_panel

      # Hint about level transition via stairs
      @message_system.log_message("ui.level_change_hint",
                                  metadata: {},
                                  importance: :info,
                                  category: :system)
    end

    # Add starter items to the player's inventory on first level
    def add_starter_items_to_player
      return unless @player && @player.has_component?(:inventory) && @inventory_system

      # Create a healing potion
      potion = @inventory_system.item_factory.create_potion(
        "Healing Potion",
        :heal,
        20,
        {
          description: "A small vial of red liquid that restores health.",
          character: '!',
          color: :red
        }
      )

      # Create a simple weapon
      sword = @inventory_system.item_factory.create_weapon(
        "Short Sword",
        5,
        {
          description: "A simple but effective weapon.",
          character: '/',
          color: :white
        }
      )

      # Create some gold coins
      gold = Vanilla::Components::Entity.new
      gold.add_component(Vanilla::Components::ItemComponent.new(
        name: "Gold Coins",
        description: "A small pouch of gold coins.",
        item_type: :currency,
        stackable: true,
        stack_size: 10
      ))

      # Create a render component using the same approach as in ItemFactory
      character = '$'
      render_component = Vanilla::Components::RenderComponent.new(
        character: character,
        color: :yellow,
        layer: 5,
        entity_type: 'item'
      )

      # Add the render component to the gold
      gold.add_component(render_component)

      gold.add_component(Vanilla::Components::CurrencyComponent.new(10, :gold))

      # Add the items to the player's inventory
      @inventory_system.add_item_to_entity(@player, potion)
      @inventory_system.add_item_to_entity(@player, sword)
      @inventory_system.add_item_to_entity(@player, gold)

      # Log a message about the starting items
      @message_system.log_message("items.starter_kit",
                                 importance: :info,
                                 category: :item)
    end

    # Increase the difficulty and start a new level
    def next_level
      @difficulty += 1
      @current_turn = 0
      start_new_level
    end

    # Handle a player's keyboard input
    def handle_input(key)
      # First check if inventory system should handle the input
      if @inventory_system.inventory_visible?
        if @inventory_system.handle_inventory_input(key, @player)
          # Input was handled by inventory system
          clear_screen_with_space_for_messages
          render
          @message_system.render(@render_system)
          return
        end
      end

      # Check for inventory toggle key
      if key == 'i'
        @inventory_system.toggle_inventory_view(@player)
        clear_screen_with_space_for_messages
        render
        @message_system.render(@render_system)
        return
      end

      # Try to handle input with message system
      return if try_handle_with_message_system(key)

      # Handle movement keys directly with our special method
      case key
      when "k", "K", :KEY_UP
        @logger.info("Player attempting to move UP")
        return if move_player(:north)
      when "j", "J", :KEY_DOWN
        @logger.info("Player attempting to move DOWN")
        return if move_player(:south)
      when "l", "L", :KEY_RIGHT
        @logger.info("Player attempting to move RIGHT")
        return if move_player(:east)
      when "h", "H", :KEY_LEFT
        @logger.info("Player attempting to move LEFT")
        return if move_player(:west)
      when "\C-c", "q"
        exit_game
      end

      # For non-movement keys, use the regular input handler
      # Create a handler for the player's input
      input_handler = InputHandler.new(@logger, @event_manager, @render_system)

      # Try to handle the input and get the resulting command
      command = input_handler.handle_input(key, @player, @level.grid)

      # Process the command
      case command
      when Commands::ExitCommand
        exit_game
      when Commands::MoveCommand
        # Debug log to check movement handling
        @logger.debug("Processing MoveCommand, checking for items and stairs")

        # Check if there are any items at the new position after movement
        if @player.has_component?(:position)
          position = @player.get_component(:position)
          @inventory_system.check_for_items_at_position(@player, @level)
        end

        # Increment the turn counter
        @current_turn += 1

        # Check if player has reached the stairs
        @logger.debug("Checking if player is at stairs position")
        if @level.player_at_stairs?
          @logger.info("FOUND STAIRS: Player at stairs position!")
          @message_system.log_message("level.stairs_found",
                                   importance: :success,
                                   category: :level)

          # Call the more robust transition method
          transition_to_next_level
          return
        else
          @logger.debug("Player is not at stairs position")
        end

        # Update scheduled entities
        @scheduler.update
      end
    end

    # Check for collisions with monsters
    def check_for_monster_collisions
      # Check if the player has collided with a monster
      if @monster_system.player_collision?
        monster = @monster_system.monster_at(@player.position.row, @player.position.column)

        # Log a message about the collision - make it a critical message for visibility
        @message_system.log_message("combat.player_hit",
                                  { monster: monster ? "a monster" : "something" },
                                  importance: :critical,
                                  category: :combat)

        # Also add a direct warning message that's more visible
        @message_system.log_message("combat.enemy_hit",
                                  { damage: 5, remaining_hp: 95 },
                                  importance: :warning,
                                  category: :combat)

        # TODO: Implement proper combat system
        # For now, just prevent the player from moving onto the monster tile
        # The message should be sufficient to indicate that combat happened
      end

      # Force a re-render after collision to ensure messages are visible
      clear_screen_with_space_for_messages
      render
      @message_system.render(@render_system)
    end

    # Handle transition to the next level
    def transition_to_next_level
      begin
        # Simplify the transition to address the stairs issue
        @logger.info("TRANSITION: Player found stairs, going to next level")

        # Increment difficulty
        @difficulty += 1

        # Clear screen for transition
        clear_screen
        puts "Descending to level #{@difficulty}..."
        puts "Please wait..."
        sleep 1

        # Save old level reference
        old_level = @level

        # Re-register game in service registry first
        Vanilla::ServiceRegistry.clear
        Vanilla::ServiceRegistry.register(:game, self)

        # Create a new level with higher difficulty
        @level = Level.new(difficulty: @difficulty, seed: nil)
        @player = @level.player

        # Re-setup monster system
        @monster_system = Vanilla::Systems::MonsterSystem.new(grid: @level.grid, player: @player, logger: @logger)
        @monster_system.spawn_monsters(@difficulty)

        # Re-setup message panel with new grid dimensions
        setup_message_panel

        # Reset turn counter
        @current_turn = 0

        # Force garbage collection of old level
        old_level = nil
        GC.start

        # Redraw everything
        clear_screen_with_space_for_messages
        print_title_screen
        render

        # Add success message
        @message_system.log_message(
          "level.descended",
          metadata: { level: @difficulty },
          importance: :success,
          category: :level
        )
      rescue => e
        # Log the error
        @logger.error("Error during level transition: #{e.message}")
        @logger.error(e.backtrace.join("\n"))

        # Display error to player
        clear_screen
        puts "Error transitioning to next level: #{e.message}"
        puts "Press any key to exit..."
        STDIN.getch
        exit(1)
      end
    end

    # First try to handle input with message system
    def try_handle_with_message_system(key)
      handled_by_message_system = @message_system.handle_input(key)

      # If the message system handled it, we're done
      if handled_by_message_system
        # Re-render after message system input
        clear_screen_with_space_for_messages
        render
        @message_system.render(@render_system)
      end

      handled_by_message_system
    end

    # Wait for a keypress and return it
    # This integrates with the message system for handling certain keys
    def wait_for_keypress
      loop do
        # Check for keypress
        if STDIN.ready?
          key = STDIN.getch

          # Check for arrow keys (escape sequences)
          if key == "\e"
            # Possibly an arrow key
            if STDIN.ready?
              # Read the next character
              second_char = STDIN.getch
              if second_char == '['
                # It's an escape sequence
                if STDIN.ready?
                  # Read the actual arrow key
                  third_char = STDIN.getch
                  arrow_sym = KEYBOARD_ARROWS[third_char.to_sym]

                  # Check for message system selection mode or inventory mode
                  if @message_system.selection_mode? || @inventory_system.inventory_visible?
                    return arrow_sym
                  end

                  # Otherwise, translate to h/j/k/l
                  key = case arrow_sym
                        when :KEY_UP then 'k'
                        when :KEY_DOWN then 'j'
                        when :KEY_LEFT then 'h'
                        when :KEY_RIGHT then 'l'
                        else key
                        end
                end
              end
            end
          end

          # Check for tab key to toggle message selection mode
          if key == "\t"
            @message_system.toggle_selection_mode
            clear_screen_with_space_for_messages
            render
            @message_system.render(@render_system)
            next
          end

          # If in message selection mode, handle arrow keys directly
          if @message_system.selection_mode?
            if key == 'k' || key == 'h'
              return :KEY_UP
            elsif key == 'j' || key == 'l'
              return :KEY_DOWN
            end
          end

          # Enter key in selection mode
          if key == "\r" && @message_system.selection_mode?
            return :enter
          end

          # Check if the message system should handle this
          if try_handle_with_message_system(key)
            next  # Get another key since this one was consumed
          end

          return key
        end

        # No key ready, sleep briefly to avoid CPU spin
        sleep 0.01
      end
    end

    # Handle direct player movement and check for stairs
    def move_player(direction)
      @logger.debug("Game.move_player called with direction: #{direction}")

      # Get the player's position before movement
      player_pos = @player.get_component(:position)
      old_row, old_col = player_pos.row, player_pos.column
      @logger.debug("Player position before movement: [#{old_row}, #{old_col}]")

      # Create a movement system
      movement_system = Vanilla::Systems::MovementSystem.new(@level.grid)

      # Move the player
      success = movement_system.move(@player, direction)
      @logger.debug("Movement success: #{success}")

      if success
        # Get new position
        new_row, new_col = player_pos.row, player_pos.column
        @logger.debug("Player position after movement: [#{new_row}, #{new_col}]")

        # Update the level's grid with the new position
        @level.update_grid_with_entities

        # Render the updated state
        render

        # Check directly if the player is at the same position as the stairs
        stairs_pos = @level.stairs.get_component(:position)

        if stairs_pos
          @logger.debug("Player-Stairs Check - Stairs: [#{stairs_pos.row}, #{stairs_pos.column}], Player: [#{new_row}, #{new_col}]")

          if new_row == stairs_pos.row && new_col == stairs_pos.column
            @logger.info("DIRECT CHECK: Player is at stairs position! [#{new_row}, #{new_col}]")

            # Update player's stairs component
            if @player.has_component?(:stairs)
              @player.get_component(:stairs).found_stairs = true
            end

            # Log message and show renderer
            @message_system.log_message("level.stairs_found", importance: :success, category: :level)
            render

            # Add a small delay
            sleep 0.5

            # Transition to next level
            transition_to_next_level
            return true
          end
        end
      end

      return success
    end
  end

  class Scheduler
    def initialize
      @entities = []
    end

    def register(entity)
      @entities << entity
    end

    def unregister(entity)
      @entities.delete(entity)
    end

    def update
      @entities.each { |entity| entity.update }
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
