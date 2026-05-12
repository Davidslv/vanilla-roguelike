# frozen_string_literal: true

module Vanilla
  module Algorithms
    class AbstractAlgorithm
      def self.on(grid)
        raise NotImplementedError, "#{name} must implement .on(grid)"
      end
    end
  end
end
