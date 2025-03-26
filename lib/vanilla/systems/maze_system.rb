module Vanilla
  module Systems
    class MazeSystem < System
      def initialize(world)
        super(world, algorithm = Vanilla::Algorithms::RecursiveBacktracker.new)
        @logger = Logger.instance

        @logger.debug("[MazeSystem] Initializing")
        @algorithm = algorithm
        @logger.debug("[MazeSystem] Algorithm: #{@algorithm.class.name}")

        @type_factory = Vanilla::MapUtils::CellTypeFactory.new
      end

      def update(_delta_time)
        return if @world.grid

        grid = generate_maze
        populate_entities(grid)
        @logger.debug("[MazeSystem] Maze generated and entities populated")
      end

      def generate_maze
        grid = Vanilla::MapUtils::Grid.new(
          rows: @world.current_level.rows,
          columns: @world.current_level.columns,
          type_factory: @type_factory
        )

        @logger.debug("[MazeSystem] Generating maze")
        @algorithm.on(grid)

        grid
      end

      def populate_entities(grid)
        @logger.debug("[MazeSystem] Populating entities")

        @world.entities.clear # Remove all existing entities

        player = Vanilla::EntityFactory.create_player(0, 0)
        @world.add_entity(player)

        stairs_position = find_stairs_position(grid)
        stairs = Vanilla::EntityFactory.create_stairs(stairs_position[:row], stairs_position[:column])
        @world.add_entity(stairs)

        @world.set_level(grid)
      end

      private

      def find_stairs_position(grid)
        cell = grid.random_cell while cell.links.empty?

        { row: cell.row, column: cell.column }
      end
    end
  end
end
