require_relative 'commands/move_command'
require_relative 'commands/exit_command'
require_relative 'commands/null_command'

module Vanilla
  class InputHandler
    def initialize(logger = Vanilla::Logger.instance)
      @logger = logger
    end

    def handle_input(key, entity, grid)
      command = create_command(key, entity, grid)
      command.execute
      command  # Return the command object
    end

    private

    def create_command(key, entity, grid)
      case key
      when "k", "K", :KEY_UP
        @logger.info("Player attempting to move UP")
        Commands::MoveCommand.new(entity, :up, grid)
      when "j", "J", :KEY_DOWN
        @logger.info("Player attempting to move DOWN")
        Commands::MoveCommand.new(entity, :down, grid)
      when "l", "L", :KEY_RIGHT
        @logger.info("Player attempting to move RIGHT")
        Commands::MoveCommand.new(entity, :right, grid)
      when "h", "H", :KEY_LEFT
        @logger.info("Player attempting to move LEFT")
        Commands::MoveCommand.new(entity, :left, grid)
      when "\C-c", "q"
        Commands::ExitCommand.new
      else
        @logger.debug("Unknown key pressed: #{key.inspect}")
        Commands::NullCommand.new
      end
    end
  end
end