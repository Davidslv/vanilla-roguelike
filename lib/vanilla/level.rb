module Vanilla
  class Level
    attr_reader :grid, :player

    def initialize(seed: nil, rows: 10, columns: 10)
      logger = Vanilla::Logger.instance

      logger.info("Creating new level with rows: #{rows}, columns: #{columns}, seed: #{seed || 'random'}")
      @grid = Vanilla::Map.create(rows: rows, columns: columns, algorithm: Vanilla::Algorithms::AVAILABLE.sample, seed: seed)
      logger.debug("Grid created with algorithm: #{@grid.algorithm.name}")

      start = start_position(grid: grid)
      logger.debug("Start position selected: [#{start.row}, #{start.column}]")

      positions = longest_path(grid: grid, start: start)
      logger.debug("Path positions calculated - Start: #{positions[:start].inspect}, Goal: #{positions[:goal].inspect}")

      player_position, stairs_position = positions[:start], positions[:goal]

      player_row = player_position[0]
      player_column = player_position[1]
      stairs_row = stairs_position[0]
      stairs_column = stairs_position[1]

      @player = Entities::Player.new(row: player_row, column: player_column)
      logger.info("Player created at position [#{player_row}, #{player_column}]")

      Vanilla::Draw.player(grid: grid, unit: @player)
      Vanilla::Draw.stairs(grid: grid, row: stairs_row, column: stairs_column)
      logger.info("Stairs placed at position [#{stairs_row}, #{stairs_column}]")
    end

    def self.random
      logger = Vanilla::Logger.instance

      rows = rand(8..20)
      columns = rand(8..20)

      logger.info("Generating random level with rows: #{rows}, columns: #{columns}")
      new(rows: rows, columns: columns)
    end

    private

    def start_position(grid:)
      grid[rand(0..((grid.rows - 1) / 2)), rand(0..((grid.columns - 1) / 2))]
    end

    def longest_path(grid:, start:)
      distances = start.distances
      new_start, distance = distances.max
      logger = Vanilla::Logger.instance
      logger.debug("Longest path first pass - new start: [#{new_start.row}, #{new_start.column}], distance: #{distance}")

      new_distances = new_start.distances
      goal, distances = new_distances.max
      logger.debug("Longest path second pass - goal: [#{goal.row}, #{goal.column}], distance: #{distances}")

      {
        start: [new_start.row, new_start.column],
        goal: [goal.row, goal.column]
      }
    end
  end
end