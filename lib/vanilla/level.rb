module Vanilla
  # Represents a game level
  class Level
    attr_reader :grid, :difficulty, :entrance_row, :entrance_column, :exit_row, :exit_column, :player, :stairs

    # Initialize a new level
    # @param seed [Integer, nil] Random seed for level generation
    # @param rows [Integer] Number of rows in the level
    # @param columns [Integer] Number of columns in the level
    # @param difficulty [Integer] The level difficulty
    def initialize(seed: nil, rows: 10, columns: 10, difficulty: 1)
      logger = Vanilla::Logger.instance

      @difficulty = difficulty
      @entrance_row = 0
      @entrance_column = 0
      @exit_row = 0
      @exit_column = 0

      logger.info("Creating new level with rows: #{rows}, columns: #{columns}, seed: #{seed || 'random'}, difficulty: #{difficulty}")
      @grid = Vanilla::Map.create(rows: rows, columns: columns, algorithm: Vanilla::Algorithms::AVAILABLE.sample, seed: seed)
      logger.debug("Grid created with algorithm: #{@grid.algorithm.name}")

      start = start_position(grid: grid)
      logger.debug("Start position selected: [#{start.row}, #{start.column}]")

      positions = longest_path(grid: grid, start: start)
      logger.debug("Path positions calculated - Start: #{positions[:start].inspect}, Goal: #{positions[:goal].inspect}")

      player_position, stairs_position = positions[:start], positions[:goal]

      # Store entrance/exit for entity creation
      @entrance_row = player_position[0]
      @entrance_column = player_position[1]
      @exit_row = stairs_position[0]
      @exit_column = stairs_position[1]

      # Create legacy player and stairs entities for backward compatibility
      player_row = player_position[0]
      player_column = player_position[1]
      stairs_row = stairs_position[0]
      stairs_column = stairs_position[1]

      @player = Entities::Player.new(row: player_row, column: player_column)
      logger.info("Player created at position [#{player_row}, #{player_column}]")

      @stairs = Entities::Stairs.new(row: stairs_row, column: stairs_column)
      logger.info("Stairs placed at position [#{stairs_row}, #{stairs_column}]")

      # We don't call update_grid_with_entities here anymore as it's now the responsibility
      # of the World class to do that with the actual entities it manages

      logger.info("Entrance set at position [#{@entrance_row}, #{@entrance_column}]")
      logger.info("Exit set at position [#{@exit_row}, #{@exit_column}]")
    end

    # Set the entrance position
    # @param row [Integer] The entrance row
    # @param column [Integer] The entrance column
    def set_entrance(row, column)
      @entrance_row = row
      @entrance_column = column
    end

    # Set the exit position
    # @param row [Integer] The exit row
    # @param column [Integer] The exit column
    def set_exit(row, column)
      @exit_row = row
      @exit_column = column
    end

    # Set the level grid
    # @param grid [Grid] The grid for this level
    def set_grid(grid)
      @grid = grid
    end

    def self.random(difficulty: 1)
      logger = Vanilla::Logger.instance

      # Scale level size based on difficulty
      base_size = 5
      size_scale = [difficulty * 0.7, 2.5].min  # Cap scaling at 2.5x

      min_size = [base_size, 4].max
      max_size = [(base_size + difficulty), 15].min

      rows = rand(min_size..max_size)
      columns = rand(min_size..max_size)

      logger.info("Generating random level with rows: #{rows}, columns: #{columns}, difficulty: #{difficulty}")
      new(rows: rows, columns: columns, difficulty: difficulty)
    end

    def all_entities
      entities = [@player, @stairs]

      # Add monsters if monster_system is available
      monster_system = Vanilla::ServiceRegistry.get(:game)&.monster_system
      if monster_system && monster_system.respond_to?(:monsters)
        entities += monster_system.monsters
      end

      entities
    end

    # Check if the player is at the stairs position
    # @return [Boolean] true if player is at stairs position
    def player_at_stairs?
      logger = Vanilla::Logger.instance

      unless @player && @stairs
        logger.debug("Player or stairs not available")
        return false
      end

      player_pos = @player.get_component(:position)
      stairs_pos = @stairs.get_component(:position)

      unless player_pos && stairs_pos
        logger.debug("Player or stairs position component not available")
        return false
      end

      logger.debug("Player at [#{player_pos.row}, #{player_pos.column}], Stairs at [#{stairs_pos.row}, #{stairs_pos.column}]")

      # Print the grid cells around player for debugging
      logger.debug("Grid cells around player:")
      (-1..1).each do |row_offset|
        (-1..1).each do |col_offset|
          check_row = player_pos.row + row_offset
          check_col = player_pos.column + col_offset

          if check_row >= 0 && check_row < @grid.rows && check_col >= 0 && check_col < @grid.columns
            cell = @grid[check_row, check_col]
            tile = cell ? cell.tile : "nil"
            stairs_here = (check_row == stairs_pos.row && check_col == stairs_pos.column) ? " (STAIRS)" : ""
            logger.debug("Cell [#{check_row}, #{check_col}]: #{tile}#{stairs_here}")
          end
        end
      end

      at_stairs = player_pos.row == stairs_pos.row && player_pos.column == stairs_pos.column

      if at_stairs
        logger.info("Player found stairs at [#{stairs_pos.row}, #{stairs_pos.column}]")
      end

      at_stairs
    end

    # Updates grid cells with entity information for backwards compatibility
    # with code that still uses the grid's tile properties directly
    # @param entities [Array<Entity>, nil] The entities to update the grid with (optional)
    def update_grid_with_entities(entities = nil)
      # If no entities provided, use legacy approach
      entities ||= all_entities

      # First, reset all grid cells to their default state
      # This prevents "ghost" entities remaining on the grid
      @grid.rows.times do |row|
        @grid.columns.times do |col|
          cell = @grid[row, col]
          # Only reset cells that can be walked on, not walls
          if cell && Vanilla::Support::TileType.walkable?(cell.tile)
            cell.tile = Vanilla::Support::TileType::EMPTY
          end
        end
      end

      # Update entities on grid
      entities.each do |entity|
        next unless entity.respond_to?(:has_component?) &&
                   entity.has_component?(:position) &&
                   entity.has_component?(:render)

        pos = entity.get_component(:position)
        render_component = entity.get_component(:render)

        # Skip if position is out of bounds
        next if pos.row < 0 || pos.row >= @grid.rows || pos.column < 0 || pos.column >= @grid.columns

        cell = @grid[pos.row, pos.column]
        next unless cell # Skip if no cell at this position

        # Handle special case for stairs
        if entity.respond_to?(:has_tag?) && entity.has_tag?(:stairs)
          cell.tile = render_component.respond_to?(:char) ? render_component.char : Vanilla::Support::TileType::STAIRS
        else
          char = if render_component.respond_to?(:char)
                   render_component.char
                 elsif render_component.respond_to?(:character)
                   render_component.character
                 else
                   '?'  # Fallback
                 end
          cell.tile = char
        end
      end
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