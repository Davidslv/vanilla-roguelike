# frozen_string_literal: true

require_relative 'system'

module Vanilla
  module Systems
    class CombatSystem < System
      def initialize(world)
        super(world)
        @logger = Vanilla::Logger.instance
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

        event_data = {
          entity_id: entity.id
        }
        event_data[:killer_id] = killer.id if killer

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
          @logger.info("[CombatSystem] #{attacker.id} missed #{target.id}")
        end

        hit
      end
    end
  end
end

