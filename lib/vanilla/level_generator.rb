module Vanilla
  # Generates game levels with appropriate difficulty scaling
  class LevelGenerator
    # Generate a new level with appropriate difficulty
    # @param difficulty [Integer] The difficulty level (higher = harder)
    # @return [Level] The generated level
    def generate(difficulty)
      # Create level with appropriate size for difficulty
      level = Level.random(difficulty: difficulty)

      # Populate level with entities based on difficulty
      # This is done by the World class which will use the EntityFactory

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