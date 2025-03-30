# frozen_string_literal: true

module Vanilla
  module Systems
    class ItemUseSystem < System
      def initialize(world)
        super(world)
        @logger = Vanilla::Logger.instance
      end

      def update(_dt)
        @world.command_queue.each do |command_type, params|
          next unless command_type == :use_item

          entity = @world.get_entity(params[:entity_id])
          item = @world.get_entity(params[:item_id])
          next unless entity && item && entity.has_component?(:inventory) && entity.get_component(:inventory).items.include?(item)

          next unless item.has_component?(:consumable)

          consumable = item.get_component(:consumable)
          consumable.effects.each do |effect|
            case effect[:type]
            when :heal
              health = entity.get_component(:health)
              health.current_health = [health.max_health, health.current_health + effect[:amount]].min if health
            when :buff
              effect_comp = entity.get_component(:effect) || entity.add_component(EffectComponent.new)
              effect_comp.add_effect(effect)
            end
          end
          consumable.charges -= 1
          if consumable.charges <= 0
            entity.get_component(:inventory).items.delete(item)
            @world.remove_entity(item.id)
          end
          @world.emit_event(:item_used, { entity_id: entity.id, item_id: item.id })
          @logger.info("Item used: #{item.get_component(:item).name}")
        end
      end
    end
  end
end
