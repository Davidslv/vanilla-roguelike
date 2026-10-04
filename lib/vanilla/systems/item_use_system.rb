# frozen_string_literal: true

module Vanilla
  module Systems
    # Applies a consumable's effects when the player uses it (#164). Driven by
    # UseItemCommand, the way CombatSystem is driven by AttackCommand.
    class ItemUseSystem < System
      def initialize(world)
        super(world)
        @logger = Vanilla::Logger.instance
      end

      # Items are used through UseItemCommand, not on a tick.
      def update(_dt); end

      # @return [Boolean] true if the item was used
      def use_item(entity, item)
        inventory = entity.get_component(:inventory)
        return false unless inventory&.items&.include?(item) && item.has_component?(:consumable)

        consumable = item.get_component(:consumable)
        consumable.effects.each { |effect| apply_effect(entity, effect) }
        consumable.charges -= 1
        use_up(entity, item) if consumable.charges <= 0

        emit_event(:item_used, { entity_id: entity.id, item_id: item.id })
        @logger.info("[ItemUseSystem] #{entity.id} used #{item.name}")
        true
      end

      private

      def apply_effect(entity, effect)
        case effect[:type]
        when :heal
          health = entity.get_component(:health)
          health.current_health += effect[:amount] if health # the setter caps at max
        when :nourish
          nutrition = entity.get_component(:nutrition)
          nutrition.food_left = [nutrition.food_left + effect[:amount], nutrition.max_food].min if nutrition
        else
          @logger.warn("[ItemUseSystem] Unsupported effect: #{effect[:type].inspect}")
        end
      end

      def use_up(entity, item)
        entity.get_component(:inventory).remove(item)
        @world.remove_entity(item.id)
      end
    end
  end
end
