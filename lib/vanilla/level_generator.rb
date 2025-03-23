module Vanilla
  class LevelGenerator
    def generate(difficulty, seed = Random.new_seed)
      $seed = seed
      srand($seed)
      level = Level.new(rows: 10, columns: 10, difficulty: difficulty)
      algorithm = Vanilla::Algorithms::RecursiveBacktracker

      level.generate(algorithm)
      level.place_stairs
      level
    end
  end
end
