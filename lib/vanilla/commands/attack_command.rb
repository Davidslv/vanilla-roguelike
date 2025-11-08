# frozen_string_literal: true

require_relative 'command'

module Vanilla
  module Commands
    class AttackCommand < Command
      attr_reader :attacker, :target

      def initialize(attacker, target)
        super()
        @attacker = attacker
        @target = target
        @logger.debug("[AttackCommand] Initializing attack command: #{attacker&.id} -> #{target&.id}")
      end

      def execute(world)
        return if @executed

        combat_system = world.systems.find { |s, _| s.is_a?(Vanilla::Systems::CombatSystem) }&.first
        unless combat_system
          @logger.error("[AttackCommand] No CombatSystem found")
          return
        end

        # Validate attacker and target
        unless @attacker && @target
          @logger.error("[AttackCommand] Invalid attacker or target")
          @executed = true
          return
        end

        @logger.info("[AttackCommand] Executing attack: #{@attacker.id} attacks #{@target.id}")

        # If player is attacking, start turn-based combat
        if @attacker.has_tag?(:player) && @target.has_tag?(:monster)
          @logger.info("[AttackCommand] Starting turn-based combat")
          combat_system.process_turn_based_combat(@attacker, @target)
        else
          # Single attack for non-player attacks
          combat_system.process_attack(@attacker, @target)
        end

        @executed = true
      end
    end
  end
end

