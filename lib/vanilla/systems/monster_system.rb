# frozen_string_literal: true

require_relative '../entities'

module Vanilla
  module Systems
    class MonsterSystem < System
      MAX_MONSTERS = {
        1 => 2,
        2 => 4,
        3 => 6,
        4 => 8
      }.freeze

      def initialize(world, player:, logger: nil)
        super(world)
        @player = player
        @monsters = []
        @logger = logger || Vanilla::Logger.instance
        @rng = Random.new
      end

      attr_reader :monsters

      def spawn_monsters(level)
        @monsters.clear
        count = determine_monster_count(level)
        @logger.info("Spawning #{count} monsters at level #{level}")
        count.times { spawn_monster(level) }
      end

      def update(delta_time = nil)
        @monsters.reject! { |m| !m.alive? }
      end

      def monster_at(row, column)
        @monsters.find do |monster|
          position = monster.get_component(:position)
          position.row == row && position.column == column
        end
      end

      def player_collision?
        player_pos = @player.get_component(:position)
        monster_at(player_pos.row, player_pos.column) != nil
      end

      private

      def determine_monster_count(level)
        max = MAX_MONSTERS[level] || MAX_MONSTERS.values.last
        @rng.rand((max / 2.0).ceil..max)
      end

      def spawn_monster(level)
        grid = @world.current_level.grid
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
        @world.current_level.add_entity(monster) # Sync with level entities
        @logger.info("Spawned #{monster_type} at [#{cell.row}, #{cell.column}] with #{health} HP and #{damage} damage")
        monster
      end

      def find_spawn_location(grid)
        walkable_cells = []
        grid.each_cell do |cell|
          next unless cell.tile == Vanilla::Support::TileType::EMPTY

          player_pos = @player.get_component(:position)
          distance = (cell.row - player_pos.row).abs + (cell.column - player_pos.column).abs
          next if distance < 5

          has_nearby_monster = @monsters.any? do |m|
            m_pos = m.get_component(:position)
            nearby_distance = (cell.row - m_pos.row).abs + (cell.column - m_pos.column).abs
            nearby_distance < 3
          end
          next if has_nearby_monster

          walkable_cells << cell
        end
        walkable_cells.empty? ? nil : walkable_cells.sample(random: @rng)
      end

      def select_weighted_monster_type(types)
        total = types.values.sum
        roll = @rng.rand(total)
        running_total = 0
        types.each do |type, probability|
          running_total += probability
          return type if roll <= running_total
        end
        types.keys.first
      end

      def valid_move?(row, column)
        grid = @world.current_level.grid
        cell = grid[row, column]
        return false unless cell
        return false unless Vanilla::Support::TileType.walkable?(cell.tile)

        @monsters.none? do |other|
          other_pos = other.get_component(:position)
          other_pos.row == row && other_pos.column == column
        end
      end
    end
  end
end
