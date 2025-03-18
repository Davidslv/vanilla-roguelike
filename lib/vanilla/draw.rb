module Vanilla
  module Draw
    def self.map(grid, open_maze: true)
      system("clear")

      # Print header
      header = "Seed: #{$seed} | Rows: #{grid.rows} | Columns: #{grid.columns}"
      puts header
      puts "-" * 35
      puts "\n\n"

      # Print grid
      terminal_output = Vanilla::Output::Terminal.new(grid, open_maze: open_maze)
      puts terminal_output
    end

    def self.tile(grid:, row:, column:, tile:)
      raise ArgumentError, 'Invalid tile type' unless Support::TileType::VALUES.include?(tile)

      cell = grid[row, column]
      cell.tile = tile

      self.map(grid)
    end

    def self.player(grid:, unit:)
      # Handle both Entity and legacy Unit objects
      if unit.respond_to?(:has_component?) && unit.has_component?(:position) && unit.has_component?(:tile)
        # Preferred approach: Entity with components
        position = unit.get_component(:position)
        tile_component = unit.get_component(:tile)
        self.tile(grid: grid, row: position.row, column: position.column, tile: tile_component.tile)
      else
        # Legacy approach: Unit object
        logger = Vanilla::Logger.instance
        logger.warn("DEPRECATED: Using legacy Unit object in Draw.player. Please use Entity with components.")
        self.tile(grid: grid, row: unit.row, column: unit.column, tile: unit.tile)
      end
    end

    def self.stairs(grid:, row:, column:)
      self.tile(grid: grid, row: row, column: column, tile: Vanilla::Support::TileType::STAIRS)
    end

    def self.movement(grid:, unit:, direction:)
      # Use the MovementSystem for all objects
      movement_system = Vanilla::Systems::MovementSystem.new(grid)

      # Determine if this is an Entity or legacy Unit
      if unit.respond_to?(:has_component?) && unit.has_component?(:position)
        # Entity approach - get position before movement
        position = unit.get_component(:position)
        old_row, old_column = position.row, position.column

        # Move the entity
        success = movement_system.move(unit, direction)

        # Get updated position
        new_row, new_column = position.row, position.column
      else
        # Legacy Unit approach
        logger = Vanilla::Logger.instance
        logger.warn("DEPRECATED: Using legacy Unit object in Draw.movement. Please use Entity with components.")

        # Get position before movement
        old_row, old_column = unit.row, unit.column

        # Move the unit
        success = movement_system.move(unit, direction)

        # Get updated position
        new_row, new_column = unit.row, unit.column
      end

      # If player moved, clear the old position
      if old_row != new_row || old_column != new_column
        old_cell = grid[old_row, old_column]
        old_cell.tile = Support::TileType::EMPTY if old_cell
      end

      # Update player position on the grid after movement
      self.player(grid: grid, unit: unit)
      self.map(grid)
    end
  end
end
