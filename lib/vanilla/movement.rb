module Vanilla
  module Movement
    def self.move(grid:, unit:, direction:)
      logger = Vanilla::Logger.instance
      logger.debug("Processing movement in direction: #{direction}")

      # If the unit is an entity with required components, use the Movement System
      if unit.respond_to?(:has_component?) &&
         unit.has_component?(:position) &&
         unit.has_component?(:movement)

        logger.debug("Using ECS MovementSystem for movement")
        movement_system = Vanilla::Systems::MovementSystem.new(grid)
        movement_system.move(unit, direction)
      else
        # For backward compatibility with non-entity units
        logger.debug("Using legacy movement system")
        legacy_move(grid: grid, unit: unit, direction: direction)
      end
    end

    # Legacy movement implementation for backward compatibility
    def self.legacy_move(grid:, unit:, direction:)
      logger = Vanilla::Logger.instance
      cell = grid[*unit.coordinates]

      case direction
      when :left
        self.move_left(cell, unit)
      when :right
        self.move_right(cell, unit)
      when :up
        self.move_up(cell, unit)
      when :down
        self.move_down(cell, unit)
      end
    end

    def self.move_left(cell, unit)
      logger = Vanilla::Logger.instance

      unless cell.linked?(cell.west)
        logger.info("Movement blocked: Cannot move left from [#{unit.row}, #{unit.column}]")
        return
      end

      old_position = [unit.row, unit.column]
      unit.found_stairs = cell.west.stairs?

      if unit.found_stairs
        logger.info("Player found stairs at [#{cell.west.row}, #{cell.west.column}]")
      end

      cell.tile = Support::TileType::EMPTY
      cell.west.tile = unit.tile
      unit.row, unit.column = cell.west.row, cell.west.column

      logger.info("Player moved left from #{old_position} to [#{unit.row}, #{unit.column}]")
    end

    def self.move_right(cell, unit)
      logger = Vanilla::Logger.instance

      unless cell.linked?(cell.east)
        logger.info("Movement blocked: Cannot move right from [#{unit.row}, #{unit.column}]")
        return
      end

      old_position = [unit.row, unit.column]
      unit.found_stairs = cell.east.stairs?

      if unit.found_stairs
        logger.info("Player found stairs at [#{cell.east.row}, #{cell.east.column}]")
      end

      cell.tile = Support::TileType::EMPTY
      cell.east.tile = unit.tile
      unit.row, unit.column = cell.east.row, cell.east.column

      logger.info("Player moved right from #{old_position} to [#{unit.row}, #{unit.column}]")
    end

    def self.move_up(cell, unit)
      logger = Vanilla::Logger.instance

      unless cell.linked?(cell.north)
        logger.info("Movement blocked: Cannot move up from [#{unit.row}, #{unit.column}]")
        return
      end

      old_position = [unit.row, unit.column]
      unit.found_stairs = cell.north.stairs?

      if unit.found_stairs
        logger.info("Player found stairs at [#{cell.north.row}, #{cell.north.column}]")
      end

      cell.tile = Support::TileType::EMPTY
      cell.north.tile = unit.tile
      unit.row, unit.column = cell.north.row, cell.north.column

      logger.info("Player moved up from #{old_position} to [#{unit.row}, #{unit.column}]")
    end

    def self.move_down(cell, unit)
      logger = Vanilla::Logger.instance

      unless cell.linked?(cell.south)
        logger.info("Movement blocked: Cannot move down from [#{unit.row}, #{unit.column}]")
        return
      end

      old_position = [unit.row, unit.column]
      unit.found_stairs = cell.south.stairs?

      if unit.found_stairs
        logger.info("Player found stairs at [#{cell.south.row}, #{cell.south.column}]")
      end

      cell.tile = Support::TileType::EMPTY
      cell.south.tile = unit.tile
      unit.row, unit.column = cell.south.row, cell.south.column

      logger.info("Player moved down from #{old_position} to [#{unit.row}, #{unit.column}]")
    end
  end
end
