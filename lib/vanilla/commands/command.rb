module Vanilla
  module Commands
    class Command
      def execute
        raise NotImplementedError, "#{self.class} must implement #execute"
      end
    end
  end
end