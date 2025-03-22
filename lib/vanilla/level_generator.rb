module Vanilla
  # Generates game levels with appropriate difficulty scaling
  class LevelGenerator
    # Generate a new level with appropriate difficulty
    # @param difficulty [Integer] The difficulty level (higher = harder)
    # @return [Level] The generated level
    def generate(difficulty)
      # Create level with appropriate size for difficulty
      level = Level.random(difficulty: difficulty)

      # The World is responsible for adding entities to the level
      # but we need to ensure the level has proper entrance/exit coordinates
      # and is fully initialized before it's returned

      # Validate level before returning
      unless level && level.grid
        raise "Failed to create a valid level with grid"
      end

      # Log level creation
      Vanilla::Logger.instance.info("Level generated: #{level.grid.rows}x#{level.grid.columns}, entrance: [#{level.entrance_row}, #{level.entrance_column}], exit: [#{level.exit_row}, #{level.exit_column}]")

      level
    end

    # Create a level with a specific size and layout
    # @param rows [Integer] Number of rows
    # @param columns [Integer] Number of columns
    # @param difficulty [Integer] The difficulty level
    # @param seed [Integer, nil] Random seed for generation
    # @return [Level] The generated level
    def create_with_size(rows, columns, difficulty, seed = nil)
      Level.new(rows: rows, columns: columns, difficulty: difficulty, seed: seed)
    end
  end
end