# frozen_string_literal: true

require_relative 'commands/move_command'
require_relative 'commands/exit_command'
require_relative 'commands/null_command'
require_relative 'commands/no_op_command'

# Update Flow:
# KeyboardHandler → InputHandler → Creates commands → InputSystem queues them in World.

module Vanilla
  class InputHandler
    # Initialize a new input handler
    # @param world [World]
    # @param logger [Logger] Logger instance
    # @param event_manager [Vanilla::Events::EventManager, nil] Optional event manager
    # @param render_system [Vanilla::Systems::RenderSystem, nil] Optional render system
    def initialize(world, logger = Vanilla::Logger.instance, event_manager = nil, render_system = nil)
      @world = world
      @logger = logger
      @event_manager = event_manager
      @render_system = render_system || Vanilla::Systems::RenderSystemFactory.create
    end

    # Handle a key press from the user
    # @param key [String, Symbol] The key that was pressed
    # @param entity [Vanilla::Entity] The entity to control (typically the player)
    # @param grid [Vanilla::MapUtils::Grid] The current game grid
    # @return [Vanilla::Commands::Command] The command that was executed
    def handle_input(key, entity, grid)
      # Log the key press
      @logger.info("[InputHandler] User pressed key: #{key}")

      publish_key_press_event(key, entity)

      # Create and execute the command
      command = process_command(key, entity, grid)

      publish_command_issued_event(command)

      # Execute the command and return it
      command.execute
      command
    end

    private

    def publish_key_press_event(key, entity)
      # Publish key press event if event manager is available
      if @event_manager
        @event_manager.publish_event(
          Vanilla::Events::Types::KEY_PRESSED,
          self,
          { key: key, entity_id: entity.id }
        )
      end
    end

    def publish_command_issued_event(command)
      # Publish command issued event if event manager is available
      if @event_manager
        @event_manager.publish_event(
          Vanilla::Events::Types::COMMAND_ISSUED,
          self,
          { command: command }
        )
      end
    end

    # Create a command based on the key that was pressed
    # @param key [String, Symbol] The key that was pressed
    # @param entity [Vanilla::Entity] The entity to control
    # @param grid [Vanilla::MapUtils::Grid] The current game grid
    # @return [Vanilla::Commands::Command] The command to execute
    def process_command(key, entity, grid)
      case key
      when "k", "K", :KEY_UP
        @logger.info("[InputHandler] User attempting to move UP")
        Commands::MoveCommand.new(entity, :up, grid, @render_system)
      when "j", "J", :KEY_DOWN
        @logger.info("[InputHandler] User attempting to move DOWN")
        Commands::MoveCommand.new(entity, :down, grid, @render_system)
      when "l", "L", :KEY_RIGHT
        @logger.info("[InputHandler] User attempting to move RIGHT")
        Commands::MoveCommand.new(entity, :right, grid, @render_system)
      when "h", "H", :KEY_LEFT
        @logger.info("[InputHandler] User attempting to move LEFT")
        Commands::MoveCommand.new(entity, :left, grid, @render_system)
      when "q", "\C-c", "\u0003" # 'q' or Ctrl+C
        Commands::ExitCommand.new
      else
        @logger.debug("[InputHandler] Unknown key pressed: #{key.inspect}")
        Commands::NullCommand.new
      end
    end
  end
end
