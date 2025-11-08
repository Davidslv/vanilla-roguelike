# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Systems::ItemUseSystem do
  let(:world) { double('Vanilla::World') }
  let(:system) { described_class.new(world) }
  let(:logger) { instance_double('Vanilla::Logger') }
  let(:player) do
    Vanilla::Entities::Entity.new.tap do |e|
      e.name = "Player"
      e.add_tag(:player)
      e.add_component(Vanilla::Components::HealthComponent.new(max_health: 100, current_health: 50))
      e.add_component(Vanilla::Components::InventoryComponent.new(max_size: 20))
    end
  end
  let(:apple) do
    Vanilla::Entities::Entity.new.tap do |e|
      e.name = "Apple"
      e.add_component(Vanilla::Components::ItemComponent.new(name: "Apple", item_type: :food))
      e.add_component(Vanilla::Components::ConsumableComponent.new(
        charges: 1,
        effects: [{ type: :heal, amount: 20 }]
      ))
    end
  end

  before do
    allow(Vanilla::Logger).to receive(:instance).and_return(logger)
    allow(logger).to receive(:debug)
    allow(logger).to receive(:info)
    allow(logger).to receive(:error)
    allow(world).to receive(:get_entity).and_return(nil)
    allow(world).to receive(:get_entity).with(player.id).and_return(player)
    allow(world).to receive(:get_entity).with(apple.id).and_return(apple)
    allow(world).to receive(:remove_entity)
    allow(world).to receive(:emit_event)
    
    # Create a mock command queue that behaves like a Queue
    @command_queue = []
    allow(world).to receive(:command_queue).and_return(@command_queue)
    
    player.get_component(:inventory).add(apple)
  end

  describe 'apple consumption' do
    it 'restores HP when apple is used' do
      initial_health = player.get_component(:health).current_health
      expect(initial_health).to eq(50)

      @command_queue << [:use_item, { entity_id: player.id, item_id: apple.id }]
      system.update(nil)

      new_health = player.get_component(:health).current_health
      expect(new_health).to eq(70) # 50 + 20
    end

    it 'does not exceed max HP' do
      # Set health to 90 (close to max)
      player.get_component(:health).current_health = 90

      @command_queue << [:use_item, { entity_id: player.id, item_id: apple.id }]
      system.update(nil)

      new_health = player.get_component(:health).current_health
      expect(new_health).to eq(100) # Capped at max_health
    end

    it 'removes apple from inventory after use' do
      expect(player.get_component(:inventory).items).to include(apple)

      @command_queue << [:use_item, { entity_id: player.id, item_id: apple.id }]
      system.update(nil)

      expect(player.get_component(:inventory).items).not_to include(apple)
    end

    it 'emits item_used event' do
      expect(world).to receive(:emit_event).with(:item_used, { entity_id: player.id, item_id: apple.id })

      @command_queue << [:use_item, { entity_id: player.id, item_id: apple.id }]
      system.update(nil)
    end
  end
end

