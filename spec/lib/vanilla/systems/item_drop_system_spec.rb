# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Systems::ItemDropSystem do
  let(:level) { instance_double(Vanilla::Level, add_entity: nil, update_grid_with_entity: nil) }
  let(:world) { instance_double(Vanilla::World, emit_event: nil, add_entity: nil, current_level: level) }
  let(:system) { described_class.new(world) }
  let(:player) do
    Vanilla::Entities::Entity.new.tap do |e|
      e.add_component(Vanilla::Components::InventoryComponent.new(max_size: 20))
      e.add_component(Vanilla::Components::PositionComponent.new(row: 4, column: 6))
    end
  end
  let(:apple) do
    Vanilla::Entities::Entity.new.tap do |e|
      e.add_component(Vanilla::Components::ItemComponent.new(name: "Apple", item_type: :food))
    end
  end

  before { player.get_component(:inventory).add(apple) }

  describe '#drop_item' do
    it 'moves the item from the inventory to the floor under the player' do
      expect(system.drop_item(player, apple)).to be(true)

      expect(player.get_component(:inventory).items).not_to include(apple)
      position = apple.get_component(:position)
      expect([position.row, position.column]).to eq([4, 6])
    end

    it 'adds the item to the world and the level, and redraws its cell' do
      system.drop_item(player, apple)

      expect(world).to have_received(:add_entity).with(apple)
      expect(level).to have_received(:add_entity).with(apple)
      expect(level).to have_received(:update_grid_with_entity).with(apple)
    end

    it 'gives an item with no look a default glyph' do
      system.drop_item(player, apple)

      expect(apple.get_component(:render).character).to eq(Vanilla::Support::TileType::GOLD)
    end

    it 'emits item_dropped' do
      system.drop_item(player, apple)

      expect(world).to have_received(:emit_event).with(:item_dropped, { entity_id: player.id, item_id: apple.id })
    end

    it 'refuses an item that is not in the inventory' do
      player.get_component(:inventory).remove(apple)

      expect(system.drop_item(player, apple)).to be(false)
      expect(world).not_to have_received(:add_entity)
    end
  end
end
