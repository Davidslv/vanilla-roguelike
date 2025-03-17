module Vanilla
  class Level
    attr_reader :grid, :player

    def initialize(seed: nil, rows: 10, columns: 10)
      @grid = Vanilla::Map.create(rows: rows, columns: columns, algorithm: Vanilla::Algorithms::AVAILABLE.sample, seed: seed)

      start = start_position(grid: grid)
      positions = longest_path(grid: grid, start: start)

      player_position, stairs_position = positions[:start], positions[:goal]

      player_row = player_position[0]
      player_column = player_position[1]
      stairs_row = stairs_position[0]
      stairs_column = stairs_position[1]

      @player = Characters::Player.new(row: player_row, column: player_column)

      Vanilla::Draw.player(grid: grid, unit: player)
      Vanilla::Draw.stairs(grid: grid, row: stairs_row, column: stairs_column)
    end

    def self.random
      rows = rand(8..20)
      columns = rand(8..20)

      new(rows: rows, columns: columns)
    end

    private

    def start_position(grid:)
      grid[rand(0..((grid.rows - 1) / 2)), rand(0..((grid.columns - 1) / 2))]
    end

    def longest_path(grid:, start:)
      distances = start.distances
      new_start, distance = distances.max

      new_distances = new_start.distances
      goal, distances = new_distances.max

      {
        start: [new_start.row, new_start.column],
        goal: [goal.row, goal.column]
      }
    end
  end
end