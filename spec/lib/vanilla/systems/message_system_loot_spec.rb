# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Systems::MessageSystem do
  let(:world) { instance_double('Vanilla::World') }
  let(:system) { described_class.new(world) }
  let(:logger) { instance_double('Vanilla::Logger') }
  let(:player) do
    Vanilla::Entities::Entity.new.tap do |e|
      e.name = "Player"
      e.add_tag(:player)
      e.add_component(Vanilla::Components::InventoryComponent.new(max_size: 20))
      e.add_component(Vanilla::Components::CurrencyComponent.new(0, :gold))
    end
  end
  let(:monster) do
    Vanilla::Entities::Entity.new.tap do |e|
      e.name = "Goblin"
      e.add_tag(:monster)
      e.add_component(Vanilla::Components::PositionComponent.new(row: 5, column: 5))
    end
  end
  let(:loot_system) { instance_double('Vanilla::Systems::LootSystem') }

  before do
    allow(Vanilla::Logger).to receive(:instance).and_return(logger)
    allow(logger).to receive(:debug)
    allow(logger).to receive(:info)
    allow(logger).to receive(:error)
    allow(logger).to receive(:warn)
    allow(world).to receive(:subscribe)
    allow(world).to receive(:queue_command)
    allow(world).to receive(:get_entity).and_return(nil)
    allow(world).to receive(:get_entity_by_name).and_return(nil)
    allow(world).to receive(:systems).and_return([])
    allow(world).to receive(:respond_to?).with(:process_events, true).and_return(true)
    allow(world).to receive(:send).with(:process_events)
    allow(Vanilla::ServiceRegistry).to receive(:register)
    allow(Vanilla::ServiceRegistry).to receive(:get).and_return(nil)
  end

  describe 'loot drop on monster death' do
    before do
      allow(world).to receive(:get_entity).with(player.id).and_return(player)
      allow(world).to receive(:get_entity).with(monster.id).and_return(monster)
      allow(world).to receive(:systems).and_return([[loot_system, 6]])
      allow(loot_system).to receive(:is_a?).with(Vanilla::Systems::LootSystem).and_return(true)
    end

    context 'when loot is generated' do
      let(:apple) do
        Vanilla::Entities::Entity.new.tap do |e|
          e.name = "Apple"
          e.add_component(Vanilla::Components::ItemComponent.new(name: "Apple", item_type: :food))
        end
      end

      it 'shows loot drop message with pickup options' do
        loot = { gold: 5, items: [apple] }
        allow(loot_system).to receive(:generate_loot).and_return(loot)

        system.handle_event(:loot_dropped, {
          loot: loot,
          position: { row: 5, column: 5 },
          monster_id: monster.id,
          killer_id: player.id
        })
        system.update(nil)

        messages = system.instance_variable_get(:@manager).instance_variable_get(:@message_log).messages
        loot_messages = messages.select { |m| m.content.to_s == "loot.dropped" }
        expect(loot_messages).not_to be_empty

        message = loot_messages.first
        expect(message.options).not_to be_empty
        expect(message.options.size).to eq(2)
        
        pickup_option = message.options.find { |opt| opt[:key] == '1' }
        ignore_option = message.options.find { |opt| opt[:key] == '2' }
        
        expect(pickup_option).not_to be_nil
        expect(pickup_option[:callback]).to eq(:pickup_loot)
        expect(ignore_option).not_to be_nil
        expect(ignore_option[:callback]).to eq(:ignore_loot)
      end

      it 'stores loot data for pickup' do
        loot = { gold: 5, items: [apple] }
        allow(loot_system).to receive(:generate_loot).and_return(loot)

        system.handle_event(:loot_dropped, {
          loot: loot,
          position: { row: 5, column: 5 },
          monster_id: monster.id,
          killer_id: player.id
        })
        system.update(nil)

        loot_data = system.instance_variable_get(:@last_loot_data)
        expect(loot_data).not_to be_nil
        expect(loot_data[:gold]).to eq(5)
        expect(loot_data[:items]).to include(apple)
      end
    end

    context 'when no loot is generated' do
      it 'does not show loot message' do
        loot = { gold: 0, items: [] }
        allow(loot_system).to receive(:generate_loot).and_return(loot)

        system.handle_event(:loot_dropped, {
          loot: loot,
          position: { row: 5, column: 5 },
          monster_id: monster.id,
          killer_id: player.id
        })
        system.update(nil)

        messages = system.instance_variable_get(:@manager).instance_variable_get(:@message_log).messages
        loot_messages = messages.select { |m| m.content.to_s == "loot.dropped" }
        expect(loot_messages).to be_empty
      end
    end
  end

  describe '#handle_pickup_loot_callback' do
    let(:apple) do
      Vanilla::Entities::Entity.new.tap do |e|
        e.name = "Apple"
        e.add_component(Vanilla::Components::ItemComponent.new(name: "Apple", item_type: :food))
      end
    end

    before do
      allow(world).to receive(:get_entity_by_name).with('Player').and_return(player)
      system.instance_variable_set(:@last_loot_data, {
        gold: 5,
        items: [apple],
        position: { row: 5, column: 5 }
      })
    end

    it 'adds gold to player currency' do
      currency = player.get_component(:currency)
      initial_gold = currency.value
      
      system.send(:handle_pickup_loot_callback)
      
      expect(currency.value).to eq(initial_gold + 5)
    end

    it 'adds items to player inventory' do
      initial_item_count = player.get_component(:inventory).items.size
      
      system.send(:handle_pickup_loot_callback)
      
      expect(player.get_component(:inventory).items.size).to eq(initial_item_count + 1)
      expect(player.get_component(:inventory).items).to include(apple)
    end

    it 'shows pickup message with loot details' do
      system.send(:handle_pickup_loot_callback)
      system.update(nil)

      messages = system.instance_variable_get(:@manager).instance_variable_get(:@message_log).messages
      pickup_messages = messages.select { |m| m.content.to_s == "loot.picked_up" }
      expect(pickup_messages).not_to be_empty
    end

    it 'clears loot data after pickup' do
      system.send(:handle_pickup_loot_callback)
      
      loot_data = system.instance_variable_get(:@last_loot_data)
      expect(loot_data).to be_nil
    end

    it 'exits selection mode after pickup' do
      system.instance_variable_get(:@manager).toggle_selection_mode
      expect(system.selection_mode?).to be true

      system.send(:handle_pickup_loot_callback)
      system.update(nil)

      expect(system.selection_mode?).to be false
    end
  end

  describe '#handle_ignore_loot_callback' do
    before do
      system.instance_variable_set(:@last_loot_data, {
        gold: 5,
        items: [],
        position: { row: 5, column: 5 }
      })
    end

    it 'shows ignore message' do
      system.send(:handle_ignore_loot_callback)
      system.update(nil)

      messages = system.instance_variable_get(:@manager).instance_variable_get(:@message_log).messages
      ignore_messages = messages.select { |m| m.content.to_s == "loot.ignored" }
      expect(ignore_messages).not_to be_empty
    end

    it 'clears loot data after ignoring' do
      system.send(:handle_ignore_loot_callback)
      
      loot_data = system.instance_variable_get(:@last_loot_data)
      expect(loot_data).to be_nil
    end

    it 'exits selection mode after ignoring' do
      system.instance_variable_get(:@manager).toggle_selection_mode
      expect(system.selection_mode?).to be true

      system.send(:handle_ignore_loot_callback)
      system.update(nil)

      expect(system.selection_mode?).to be false
    end
  end
end

