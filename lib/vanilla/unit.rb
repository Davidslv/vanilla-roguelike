module Vanilla
  # @deprecated Use Vanilla::Components::Entity with appropriate components instead
  # This class is being phased out in favor of the Entity-Component-System architecture.
  # For position: use PositionComponent
  # For tile: use TileComponent
  # For stairs tracking: use StairsComponent
  class Unit
    attr_accessor :row, :column
    attr_reader :tile
    attr_accessor :found_stairs

    alias found_stairs? found_stairs

    def initialize(row:, column:, tile:, found_stairs: false)
      logger = Vanilla::Logger.instance
      logger.warn("DEPRECATED: #{self.class} is deprecated. Please use Vanilla::Components::Entity with appropriate components instead.")

      @row, @column = row, column
      @tile = tile
      @found_stairs = false
    end

    def coordinates
      logger = Vanilla::Logger.instance
      logger.warn("DEPRECATED: #{self.class}##{__method__} is deprecated. Please use Vanilla::Components::PositionComponent#coordinates instead.")

      [row, column]
    end
  end
end
