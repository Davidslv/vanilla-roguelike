module Vanilla
  class Map
    def initialize(rows: 10, columns: 10, algorithm:, seed: nil)
      @logger = Vanilla::Logger.instance

      $seed = seed || rand(999_999_999_999_999)
      @logger.info("Map initialized with seed: #{$seed}")
      srand($seed)

      @rows, @columns, @algorithm = rows, columns, algorithm
      @logger.debug("Map parameters set: rows=#{rows}, columns=#{columns}, algorithm=#{algorithm}")
    end

    def self.create(rows:, columns:, algorithm: Vanilla::Algorithms::BinaryTree, seed:)
      Vanilla::Logger.instance.info("Creating map with algorithm: #{algorithm}")
      new(rows: rows, columns: columns, algorithm: algorithm, seed: seed).create
    end

    def create
      @logger.debug("Creating grid with rows=#{@rows}, columns=#{@columns}")
      grid = Vanilla::MapUtils::Grid.new(rows: @rows, columns: @columns)

      @logger.debug("Applying algorithm: #{@algorithm}")
      @algorithm.on(grid)

      dead_ends_count = grid.dead_ends.count
      @logger.debug("Map created with #{dead_ends_count} dead ends")

      # Store the algorithm used to create this grid
      grid.instance_variable_set(:@algorithm, @algorithm)

      # Add a method to access the algorithm
      grid.define_singleton_method(:algorithm) { @algorithm }

      grid
    end
  end
end
