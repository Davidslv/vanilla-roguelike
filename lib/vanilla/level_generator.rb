module Vanilla
  class LevelGenerator
    def generate(difficulty, seed = Random.new_seed, algorithm = nil)
      $seed = seed
      srand($seed)
      level = Level.new(rows: 10, columns: 10, difficulty: difficulty)
      @algorithm = algorithm || Vanilla::Algorithms::AVAILABLE.sample(random: Random.new($seed))
      level.generate(@algorithm)

      player_cell = level.grid[0, 0]
      stairs_cell = level.grid.random_cell
      ensure_path(level.grid, player_cell, stairs_cell)

      player_cell.tile = Vanilla::Support::TileType::PLAYER
      stairs_cell.tile = Vanilla::Support::TileType::STAIRS
      level.place_stairs(stairs_cell.row, stairs_cell.column)

      level
    end

    private

    def ensure_path(grid, start_cell, goal_cell)
      current = start_cell
      until current == goal_cell
        next_cell = [current.north, current.south, current.east, current.west].compact.min_by do |cell|
          (cell.row - goal_cell.row).abs + (cell.column - goal_cell.column).abs
        end
        if next_cell
          current.link(cell: next_cell, bidirectional: true)
          next_cell.tile = Vanilla::Support::TileType::EMPTY unless next_cell == goal_cell
          current = next_cell
        else
          break # Fallback if no valid next cell
        end
      end
    end
  end
end
