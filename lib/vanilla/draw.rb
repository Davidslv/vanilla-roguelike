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
      self.tile(grid: grid, row: unit.row, column: unit.column, tile: unit.tile)
    end

    def self.stairs(grid:, row:, column:)
      self.tile(grid: grid, row: row, column: column, tile: Vanilla::Support::TileType::STAIRS)
    end

    def self.movement(grid:, unit:, direction:)
      # Save old position before movement
      old_row, old_column = unit.row, unit.column

      # Perform movement
      Vanilla::Movement.move(grid: grid, unit: unit, direction: direction)

      # If player moved, clear the old position
      if old_row != unit.row || old_column != unit.column
        old_cell = grid[old_row, old_column]
        old_cell.tile = Support::TileType::EMPTY if old_cell
      end

      # Update player position on the grid after movement
      self.player(grid: grid, unit: unit)
      self.map(grid)
    end
  end
end
