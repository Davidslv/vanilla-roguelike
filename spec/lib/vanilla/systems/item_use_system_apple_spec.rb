# frozen_string_literal: true

require 'spec_helper'

# Issue #164: ItemUseSystem used to poll World#command_queue, which World
# never exposed, and this spec hid that behind a plain double. It now uses a
# verifying double, so the system can only call what World really offers.
RSpec.describe Vanilla::Systems::ItemUseSystem do
  let(:world) { instance_double(Vanilla::World, emit_event: nil, remove_entity: nil) }
  let(:system) { described_class.new(world) }
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
      e.add_component(Vanilla::Components::ConsumableComponent.new(charges: 1, effects: [{ type: :heal, amount: 20 }]))
    end
  end

  before { player.get_component(:inventory).add(apple) }

  describe '#use_item' do
    it 'restores HP' do
      expect(system.use_item(player, apple)).to be(true)
      expect(player.get_component(:health).current_health).to eq(70)
    end

    it 'does not heal past max HP' do
      player.get_component(:health).current_health = 95

      system.use_item(player, apple)

      expect(player.get_component(:health).current_health).to eq(100)
    end

    it 'removes the apple from the inventory and the world once its charges run out' do
      system.use_item(player, apple)

      expect(player.get_component(:inventory).items).not_to include(apple)
      expect(world).to have_received(:remove_entity).with(apple.id)
    end

    it 'keeps an item that still has charges' do
      apple.get_component(:consumable).charges = 2

      system.use_item(player, apple)

      expect(player.get_component(:inventory).items).to include(apple)
      expect(apple.get_component(:consumable).charges).to eq(1)
    end

    it 'emits item_used' do
      system.use_item(player, apple)

      expect(world).to have_received(:emit_event).with(:item_used, { entity_id: player.id, item_id: apple.id })
    end

    it 'refuses an item that is not in the inventory' do
      player.get_component(:inventory).remove(apple)

      expect(system.use_item(player, apple)).to be(false)
      expect(player.get_component(:health).current_health).to eq(50)
    end

    it 'refuses an item that is not consumable' do
      sword = Vanilla::Entities::Entity.new
      player.get_component(:inventory).add(sword)

      expect(system.use_item(player, sword)).to be(false)
      expect(world).not_to have_received(:emit_event)
    end
  end
end
