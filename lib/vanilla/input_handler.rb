require_relative 'commands/move_command'
require_relative 'commands/exit_command'
require_relative 'commands/null_command'
require_relative 'commands/no_op_command'

module Vanilla
  class InputHandler
    # Initialize a new input handler
    # @param logger [Logger] Logger instance
    # @param event_manager [Vanilla::Events::EventManager, nil] Optional event manager
    # @param render_system [Vanilla::Systems::RenderSystem, nil] Optional render system
    def initialize(logger = Vanilla::Logger.instance, event_manager = nil, render_system = nil)
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
      @logger.info("Player pressed key: #{key}")

      # Publish key press event if event manager is available
      if @event_manager
        @event_manager.publish_event(
          Vanilla::Events::Types::KEY_PRESSED,
          self,
          { key: key, entity_id: entity.id }
        )
      end

      # Create and execute the command
      command = create_command(key, entity, grid)

      # Publish command issued event if event manager is available
      if @event_manager && command.class != Commands::NullCommand
        command_type = command.class.name.split('::').last.gsub('Command', '').downcase
        event_type = "#{command_type}_command_issued"

        @event_manager.publish_event(
          event_type,
          command,
          { entity_id: entity.id }
        )
      end

      # Execute the command and return it
      command.execute
      command
    end

    private

    # Create a command based on the key that was pressed
    # @param key [String, Symbol] The key that was pressed
    # @param entity [Vanilla::Entity] The entity to control
    # @param grid [Vanilla::MapUtils::Grid] The current game grid
    # @return [Vanilla::Commands::Command] The command to execute
    def create_command(key, entity, grid)
      case key
      when "k", "K", :KEY_UP
        @logger.info("Player attempting to move UP")
        Commands::MoveCommand.new(entity, :up, grid, @render_system)
      when "j", "J", :KEY_DOWN
        @logger.info("Player attempting to move DOWN")
        Commands::MoveCommand.new(entity, :down, grid, @render_system)
      when "l", "L", :KEY_RIGHT
        @logger.info("Player attempting to move RIGHT")
        Commands::MoveCommand.new(entity, :right, grid, @render_system)
      when "h", "H", :KEY_LEFT
        @logger.info("Player attempting to move LEFT")
        Commands::MoveCommand.new(entity, :left, grid, @render_system)
      when "\C-c", "q"
        Commands::ExitCommand.new
      else
        @logger.debug("Unknown key pressed: #{key.inspect}")
        Commands::NullCommand.new
      end
    end
  end
end