# frozen_string_literal: true

module Vanilla
  module Systems
    class MonsterSystem < System
      MAX_MONSTERS = {
        1 => 2,
        2 => 4,
        3 => 6,
        4 => 8
      }.freeze
      attr_reader :monsters

      def initialize(world, player:, logger: nil)
        super(world)
        @player = player
        @monsters = []
        @logger = logger || Vanilla::Logger.instance
        @rng = Random.new
        @world.subscribe(:combat_damage, self) # Prepare for future combat events
      end

      # Spawn monsters based on the current level difficulty
      # @param level [Integer] The current difficulty level
      # @param grid [Vanilla::MapUtils::Grid] The grid to spawn monsters in
      def spawn_monsters(level, grid)
        @monsters.clear
        count = determine_monster_count(level)
        @logger.info("Spawning #{count} monsters at level #{level}")
        count.times { spawn_monster(level, grid) }
      end

      # Update monster states, removing dead ones
      # @param _delta_time [Float, nil] Unused, kept for system interface compatibility
      def update(_delta_time = nil)
        @monsters.reject! do |monster|
          health = monster.get_component(:health)
          dead = health.current_health <= 0
          if dead
            @world.remove_entity(monster.id)
            @world.current_level&.remove_entity(monster) # Safe check if level exists
            emit_event(:monster_despawned, { monster_id: monster.id })
            @logger.debug("Monster #{monster.id} despawned due to health reaching 0")
          end
          dead
        end
      end

      # Find a monster at a specific position
      # @param row [Integer] The row to check
      # @param column [Integer] The column to check
      # @return [Entity, nil] The monster at the position or nil if none
      def monster_at(row, column)
        @monsters.find do |monster|
          position = monster.get_component(:position)
          position.row == row && position.column == column
        end
      end

      # Check if the player has collided with a monster
      # @return [Boolean] True if a monster is at the player’s position
      def player_collision?
        player_pos = @player.get_component(:position)
        monster_at(player_pos.row, player_pos.column) != nil
      end

      # Handle events, e.g., combat damage
      # @param event_type [Symbol] The type of event
      # @param data [Hash] The event data
      def handle_event(event_type, data)
        case event_type
        when :combat_damage
          monster = @world.get_entity(data[:target_id])
          if monster&.has_tag?(:monster)
            health = monster.get_component(:health)
            new_health = [health.current_health - data[:damage], 0].max
            health.current_health = new_health
            @logger.debug("Monster #{data[:target_id]} took #{data[:damage]} damage, health now #{new_health}")
          end
        end
      end

      private

      # Determine how many monsters to spawn based on level
      # @param level [Integer] The current difficulty level
      # @return [Integer] The number of monsters to spawn
      def determine_monster_count(level)
        max = MAX_MONSTERS[level] || MAX_MONSTERS.values.last
        @rng.rand((max / 2.0).ceil..max)
      end

      # Spawn a single monster at a valid location
      # @param level [Integer] The current difficulty level
      # @param grid [Vanilla::MapUtils::Grid] The grid to spawn the monster in
      # @return [Entity, nil] The spawned monster or nil if no valid location
      def spawn_monster(level, grid)
        cell = find_spawn_location(grid)
        return nil unless cell

        health = 10 + (level * 2)
        damage = 1 + (level / 2)

        monster_types = {
          'goblin' => 0.4,
          'orc' => 0.3,
          'troll' => 0.2,
          'ogre' => 0.1
        }
        monster_type = select_weighted_monster_type(monster_types)

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

        monster = Vanilla::EntityFactory.create_monster(monster_type, cell.row, cell.column, health, damage)
        cell.tile = Vanilla::Support::TileType::MONSTER
        @monsters << monster
        @world.add_entity(monster) # Add to World entities, Level sync happens later
        @logger.info("Spawned #{monster_type} at [#{cell.row}, #{cell.column}] with #{health} HP and #{damage} damage")

        # Emit event for Goal 2 integration
        emit_event(:monster_spawned, { monster_id: monster.id, position: { row: cell.row, column: cell.column } })

        monster
      end

      # Find a valid spawn location for a monster
      # @param grid [Vanilla::MapUtils::Grid] The grid to search for a spawn location
      # @return [Cell, nil] A suitable cell or nil if none available
      def find_spawn_location(grid)
        walkable_cells = []
        grid.each_cell do |cell|
          next unless cell.tile == Vanilla::Support::TileType::EMPTY

          player_pos = @player.get_component(:position)
          distance = (cell.row - player_pos.row).abs + (cell.column - player_pos.column).abs
          next if distance < 5 # Ensure distance from player

          has_nearby_monster = @monsters.any? do |m|
            m_pos = m.get_component(:position)
            nearby_distance = (cell.row - m_pos.row).abs + (cell.column - m_pos.column).abs
            nearby_distance < 3
          end
          next if has_nearby_monster # Avoid clustering

          walkable_cells << cell
        end
        walkable_cells.empty? ? nil : walkable_cells.sample(random: @rng)
      end

      # Select a monster type based on weighted probabilities
      # @param types [Hash] Monster types with probabilities
      # @return [String] The selected monster type
      def select_weighted_monster_type(types)
        total = types.values.sum
        roll = @rng.rand(total)
        running_total = 0
        types.each do |type, probability|
          running_total += probability
          return type if roll <= running_total
        end
        types.keys.first # Fallback
      end
    end
  end
end
