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

        # The player drives the interactive, turn-based combat loop when it
        # attacks a hostile entity. Hostility is decided by faction rather than
        # by a hard-coded :monster tag, so any future hostile faction (undead,
        # rival NPCs, ...) routes through the same path automatically.
        if player_initiated_against_hostile?
          @logger.info("[AttackCommand] Starting turn-based combat")
          combat_system.process_turn_based_combat(@attacker, @target)
        else
          # Single attack for everything else (e.g. a monster striking back).
          combat_system.process_attack(@attacker, @target)
        end

        @executed = true
      end

      private

      # @return [Boolean] true when the player is the attacker and the target
      #   is hostile to it (the case that warrants interactive, turn-based combat)
      def player_initiated_against_hostile?
        @attacker.has_tag?(:player) && Vanilla::Factions.hostile?(@attacker, @target)
      end
    end
  end
end
