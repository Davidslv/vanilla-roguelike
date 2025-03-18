require_relative 'input_handler'

module Vanilla
  class Command
    def initialize(key:, grid:, unit:)
      @key = key
      @grid = grid
      @unit = unit
      @logger = Vanilla::Logger.instance
      @input_handler = Vanilla::InputHandler.new(@logger)

      # Log deprecation warning if using legacy Unit
      if !unit.respond_to?(:has_component?) || !unit.has_component?(:position)
        @logger.warn("DEPRECATED: Using legacy Unit object in Command. Please use Entity with components.")
      end
    end

    def self.process(key:, grid:, unit:)
      new(key: key, grid: grid, unit: unit).process
    end

    def process
      # Log deprecation warning if using legacy Unit
      if !@unit.respond_to?(:has_component?) || !@unit.has_component?(:position)
        @logger.warn("DEPRECATED: Using legacy Unit object in Command. Please use Entity with components.")
      end

      # Delegate to input handler
      @input_handler.handle_input(@key, @unit, @grid)
    end

    private

    attr_reader :key, :grid, :unit
  end
end
