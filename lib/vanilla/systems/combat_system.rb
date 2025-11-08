# frozen_string_literal: true

require_relative 'system'

module Vanilla
  module Systems
    class CombatSystem < System
      def initialize(world)
        super(world)
        @logger = Vanilla::Logger.instance
        @active_combat = nil # { player: Entity, monster: Entity, turn: :player }
      end

      def update(_delta_time)
        # Combat is processed via commands, not in update loop
      end

      # Calculate damage based on attacker's attack_power and defender's defense
      # @param attacker_combat [CombatComponent] The attacker's combat component
      # @param defender_combat [CombatComponent] The defender's combat component
      # @return [Integer] The damage amount (minimum 1)
      def calculate_damage(attacker_combat, defender_combat)
        damage = attacker_combat.attack_power - defender_combat.defense
        [damage, 1].max
      end

      # Apply damage to a target entity
      # @param target [Entity] The entity taking damage
      # @param damage [Integer] The amount of damage
      # @param source [Entity, nil] The entity causing the damage (optional)
      def apply_damage(target, damage, source = nil)
        health = target.get_component(:health)
        return unless health

        old_health = health.current_health
        health.current_health = [old_health - damage, 0].max

        event_data = {
          target_id: target.id,
          damage: damage
        }
        event_data[:source_id] = source.id if source

        emit_event(:combat_damage, event_data)
        @logger.debug("[CombatSystem] Applied #{damage} damage to #{target.id}, health now #{health.current_health}")
      end

      # Check if an entity is dead and handle death
      # @param entity [Entity] The entity to check
      # @param killer [Entity, nil] The entity that killed this one (optional)
      # @return [Boolean] True if entity is dead, false otherwise
      def check_death(entity, killer = nil)
        health = entity.get_component(:health)
        return false unless health

        return false unless health.current_health <= 0

        # Get entity info before removing it
        entity_name = entity.name
        was_player = entity.has_tag?(:player)

        event_data = {
          entity_id: entity.id,
          entity_name: entity_name,
          was_player: was_player
        }
        event_data[:killer_id] = killer.id if killer

        # Generate loot if monster was killed by player
        if !was_player && killer && killer.has_tag?(:player)
          loot_system = @world.systems.find { |s, _| s.is_a?(Vanilla::Systems::LootSystem) }&.first
          if loot_system
            loot = loot_system.generate_loot
            # Only emit loot event if there's actually loot
            if loot[:gold] > 0 || !loot[:items].empty?
              position = entity.get_component(:position)
              emit_event(:loot_dropped, {
                loot: loot,
                position: position ? { row: position.row, column: position.column } : nil,
                monster_id: entity.id,
                killer_id: killer.id
              })
            end
          end
        end

        emit_event(:combat_death, event_data)
        @world.remove_entity(entity.id)
        @logger.info("[CombatSystem] Entity #{entity.id} has died")

        true
      end

      # Process a full attack from attacker to target
      # @param attacker [Entity] The attacking entity
      # @param target [Entity] The target entity
      # @return [Boolean] True if attack hit, false if missed
      def process_attack(attacker, target)
        attacker_combat = attacker.get_component(:combat)
        target_combat = target.get_component(:combat)
        return false unless attacker_combat && target_combat

        # Emit attack event
        emit_event(:combat_attack, {
                     attacker_id: attacker.id,
                     target_id: target.id
                   })

        # Check if attack hits based on accuracy
        hit = rand < attacker_combat.accuracy

        if hit
          damage = calculate_damage(attacker_combat, target_combat)
          apply_damage(target, damage, attacker)
          check_death(target, attacker)
          @logger.info("[CombatSystem] #{attacker.id} hit #{target.id} for #{damage} damage")
        else
          # Emit miss event
          emit_event(:combat_miss, {
                       attacker_id: attacker.id,
                       target_id: target.id
                     })
          @logger.info("[CombatSystem] #{attacker.id} missed #{target.id}")
        end

        hit
      end

      # Process turn-based combat between player and monster
      # Player attacks first, then monster counter-attacks
      # Continues until one dies
      # @param player [Entity] The player entity
      # @param monster [Entity] The monster entity
      def process_turn_based_combat(player, monster)
        return if @active_combat # Already in combat

        @active_combat = { player: player, monster: monster, turn: :player }
        @logger.info("[CombatSystem] Starting turn-based combat: player #{player.id} vs monster #{monster.id}")

        # Combat loop - continue until one dies
        while @active_combat && combat_active?
          if @active_combat[:turn] == :player
            player_turn
          else
            monster_turn
          end

          # Switch turns (only if combat is still active)
          break unless combat_active?
          @active_combat[:turn] = @active_combat[:turn] == :player ? :monster : :player
        end

        # Clear combat state
        @active_combat = nil
        @logger.info("[CombatSystem] Turn-based combat ended")
      end

      # Player's turn in combat
      def player_turn
        return unless @active_combat

        player = @active_combat[:player]
        monster = @active_combat[:monster]
        @logger.debug("[CombatSystem] Player turn: #{player.id} attacks #{monster.id}")
        process_attack(player, monster)
      end

      # Monster's turn in combat
      def monster_turn
        return unless @active_combat

        player = @active_combat[:player]
        monster = @active_combat[:monster]
        @logger.debug("[CombatSystem] Monster turn: #{monster.id} attacks #{player.id}")
        process_attack(monster, player)
      end

      # Check if combat is still active (both entities alive)
      # @return [Boolean] True if both entities are alive, false otherwise
      def combat_active?
        return false unless @active_combat

        player = @active_combat[:player]
        monster = @active_combat[:monster]

        player_health = player.get_component(:health)
        monster_health = monster.get_component(:health)

        return false unless player_health && monster_health

        player_health.current_health > 0 && monster_health.current_health > 0
      end
    end
  end
end

