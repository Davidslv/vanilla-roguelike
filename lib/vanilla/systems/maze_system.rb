module Vanilla
  module Systems
    class MazeSystem < System
      attr_accessor :difficulty

      def initialize(world, difficulty:, seed: Random.new_seed)
        super(world)

        @logger = Logger.instance
        @difficulty = difficulty
        @seed = seed
        srand(@seed) # Set random seed for reproducibility

        @logger.debug("[MazeSystem] Initializing with difficulty: #{@difficulty}, seed: #{@seed}")

        # TODO: Make this configurable
        @algorithm = Vanilla::Algorithms::RecursiveBacktracker # Default algorithm
        @type_factory = Vanilla::MapUtils::CellTypeFactory.new

        @world.subscribe(:level_transition_requested, self)
      end

      def update(_delta_time)
        return unless !@world.grid || @world.level_changed? # Always regenerate if level_changed

        @logger.debug("[MazeSystem] Updating - generating maze")
        grid = generate_maze
        populate_entities(grid)
        @world.set_level(Vanilla::Level.new(grid: grid, difficulty: @difficulty, algorithm: @algorithm))
        @logger.debug("[MazeSystem] Maze generated and entities populated")
      end

      def handle_event(event_type, data)
        return unless event_type == :level_transition_requested

        @logger.info("[MazeSystem] Level transition requested for player #{data[:player_id]}")
        @world.level_changed = true # Trigger regeneration on next update
        player = @world.get_entity(data[:player_id])
        player.get_component(:position).set_position(0, 0) if player # Reset player position
      end

      def generate_maze
        grid = Vanilla::MapUtils::Grid.new(
          10,
          10,
          type_factory: @type_factory
        )

        @logger.debug("[MazeSystem] Generating maze")
        @algorithm.on(grid)

        grid
      end

      def populate_entities(grid)
        @logger.debug("[MazeSystem] Populating entities")
        @world.entities.clear
        player = Vanilla::EntityFactory.create_player(0, 0)
        @world.add_entity(player)
        player_cell = grid[0, 0]
        player_cell.tile = player.get_component(:render).character
        @logger.debug("[MazeSystem] Player tile set: #{player_cell.tile}")

        stairs_position = find_stairs_position(grid, player_cell)
        stairs = Vanilla::EntityFactory.create_stairs(stairs_position[:row], stairs_position[:column])
        @world.add_entity(stairs)
        stairs_cell = grid[stairs_position[:row], stairs_position[:column]]
        stairs_cell.tile = stairs.get_component(:render).character
        @logger.debug("[MazeSystem] Stairs tile set: #{stairs_cell.tile}")

        ensure_path(grid, player_cell, stairs_cell)

        # Delegate monster spawning to MonsterSystem
        monster_system = @world.systems.find { |s, _| s.is_a?(Vanilla::Systems::MonsterSystem) }&.first
        monster_system&.spawn_monsters(@difficulty, grid)

        # Sync Level entities with World entities
        level = Vanilla::Level.new(grid: grid, difficulty: @difficulty, algorithm: @algorithm)
        @world.entities.values.each { |e| level.add_entity(e) }
        @world.set_level(level)
      end

      private

      def find_stairs_position(grid, player_cell)
        distances = player_cell.distances
        farthest_cell = distances.max&.first || grid.random_cell
        @logger.debug("[MazeSystem] Farthest cell from player: [#{farthest_cell.row}, #{farthest_cell.column}]")

        # Avoid placing stairs at player's position
        if farthest_cell == player_cell
          max_attempts = grid.rows * grid.columns
          attempts = 0
          stairs_cell = grid.random_cell

          while stairs_cell == player_cell && attempts < max_attempts
            stairs_cell = grid.random_cell
            attempts += 1
          end

          stairs_cell = grid[1, 0] if stairs_cell == player_cell # Fallback
          @logger.debug("[MazeSystem] Stairs reselected to [#{stairs_cell.row}, #{stairs_cell.column}]")
          return { row: stairs_cell.row, column: stairs_cell.column }
        end

        { row: farthest_cell.row, column: farthest_cell.column }
      end

      def ensure_path(grid, start_cell, goal_cell)
        @logger.debug("[MazeSystem] Ensuring path from [#{start_cell.row}, #{start_cell.column}] to [#{goal_cell.row}, #{goal_cell.column}]")
        current = start_cell
        until current == goal_cell
          next_cell = [current.north, current.south, current.east, current.west].compact.min_by do |cell|
            (cell.row - goal_cell.row).abs + (cell.column - goal_cell.column).abs
          end

          if next_cell
            current.link(cell: next_cell, bidirectional: true)
            next_cell.tile = Vanilla::Support::TileType::EMPTY unless next_cell == goal_cell
            @logger.debug("[MazeSystem] Linked to [#{next_cell.row}, #{next_cell.column}]")
            current = next_cell
          else
            @logger.warn("[MazeSystem] No valid next cell; using random fallback")
            goal_cell = grid.random_cell while goal_cell == start_cell
            current = start_cell # Restart pathing
          end
        end
      end
    end
  end
end
