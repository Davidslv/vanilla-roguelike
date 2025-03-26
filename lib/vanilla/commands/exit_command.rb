# frozen_string_literal: true

require_relative 'command'

module Vanilla
  module Commands
    class ExitCommand < Command
      def initialize
        super()
        @logger = Vanilla::Logger.instance
        @logger.info("[ExitCommand] ExitCommand initialized")
      end

      def execute(world)
        @logger.info("[ExitCommand] Executing ExitCommand")
        @logger.info("[ExitCommand] Executed? #{@executed}")
        return if @executed

        world.quit = true
        @logger.info("[ExitCommand] ExitCommand executed: Game is quitting.")
        @executed = true
      end
    end
  end
end
