# systems/equipment_system.rb
module Vanilla
  module Systems
    class EquipmentSystem < System
      def initialize(world)
        super(world)
        @logger = Vanilla::Logger.instance
      end

      def update(_dt)
        @world.command_queue.each do |command_type, params|
          next unless command_type == :toggle_equip

          entity = @world.get_entity(params[:entity_id])
          item = @world.get_entity(params[:item_id])
          next unless entity && item && entity.has_component?(:inventory) && entity.get_component(:inventory).items.include?(item)

          equippable = item.get_component(:equippable)
          next unless equippable

          if equippable.equipped
            equippable.equipped = false
            @world.emit_event(:item_unequipped, { entity_id: entity.id, item_id: item.id })
            @logger.info("Item unequipped: #{item.get_component(:item).name}")
          else
            # Unequip any existing item in the same slot
            entity.get_component(:inventory).items.each do |other_item|
              if other_item.has_component?(:equippable) && other_item.get_component(:equippable).slot == equippable.slot
                other_item.get_component(:equippable).equipped = false
              end
            end
            equippable.equipped = true
            @world.emit_event(:item_equipped, { entity_id: entity.id, item_id: item.id })
            @logger.info("Item equipped: #{item.get_component(:item).name}")
          end
        end
      end
    end
  end
end
