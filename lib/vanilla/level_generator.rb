module Vanilla
  class LevelGenerator

    def initialize(logger:)
      @logger = logger
    end

    def generate(difficulty, seed = Random.new_seed, algorithm = nil)
      $seed = seed
      srand($seed)

      level = Level.new(rows: 10, columns: 10, difficulty: difficulty)
      algorithm ||= Vanilla::Algorithms::AVAILABLE.sample(random: Random.new($seed))

      @logger.info("Level Algorithm: #{algorithm}")

      level.generate(algorithm)
      level.place_stairs
      level
    end
  end
end
