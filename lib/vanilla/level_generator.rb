# lib/vanilla/level_generator.rb
module Vanilla
  class LevelGenerator
    def generate(difficulty, seed = Random.new_seed, algorithm = nil)
      $seed = seed
      srand($seed)
      @logger = Vanilla::Logger.instance
      @logger.debug("Starting level generation with difficulty: #{difficulty}, seed: #{$seed}")

      begin
        level = Level.new(rows: 10, columns: 10, difficulty: difficulty)
        @algorithm = algorithm || Vanilla::Algorithms::AVAILABLE.sample(random: Random.new($seed))
        @logger.debug("Selected algorithm: #{@algorithm.demodulize}")
        level.generate(@algorithm)

        player_cell = level.grid[0, 0]
        @logger.debug("Player cell set to: [#{player_cell.row}, #{player_cell.column}]")

        distances = player_cell.distances
        @logger.debug("Distances from player: #{distances.cells.count} reachable cells")
        new_start = distances.max&.first || level.grid.random_cell
        @logger.debug("New start cell: [#{new_start.row}, #{new_start.column}]")

        new_distances = new_start.distances
        @logger.debug("Distances from new start: #{new_distances.cells.count} reachable cells")
        stairs_cell = new_distances.max&.first || level.grid.random_cell
        @logger.debug("Stairs cell selected: [#{stairs_cell.row}, #{stairs_cell.column}]")

        # Avoid placing stairs at player’s start
        if stairs_cell == player_cell
          stairs_cell = level.grid.random_cell while stairs_cell == player_cell
          @logger.debug("Stairs cell reselected to avoid player: [#{stairs_cell.row}, #{stairs_cell.column}]")
        end

        ensure_path(level.grid, player_cell, stairs_cell)

        player_cell.tile = Vanilla::Support::TileType::PLAYER
        @logger.debug("Player tile set at: [#{player_cell.row}, #{player_cell.column}]")
        stairs_cell.tile = Vanilla::Support::TileType::STAIRS
        @logger.debug("Stairs tile set at: [#{stairs_cell.row}, #{stairs_cell.column}]")
        level.place_stairs(stairs_cell.row, stairs_cell.column)
        @logger.debug("Stairs placed at: [#{stairs_cell.row}, #{stairs_cell.column}]")

        level
      rescue StandardError => e
        @logger.error("Error generating level: #{e.message}\n#{e.backtrace.join("\n")}")
        raise
      end
    end

    private

    def ensure_path(grid, start_cell, goal_cell)
      @logger.debug("Ensuring path from [#{start_cell.row}, #{start_cell.column}] to [#{goal_cell.row}, #{goal_cell.column}]")
      current = start_cell
      until current == goal_cell
        next_cell = [current.north, current.south, current.east, current.west].compact.min_by do |cell|
          (cell.row - goal_cell.row).abs + (cell.column - goal_cell.column).abs
        end
        if next_cell
          current.link(cell: next_cell, bidirectional: true)
          next_cell.tile = Vanilla::Support::TileType::EMPTY unless next_cell == goal_cell
          @logger.debug("Linked to [#{next_cell.row}, #{next_cell.column}]")
          current = next_cell
        else
          @logger.warn("No valid next cell found; using random fallback")
          goal_cell = grid.random_cell while goal_cell == start_cell
          current = start_cell  # Restart pathing
        end
      end
    end
  end
end
