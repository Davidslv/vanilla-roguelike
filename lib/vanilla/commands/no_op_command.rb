module Vanilla
  module Commands
    # A command that does nothing when executed
    # Used when input is handled by other systems (like message selection)
    class NoOpCommand
      attr_reader :reason

      # Initialize a new NoOpCommand
      # @param logger [Logger] Logger instance
      # @param reason [String] Reason why this command is being used
      def initialize(logger = nil, reason = "No operation")
        @logger = logger
        @reason = reason
      end

      # Execute the command - does nothing
      # @return [Boolean] Always returns true
      def execute
        @logger.debug("NoOp command executed: #{@reason}") if @logger
        true
      end
    end
  end
end
