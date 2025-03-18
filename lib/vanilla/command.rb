require_relative 'input_handler'

module Vanilla
  class Command
    def initialize(key:, grid:, unit:)
      @key = key
      @grid = grid
      @unit = unit
      @logger = Vanilla::Logger.instance
      @input_handler = Vanilla::InputHandler.new(@logger)
    end

    def self.process(key:, grid:, unit:)
      new(key: key, grid: grid, unit: unit).process
    end

    def process
      # Delegate to input handler
      @input_handler.handle_input(@key, @unit, @grid)
    end

    private

    attr_reader :key, :grid, :unit
  end
end
