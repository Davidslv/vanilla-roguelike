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

        @logger.info("[AttackCommand] Executing attack: #{@attacker&.id} attacks #{@target&.id}")
        combat_system.process_attack(@attacker, @target)
        @executed = true
      end
    end
  end
end

