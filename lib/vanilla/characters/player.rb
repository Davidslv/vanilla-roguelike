require_relative 'shared/movement'

module Vanilla
  module Characters
    class Player < Unit
      include Vanilla::Characters::Shared::Movement

      attr_accessor :name, :level, :experience, :inventory

      def initialize(name: 'player', row:, column:)
        super(row: row, column: column, tile: Support::TileType::PLAYER)
        @name = name

        @level = 1
        @experience = 0
        @inventory = []
      end

      def gain_experience(amount)
        @experience += amount
        check_for_level_ups
      end

      def level_up
        xp_needed = experience_to_next_level
        @level += 1
        @experience -= xp_needed
        # Add level up bonuses here
      end

      def add_to_inventory(item)
        @inventory << item
      end

      def remove_from_inventory(item)
        @inventory.delete(item)
      end

      private

      def check_for_level_ups
        while @experience >= experience_to_next_level
          next_level_xp = experience_to_next_level
          @level += 1
          @experience -= next_level_xp
        end
      end

      def experience_to_next_level
        @level * 100 # Simple formula, can be adjusted
      end
    end
  end
end