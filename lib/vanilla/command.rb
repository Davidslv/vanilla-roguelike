module Vanilla
  class Command
    def initialize(key:, grid:, unit:)
      @key = key
      @grid, @unit = grid, unit
      @logger = Vanilla::Logger.instance
    end

    def self.process(key:, grid:, unit:)
      new(key: key, grid: grid, unit: unit).process
    end

    def process
      case key
      when "k", "K", :KEY_UP
        @logger.info("Player attempting to move UP")
        Vanilla::Draw.movement(grid: grid, unit: unit, direction: :up)
      when "j", "J", :KEY_DOWN
        @logger.info("Player attempting to move DOWN")
        Vanilla::Draw.movement(grid: grid, unit: unit, direction: :down)
      when "l", "L", :KEY_RIGHT
        @logger.info("Player attempting to move RIGHT")
        Vanilla::Draw.movement(grid: grid, unit: unit, direction: :right)
      when "h", "H", :KEY_LEFT
        @logger.info("Player attempting to move LEFT")
        Vanilla::Draw.movement(grid: grid, unit: unit, direction: :left)
      when "\C-c", "q"
        @logger.info("Player exiting game")
        exit
      else
        @logger.debug("Unknown key pressed: #{key.inspect}")
      end
    end

    private

    attr_reader :key, :grid, :unit
  end
end
