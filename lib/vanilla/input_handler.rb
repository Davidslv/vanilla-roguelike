# frozen_string_literal: true

require_relative 'commands/move_command'
require_relative 'commands/exit_command'
require_relative 'commands/null_command'
require_relative 'commands/no_op_command'
require_relative 'commands/change_level_command'
require_relative 'commands/toggle_menu_mode_command'
# Update Flow:
# KeyboardHandler → InputHandler → Creates commands → InputSystem queues them in World.

module Vanilla
  class InputHandler
    # Initialize a new input handler
    # @param world [World]
    # @param event_manager [Vanilla::Events::EventManager, nil] Optional event manager
    def initialize(world, event_manager = nil)
      @world = world
      @logger = Vanilla::Logger.instance
      @event_manager = event_manager
    end

    # Handle a key press from the user
    # @param key [String, Symbol] The key that was pressed
    # @param entity [Vanilla::Entity] The entity to control (typically the player)
    # @return [Vanilla::Commands::Command] The command that was executed
    def handle_input(key)
      # Log the key press
      @logger.info("[InputHandler] User pressed key: #{key}")

      entity = @world.get_entity_by_name('Player')
      unless entity
        @logger.error("[InputHandler] No player entity found")
        return
      end

      publish_key_press_event(key, entity)
      # Create and execute the command
      command = process_command(key, entity)
      @world.queue_command(command) if command # Queue directly to World

      publish_command_issued_event(command)

      command
    end

    private

    def publish_key_press_event(key, entity)
      # Publish key press event if event manager is available
      return unless @event_manager

      @event_manager.publish_event(
        Vanilla::Events::Types::KEY_PRESSED,
        self,
        { key: key, entity_id: entity.id }
      )
    end

    def publish_command_issued_event(command)
      # Publish command issued event if event manager is available
      return unless @event_manager

      @event_manager.publish_event(
        Vanilla::Events::Types::COMMAND_ISSUED,
        self,
        { command: command }
      )
    end

    # Create a command based on the key that was pressed
    # @param key [String, Symbol] The key that was pressed
    # @param entity [Vanilla::Entity] The entity to control
    # @return [Vanilla::Commands::Command] The command to execute
    def process_command(key, entity)
      case key
      when "k", "K", :KEY_UP
        @logger.info("[InputHandler] User attempting to move NORTH")
        Commands::MoveCommand.new(entity, :north)
      when "j", "J", :KEY_DOWN
        @logger.info("[InputHandler] User attempting to move SOUTH")
        Commands::MoveCommand.new(entity, :south)
      when "l", "L", :KEY_RIGHT
        @logger.info("[InputHandler] User attempting to move EAST")
        Commands::MoveCommand.new(entity, :east)
      when "h", "H", :KEY_LEFT
        @logger.info("[InputHandler] User attempting to move WEST")
        Commands::MoveCommand.new(entity, :west)
      when "m", "M", :KEY_MENU
        @logger.info("[InputHandler] User attempting to toggle message menu")
        Commands::ToggleMenuModeCommand.new
      when "q", "\C-c", "\u0003" # 'q' or Ctrl+C
        @logger.info("[InputHandler] User attempting to exit game")
        Commands::ExitCommand.new
      else
        @logger.debug("[InputHandler] Unknown key pressed: #{key.inspect}")
        Commands::NullCommand.new
      end
    end
  end
end
