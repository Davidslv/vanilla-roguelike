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
        # Currently disabled: monster movement
        # Just remove dead monsters for now
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
          # Only use truly empty cells (not player, stairs, or other monsters)
          next unless cell.tile == Support::TileType::EMPTY

          # Skip cells that are too close to the player
          player_pos = @player.get_component(:position)
          distance = (cell.row - player_pos.row).abs + (cell.column - player_pos.column).abs
          next if distance < 5 # Minimum distance from player

          # Skip cells that have another monster nearby (to spread them out)
          has_nearby_monster = @monsters.any? do |m|
            m_pos = m.get_component(:position)
            nearby_distance = (cell.row - m_pos.row).abs + (cell.column - m_pos.column).abs
            nearby_distance < 3 # Keep monsters at least 3 cells apart
          end
          next if has_nearby_monster

          walkable_cells << cell
        end

        # If we couldn't find ideal cells, just find any empty cell
        if walkable_cells.empty?
          @grid.each_cell do |cell|
            next unless cell.tile == Support::TileType::EMPTY
            walkable_cells << cell
          end
        end

        return nil if walkable_cells.empty?

        # Randomly select a cell
        selected_cell = walkable_cells.sample(random: @rng)
        @logger.debug("Selected spawn location at [#{selected_cell.row}, #{selected_cell.column}]")
        selected_cell
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

      # Check if a move to the given position is valid
      # @param row [Integer] the row to check
      # @param column [Integer] the column to check
      # @return [Boolean] true if the move is valid
      def valid_move?(row, column)
        # Check if the cell exists and is walkable (not a wall or other obstacle)
        cell = @grid[row, column]
        return false unless cell
        return false unless Support::TileType.walkable?(cell.tile)

        # Check if there's already a monster there
        @monsters.none? do |other|
          other_pos = other.get_component(:position)
          other_pos.row == row && other_pos.column == column
        end
      end
    end
  end
end