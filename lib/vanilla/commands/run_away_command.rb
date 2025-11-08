# frozen_string_literal: true

require_relative 'command'

module Vanilla
  module Commands
    class RunAwayCommand < Command
      FLEE_CHANCE_MIN = 0.01  # 1%
      FLEE_CHANCE_MAX = 0.30  # 30%

      attr_reader :player, :monster

      def initialize(player, monster)
        super()
        @player = player
        @monster = monster
        @logger = Vanilla::Logger.instance
        @logger.debug("[RunAwayCommand] Initializing run away command: player #{player&.id} from monster #{monster&.id}")
      end

      def execute(world)
        return if @executed

        unless @player && @monster
          @executed = true
          return
        end

        # Calculate flee chance
        flee_chance = calculate_flee_chance
        @logger.info("[RunAwayCommand] Flee chance: #{(flee_chance * 100).round(2)}%")

        # Attempt to flee
        if rand < flee_chance
          # Successful flee
          move_player_away(world)
          world.emit_event(:combat_flee_success, {
            player_id: @player.id,
            monster_id: @monster.id
          })
          @logger.info("[RunAwayCommand] Player successfully fled from monster")
        else
          # Failed flee - monster gets attack
          world.emit_event(:combat_flee_failed, {
            player_id: @player.id,
            monster_id: @monster.id
          })

          combat_system = world.systems.find { |s, _| s.is_a?(Vanilla::Systems::CombatSystem) }&.first
          if combat_system
            combat_system.process_attack(@monster, @player)
          end

          @logger.info("[RunAwayCommand] Player failed to flee, monster attacks")
        end

        @executed = true
      end

      private

      def calculate_flee_chance
        # Random between 1-30%
        min = FLEE_CHANCE_MIN
        max = FLEE_CHANCE_MAX
        min + (rand * (max - min))
      end

      def move_player_away(world)
        player_pos = @player.get_component(:position)
        monster_pos = @monster.get_component(:position)
        return unless player_pos && monster_pos

        # Find adjacent tile away from monster
        # Simple implementation: move in opposite direction
        dx = player_pos.row - monster_pos.row
        dy = player_pos.column - monster_pos.column

        # Normalize direction
        if dx.abs > dy.abs
          new_row = player_pos.row + (dx > 0 ? 1 : -1)
          new_col = player_pos.column
        else
          new_row = player_pos.row
          new_col = player_pos.column + (dy > 0 ? 1 : -1)
        end

        # For now, just clear collision data
        # Actual movement would need to check if position is valid/walkable
        # This will be handled by the collision system clearing
        message_system = Vanilla::ServiceRegistry.get(:message_system)
        if message_system
          message_system.instance_variable_set(:@last_collision_data, nil)
          @logger.debug("[RunAwayCommand] Cleared collision data")
        end
      end
    end
  end
end

