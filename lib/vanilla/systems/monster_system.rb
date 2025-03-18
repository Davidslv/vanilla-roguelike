require_relative '../entities'

module Vanilla
  module Systems
    # MonsterSystem handles monster spawning, management, and behavior in the game.
    # It's responsible for:
    # - Spawning monsters at suitable locations
    # - Managing monster movement and AI
    # - Handling monster-player interactions
    class MonsterSystem
      # The maximum number of monsters allowed based on level difficulty
      MAX_MONSTERS = {
        1 => 2,  # Level 1: max 2 monsters
        2 => 4,  # Level 2: max 4 monsters
        3 => 6,  # Level 3: max 6 monsters
        4 => 8   # Level 4+: max 8 monsters
      }.freeze

      # Initialize the monster system
      # @param grid [Vanilla::MapUtils::Grid] the current game grid
      # @param player [Vanilla::Entities::Player] the player entity
      # @param logger [Logger] the game logger
      def initialize(grid:, player:, logger: nil)
        @grid = grid
        @player = player
        @monsters = []
        @logger = logger || Vanilla::Logger.instance
        @rng = Random.new
      end

      # Get all active monsters
      # @return [Array<Vanilla::Entities::Monster>] array of monster entities
      attr_reader :monsters

      # Populate the level with monsters based on difficulty
      # @param level [Integer] the current game level
      def spawn_monsters(level)
        # Clear any existing monsters
        @monsters.clear

        # Determine how many monsters to spawn
        count = determine_monster_count(level)

        @logger.info("Spawning #{count} monsters at level #{level}")

        count.times do
          spawn_monster(level)
        end
      end

      # Update all monsters
      # This should be called once per game turn
      def update
        @monsters.each do |monster|
          # Skip dead monsters
          next unless monster.alive?

          # Basic AI: Move randomly or towards player if nearby
          move_monster(monster)
        end

        # Remove dead monsters
        @monsters.reject! { |m| !m.alive? }
      end

      # Check if a monster is at the given position
      # @param row [Integer] the row to check
      # @param column [Integer] the column to check
      # @return [Vanilla::Entities::Monster, nil] the monster at the position, or nil
      def monster_at(row, column)
        @monsters.find do |monster|
          position = monster.get_component(:position)
          position.row == row && position.column == column
        end
      end

      private

      # Determine how many monsters to spawn based on level
      # @param level [Integer] the current game level
      # @return [Integer] the number of monsters to spawn
      def determine_monster_count(level)
        max = MAX_MONSTERS[level] || MAX_MONSTERS.values.last
        # Randomly choose between half max and max
        @rng.rand((max / 2.0).ceil..max)
      end

      # Create and spawn a single monster at a valid location
      # @param level [Integer] the current game level for scaling
      # @return [Vanilla::Entities::Monster] the spawned monster
      def spawn_monster(level)
        # Find a suitable empty cell
        cell = find_spawn_location
        return nil unless cell

        # Scale monster stats based on level
        health = 10 + (level * 2) # Level 1: 12 HP, Level 5: 20 HP
        damage = 1 + (level / 2)  # Level 1: 1 damage, Level 5: 3 damage

        # Create monster types with probabilities
        monster_types = {
          'goblin' => 0.4,
          'orc' => 0.3,
          'troll' => 0.2,
          'ogre' => 0.1
        }

        # Select monster type based on weighted probability
        monster_type = select_weighted_monster_type(monster_types)

        # Adjust stats based on monster type
        case monster_type
        when 'orc'
          health += 5
          damage += 1
        when 'troll'
          health += 10
          damage += 2
        when 'ogre'
          health += 15
          damage += 3
        end

        # Create the monster
        monster = Entities::Monster.new(
          monster_type: monster_type,
          row: cell.row,
          column: cell.column,
          health: health,
          damage: damage
        )

        # Set the cell's tile to monster
        cell.tile = Support::TileType::MONSTER

        @monsters << monster
        @logger.info("Spawned #{monster_type} at [#{cell.row}, #{cell.column}] with #{health} HP and #{damage} damage")

        monster
      end

      # Find a suitable location to spawn a monster
      # @return [Vanilla::MapUtils::Cell] a suitable empty cell
      def find_spawn_location
        # Get all walkable cells
        walkable_cells = []

        @grid.each_cell do |cell|
          # Skip cells that already have entities
          next if cell.tile != Support::TileType::EMPTY

          # Skip cells that are too close to the player
          player_pos = @player.get_component(:position)
          distance = (cell.row - player_pos.row).abs + (cell.column - player_pos.column).abs
          next if distance < 5 # Minimum distance from player

          walkable_cells << cell
        end

        return nil if walkable_cells.empty?

        # Randomly select a cell
        walkable_cells.sample(random: @rng)
      end

      # Select a monster type based on weighted probability
      # @param types [Hash] hash of monster types with probabilities
      # @return [String] the selected monster type
      def select_weighted_monster_type(types)
        total = types.values.sum
        roll = @rng.rand(total)

        running_total = 0
        types.each do |type, probability|
          running_total += probability
          return type if roll <= running_total
        end

        # Fallback
        types.keys.first
      end

      # Basic AI for monster movement
      # @param monster [Vanilla::Entities::Monster] the monster to move
      def move_monster(monster)
        # Get current position
        position = monster.get_component(:position)
        old_row, old_col = position.row, position.column

        # Get player position
        player_position = @player.get_component(:position)

        # Calculate distance to player
        distance = (position.row - player_position.row).abs + (position.column - player_position.column).abs

        # Track if the monster moved successfully
        moved = false

        # If player is nearby (within 5 cells), move towards them
        if distance <= 5
          # Simple pathfinding - move in the direction of the player
          row_diff = player_position.row - position.row
          col_diff = player_position.column - position.column

          # Determine primary direction to move
          if row_diff.abs > col_diff.abs
            # Move vertically
            new_row = position.row + (row_diff > 0 ? 1 : -1)
            new_col = position.column
          else
            # Move horizontally
            new_row = position.row
            new_col = position.column + (col_diff > 0 ? 1 : -1)
          end

          # Check if move is valid (cell exists and is walkable)
          if valid_move?(new_row, new_col)
            # Get the cell at the monster's current position
            old_cell = @grid[position.row, position.column]

            # Update monster position
            position.row = new_row
            position.column = new_col

            # Update cells
            old_cell.tile = Support::TileType::EMPTY
            @grid[new_row, new_col].tile = Support::TileType::MONSTER
            moved = true
          end
        else
          # Random movement if player is not nearby
          if @rng.rand(3) == 0 # 1/3 chance to move
            directions = [
              [0, 1],  # Right
              [1, 0],  # Down
              [0, -1], # Left
              [-1, 0]  # Up
            ]

            # Try directions in random order
            directions.shuffle(random: @rng).each do |dr, dc|
              new_row = position.row + dr
              new_col = position.column + dc

              if valid_move?(new_row, new_col)
                # Get the cell at the monster's current position
                old_cell = @grid[position.row, position.column]

                # Update monster position
                position.row = new_row
                position.column = new_col

                # Update cells
                old_cell.tile = Support::TileType::EMPTY
                @grid[new_row, new_col].tile = Support::TileType::MONSTER
                moved = true
                break
              end
            end
          end
        end

        # If monster didn't move, make sure it's still visible on the grid
        unless moved
          # Ensure the monster's current position still shows the monster tile
          current_cell = @grid[position.row, position.column]
          if current_cell && current_cell.tile != Support::TileType::MONSTER
            current_cell.tile = Support::TileType::MONSTER
          end
        end
      end

      # Check if a move to the given position is valid
      # @param row [Integer] the row to check
      # @param column [Integer] the column to check
      # @return [Boolean] true if the move is valid
      def valid_move?(row, column)
        # Check if the cell exists and is empty
        cell = @grid[row, column]
        return false unless cell
        return false unless cell.tile == Support::TileType::EMPTY

        # Check if there's already a monster there
        @monsters.none? do |other|
          other_pos = other.get_component(:position)
          other_pos.row == row && other_pos.column == column
        end
      end
    end
  end
end