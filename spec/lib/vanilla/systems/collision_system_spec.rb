# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Systems::CollisionSystem do
  let(:world) { instance_double('Vanilla::World') }
  let(:system) { described_class.new(world) }
  let(:logger) { instance_double('Vanilla::Logger') }
  let(:player) do
    Vanilla::Entities::Entity.new.tap do |e|
      e.name = "Player"
      e.add_tag(:player)
      e.add_component(Vanilla::Components::PositionComponent.new(row: 2, column: 2))
    end
  end
  let(:monster) do
    Vanilla::Entities::Entity.new.tap do |e|
      e.name = "Goblin"
      e.add_tag(:monster)
      e.add_component(Vanilla::Components::PositionComponent.new(row: 2, column: 2))
    end
  end
  let(:stairs) do
    Vanilla::Entities::Entity.new.tap do |e|
      e.name = "Stairs"
      e.add_tag(:stairs)
      e.add_component(Vanilla::Components::PositionComponent.new(row: 3, column: 3))
    end
  end
  let(:item) do
    Vanilla::Entities::Entity.new.tap do |e|
      e.name = "Gold"
      e.add_tag(:item)
      e.add_component(Vanilla::Components::PositionComponent.new(row: 2, column: 2))
      e.add_component(Vanilla::Components::ItemComponent.new(name: "Gold", item_type: :currency))
    end
  end

  before do
    allow(Vanilla::Logger).to receive(:instance).and_return(logger)
    allow(logger).to receive(:debug)
    allow(logger).to receive(:info)
    allow(logger).to receive(:error)
    allow(logger).to receive(:warn)
    allow(world).to receive(:subscribe)
    allow(world).to receive(:get_entity).and_return(nil)
    allow(world).to receive(:queue_command)
    allow(world).to receive(:emit_event)
    allow(world).to receive(:query_entities).with([:position]).and_return([])
  end

  describe '#initialize' do
    it 'subscribes to entity_moved events' do
      new_world = instance_double('Vanilla::World')
      allow(new_world).to receive(:subscribe)
      system = described_class.new(new_world)
      expect(new_world).to have_received(:subscribe).with(:entity_moved, system)
    end
  end

  describe '#update' do
    it 'does nothing (collision handled via events)' do
      expect { system.update(nil) }.not_to raise_error
    end
  end

  describe '#handle_event' do
    context 'when entity moves' do
      before do
        allow(world).to receive(:get_entity).with(player.id).and_return(player)
        allow(world).to receive(:query_entities).with([:position]).and_return([player, monster])
      end

      it 'emits entities_collided event when entities are at same position' do
        expect(world).to receive(:emit_event).with(:entities_collided, hash_including(
          entity_id: player.id,
          other_entity_id: monster.id
        ))
        system.handle_event(:entity_moved, {
          entity_id: player.id,
          new_position: { row: 2, column: 2 }
        })
      end

      it 'does not emit collision for same entity' do
        allow(world).to receive(:query_entities).with([:position]).and_return([player])
        expect(world).not_to receive(:emit_event).with(:entities_collided, anything)
        system.handle_event(:entity_moved, {
          entity_id: player.id,
          new_position: { row: 2, column: 2 }
        })
      end

      it 'uses position from entity if new_position not in data' do
        allow(world).to receive(:query_entities).with([:position]).and_return([player, monster])
        expect(world).to receive(:emit_event).with(:entities_collided, anything)
        system.handle_event(:entity_moved, {
          entity_id: player.id
        })
      end

      it 'does nothing if entity has no position component' do
        player.remove_component(:position)
        allow(world).to receive(:get_entity).with(player.id).and_return(player)
        expect(world).not_to receive(:emit_event).with(:entities_collided, anything)
        system.handle_event(:entity_moved, {
          entity_id: player.id
        })
      end

      it 'does nothing if entity not found' do
        allow(world).to receive(:get_entity).with(player.id).and_return(nil)
        expect(world).not_to receive(:emit_event).with(:entities_collided, anything)
        system.handle_event(:entity_moved, {
          entity_id: player.id,
          new_position: { row: 2, column: 2 }
        })
      end
    end

    context 'player-stairs collision' do
      before do
        allow(world).to receive(:get_entity).with(player.id).and_return(player)
        allow(world).to receive(:query_entities).with([:position]).and_return([player, stairs])
      end

      it 'emits level_transition_requested event' do
        expect(world).to receive(:emit_event).with(:level_transition_requested, { player_id: player.id })
        system.handle_event(:entity_moved, {
          entity_id: player.id,
          new_position: { row: 3, column: 3 }
        })
      end
    end

    context 'player-item collision' do
      before do
        allow(world).to receive(:get_entity).with(player.id).and_return(player)
        player.add_component(Vanilla::Components::InventoryComponent.new)
        allow(world).to receive(:query_entities).with([:position]).and_return([player, item])
      end

      it 'emits item_picked_up event' do
        expect(world).to receive(:emit_event).with(:item_picked_up, hash_including(
          player_id: player.id,
          item_id: item.id
        ))
        system.handle_event(:entity_moved, {
          entity_id: player.id,
          new_position: { row: 2, column: 2 }
        })
      end

      it 'queues add_to_inventory command' do
        expect(world).to receive(:queue_command).with(:add_to_inventory, hash_including(
          player_id: player.id,
          item_id: item.id
        ))
        system.handle_event(:entity_moved, {
          entity_id: player.id,
          new_position: { row: 2, column: 2 }
        })
      end

      it 'queues remove_entity command' do
        expect(world).to receive(:queue_command).with(:remove_entity, hash_including(
          entity_id: item.id
        ))
        system.handle_event(:entity_moved, {
          entity_id: player.id,
          new_position: { row: 2, column: 2 }
        })
      end

      it 'does not pick up item if player has no inventory' do
        player.remove_component(:inventory)
        expect(world).not_to receive(:emit_event).with(:item_picked_up, anything)
        system.handle_event(:entity_moved, {
          entity_id: player.id,
          new_position: { row: 2, column: 2 }
        })
      end
    end

    it 'ignores non-entity_moved events' do
      expect(world).not_to receive(:emit_event)
      system.handle_event(:other_event, {})
    end
  end

  describe 'private methods' do
    describe '#find_entities_at_position' do
      it 'finds entities at specified position' do
        allow(world).to receive(:query_entities).with([:position]).and_return([player, monster])
        result = system.send(:find_entities_at_position, 2, 2)
        expect(result).to include(player, monster)
      end

      it 'excludes entities at different positions' do
        other_entity = Vanilla::Entities::Entity.new.tap do |e|
          e.add_component(Vanilla::Components::PositionComponent.new(row: 5, column: 5))
        end
        allow(world).to receive(:query_entities).with([:position]).and_return([player, other_entity])
        result = system.send(:find_entities_at_position, 2, 2)
        expect(result).to include(player)
        expect(result).not_to include(other_entity)
      end
    end
  end
end

