# frozen_string_literal: true

require_relative 'system'

module Vanilla
  module Systems
    class LootSystem < System
      def initialize(world)
        super(world)
        @logger = Vanilla::Logger.instance
      end

      # Generate loot when a monster dies
      # @return [Hash] Loot hash with :gold (Integer) and :items (Array) keys
      def generate_loot
        loot = { gold: 0, items: [] }

        # 90% chance for gold (1-10 coins)
        if rand < 0.9
          loot[:gold] = rand(1..10)
        end

        # 30% chance for apple
        if rand < 0.3
          loot[:items] << create_apple
        end

        @logger.debug("[LootSystem] Generated loot: #{loot[:gold]} gold, #{loot[:items].size} items")
        loot
      end

      # Create an apple entity
      # @return [Entity] Apple entity with consumable component
      def create_apple
        apple = Vanilla::Entities::Entity.new
        apple.name = "Apple"
        
        # Add item component
        apple.add_component(Vanilla::Components::ItemComponent.new(
          name: "Apple",
          item_type: :food,
          stackable: false
        ))
        
        # Add consumable component with heal effect
        apple.add_component(Vanilla::Components::ConsumableComponent.new(
          charges: 1,
          effects: [
            { type: :heal, amount: 20 } # Restore 20 HP
          ],
          auto_identify: true
        ))
        
        apple
      end
    end
  end
end

