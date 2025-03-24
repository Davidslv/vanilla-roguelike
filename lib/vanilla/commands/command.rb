# frozen_string_literal: true

module Vanilla
  module Commands
    class Command
      # Flag to track if the command was executed successfully
      attr_reader :executed

      def initialize
        @executed = false
      end

      def execute
        raise NotImplementedError, "#{self.class} must implement #execute"
      end
    end
  end
end
