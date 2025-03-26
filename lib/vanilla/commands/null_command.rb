# frozen_string_literal: true

require_relative 'command'

module Vanilla
  module Commands
    class NullCommand < Command
      def execute(_world)
        # Do nothing
        # NullCommand is not considered a successful execution
        @executed = false
        true
      end
    end
  end
end
