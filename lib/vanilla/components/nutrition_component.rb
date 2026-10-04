# frozen_string_literal: true

require_relative '../hunger'

module Vanilla
  module Components
    # How much food an entity has left (#161). Data only: the rules are in
    # Vanilla::Hunger and HungerSystem. Only entities with this component get
    # hungry.
    class NutritionComponent < Component
      attr_accessor :food_left
      attr_reader :max_food

      def initialize(food_left: Vanilla::Hunger::START_FOOD, max_food: Vanilla::Hunger::MAX_FOOD)
        super()
        @food_left = food_left
        @max_food = max_food
      end

      def type
        :nutrition
      end

      def to_hash
        { type: type, food_left: @food_left, max_food: @max_food }
      end

      def self.from_hash(hash)
        new(food_left: hash[:food_left], max_food: hash[:max_food])
      end
    end

    Component.register(NutritionComponent)
  end
end
