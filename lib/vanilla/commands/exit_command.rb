require_relative 'command'

module Vanilla
  module Commands
    class ExitCommand < Command
      def initialize
        @logger = Vanilla::Logger.instance
      end

      def execute
        @logger.info("Player exiting game")
        exit
      end
    end
  end
end