require_relative 'command'

module Vanilla
  module Commands
    class NullCommand < Command
      def execute
        # Do nothing
        true
      end
    end
  end
end