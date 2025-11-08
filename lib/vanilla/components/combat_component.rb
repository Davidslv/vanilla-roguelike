# frozen_string_literal: true

module Vanilla
  module Components
    class CombatComponent < Component
      attr_reader :attack_power, :defense, :accuracy

      def initialize(attack_power:, defense:, accuracy: 0.8)
        @attack_power = attack_power
        @defense = defense

        unless accuracy.between?(0.0, 1.0)
          raise ArgumentError, "accuracy must be between 0.0 and 1.0, got #{accuracy}"
        end

        @accuracy = accuracy
      end

      def type
        :combat
      end

      def to_hash
        super.merge(
          attack_power: @attack_power,
          defense: @defense,
          accuracy: @accuracy
        )
      end

      def self.from_hash(hash)
        new(
          attack_power: hash[:attack_power],
          defense: hash[:defense],
          accuracy: hash[:accuracy] || 0.8
        )
      end
    end
    Component.register(CombatComponent)
  end
end

