# frozen_string_literal: true

module Vanilla
  module Systems
    # Runs the food clock (#161). Each turn_ended costs every entity with a
    # NutritionComponent one food. At 0 food it costs health, and the player
    # can die of starvation.
    class HungerSystem < System
      def initialize(world)
        super(world)
        @world.subscribe(:turn_ended, self)
      end

      # Hunger moves on turns, not frames.
      def update(_delta_time); end

      def handle_event(event_type, _data)
        return unless event_type == :turn_ended

        entities_with(:nutrition).each { |entity| tick(entity) }
      end

      private

      def tick(entity)
        nutrition = entity.get_component(:nutrition)
        before = Vanilla::Hunger.status(nutrition.food_left)
        nutrition.food_left = [nutrition.food_left - 1, 0].max
        after = Vanilla::Hunger.status(nutrition.food_left)

        if after != before
          emit_event(:hunger_status_changed, { entity_id: entity.id, from: before, to: after, food_left: nutrition.food_left })
        end
        starve(entity) if after == :starving
      end

      def starve(entity)
        health = entity.get_component(:health)
        return unless health

        health.current_health = [health.current_health - Vanilla::Hunger::STARVE_DAMAGE, 0].max
        emit_event(:starvation_damage, { entity_id: entity.id, damage: Vanilla::Hunger::STARVE_DAMAGE, current_health: health.current_health })
        @world.player_died(cause: :starvation) if health.current_health.zero? && entity.has_tag?(:player)
      end
    end
  end
end
