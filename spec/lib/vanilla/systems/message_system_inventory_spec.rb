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
      e.add_component(Vanilla::Components::PositionComponent.new(row: 5, column: 5))
    end
  end
  let(:item1) do
    Vanilla::Entities::Entity.new.tap do |e|
      e.name = "Health Potion"
      e.add_component(Vanilla::Components::ItemComponent.new(name: "Health Potion", item_type: :potion, stackable: false))
    end
  end
  let(:item2) do
    Vanilla::Entities::Entity.new.tap do |e|
      e.name = "Sword"
      e.add_component(Vanilla::Components::ItemComponent.new(name: "Sword", item_type: :weapon, stackable: false))
    end
  end

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
    allow(world).to receive(:add_entity)
    allow(world).to receive(:current_level).and_return(instance_double('Vanilla::Level', add_entity: nil, update_grid_with_entity: nil))
    allow(world).to receive(:respond_to?).with(:process_events, true).and_return(true)
    allow(world).to receive(:send).with(:process_events)
    allow(Vanilla::ServiceRegistry).to receive(:register)
    allow(Vanilla::ServiceRegistry).to receive(:get).and_return(nil)
  end

  describe '#add_inventory_option_if_available' do
    before do
      allow(world).to receive(:get_entity_by_name).with('Player').and_return(player)
    end

    context 'when not in combat mode' do
      it 'adds inventory option to menu' do
        system.add_inventory_option_if_available(world)
        system.update(nil) # Process message queue

        messages = system.instance_variable_get(:@manager).instance_variable_get(:@message_log).messages
        inventory_messages = messages.select { |m| m.content.to_s == "menu.inventory" }
        expect(inventory_messages).not_to be_empty

        message = inventory_messages.first
        expect(message.options).not_to be_empty
        expect(message.options.first[:key]).to eq('i')
        expect(message.options.first[:callback]).to eq(:show_inventory)
      end

      it 'shows correct item count in inventory option' do
        player.get_component(:inventory).add(item1)
        player.get_component(:inventory).add(item2)

        system.add_inventory_option_if_available(world)
        system.update(nil)

        messages = system.instance_variable_get(:@manager).instance_variable_get(:@message_log).messages
        inventory_message = messages.find { |m| m.content.to_s == "menu.inventory" }
        expect(inventory_message.options.first[:content]).to include("2 items")
      end

      it 'updates existing inventory message instead of creating duplicate' do
        system.add_inventory_option_if_available(world)
        system.update(nil)
        
        # Add item and call again
        player.get_component(:inventory).add(item1)
        system.add_inventory_option_if_available(world)
        system.update(nil)

        messages = system.instance_variable_get(:@manager).instance_variable_get(:@message_log).messages
        inventory_messages = messages.select { |m| m.content.to_s == "menu.inventory" }
        expect(inventory_messages.size).to eq(1) # Should only have one message
      end
    end

    context 'when in combat mode' do
      before do
        system.instance_variable_set(:@last_collision_data, { entity_id: player.id, other_entity_id: 'monster-id' })
      end

      it 'does not add inventory option' do
        system.add_inventory_option_if_available(world)
        system.update(nil)

        messages = system.instance_variable_get(:@manager).instance_variable_get(:@message_log).messages
        inventory_messages = messages.select { |m| m.content.to_s == "menu.inventory" }
        expect(inventory_messages).to be_empty
      end
    end

    context 'when player has no inventory component' do
      before do
        player.remove_component(:inventory)
        allow(world).to receive(:get_entity_by_name).with('Player').and_return(player)
      end

      it 'does not add inventory option' do
        system.add_inventory_option_if_available(world)
        system.update(nil)

        messages = system.instance_variable_get(:@manager).instance_variable_get(:@message_log).messages
        inventory_messages = messages.select { |m| m.content.to_s == "menu.inventory" }
        expect(inventory_messages).to be_empty
      end
    end
  end

  describe '#handle_inventory_callback' do
    before do
      allow(world).to receive(:get_entity_by_name).with('Player').and_return(player)
    end

    context 'when inventory is empty' do
      it 'shows empty inventory message' do
        system.handle_inventory_callback
        system.update(nil)

        messages = system.instance_variable_get(:@manager).instance_variable_get(:@message_log).messages
        empty_messages = messages.select { |m| m.content.to_s == "inventory.empty" }
        expect(empty_messages).not_to be_empty
      end
    end

    context 'when inventory has items' do
      before do
        player.get_component(:inventory).add(item1)
        player.get_component(:inventory).add(item2)
      end

      it 'shows inventory items with numbered options' do
        system.handle_inventory_callback
        system.update(nil)

        messages = system.instance_variable_get(:@manager).instance_variable_get(:@message_log).messages
        items_messages = messages.select { |m| m.content.to_s == "inventory.items" }
        expect(items_messages).not_to be_empty

        message = items_messages.first
        expect(message.options.size).to eq(2)
        expect(message.options.first[:key]).to eq('1')
        expect(message.options.first[:callback]).to eq(:select_item)
        expect(message.options.first[:item_id]).to eq(item1.id)
        expect(message.options.last[:key]).to eq('2')
        expect(message.options.last[:item_id]).to eq(item2.id)
      end

      it 'includes item names in options' do
        system.handle_inventory_callback
        system.update(nil)

        messages = system.instance_variable_get(:@manager).instance_variable_get(:@message_log).messages
        message = messages.find { |m| m.content.to_s == "inventory.items" }
        expect(message.options.first[:content]).to include("Health Potion")
        expect(message.options.last[:content]).to include("Sword")
      end
    end
  end

  describe '#handle_item_selection' do
    before do
      allow(world).to receive(:get_entity_by_name).with('Player').and_return(player)
      player.get_component(:inventory).add(item1)
    end

    it 'shows item action options' do
      system.handle_item_selection(item1.id)
      system.update(nil)

      messages = system.instance_variable_get(:@manager).instance_variable_get(:@message_log).messages
      action_messages = messages.select { |m| m.content.to_s == "inventory.item_actions" }
      expect(action_messages).not_to be_empty

      message = action_messages.first
      expect(message.options.size).to be >= 2 # At least Use and Drop
      
      use_option = message.options.find { |opt| opt[:callback] == :use_item }
      drop_option = message.options.find { |opt| opt[:callback] == :drop_item }
      back_option = message.options.find { |opt| opt[:callback] == :show_inventory }

      expect(use_option).not_to be_nil
      expect(drop_option).not_to be_nil
      expect(back_option).not_to be_nil
    end

    it 'includes item name in action options' do
      system.handle_item_selection(item1.id)
      system.update(nil)

      messages = system.instance_variable_get(:@manager).instance_variable_get(:@message_log).messages
      message = messages.find { |m| m.content.to_s == "inventory.item_actions" }
      use_option = message.options.find { |opt| opt[:callback] == :use_item }
      expect(use_option[:content]).to include("Health Potion")
    end
  end

  # Item use and drop run as commands (#164). These examples cover what
  # MessageSystem still owns: running the command, the message, the menu.
  # The item behaviour itself is in item_use_system_apple_spec,
  # item_drop_system_spec and spec/integration/items_spec.
  describe '#handle_item_action_callback' do
    let(:use_command) { instance_double(Vanilla::Commands::UseItemCommand, execute: true) }
    let(:drop_command) { instance_double(Vanilla::Commands::DropItemCommand, execute: true) }

    def message_keys
      system.instance_variable_get(:@manager).instance_variable_get(:@message_log).messages.map { |m| m.content.to_s }
    end

    before do
      allow(world).to receive(:get_entity_by_name).with('Player').and_return(player)
      player.get_component(:inventory).add(item1)
      allow(Vanilla::Commands::UseItemCommand).to receive(:new).with(player, item1).and_return(use_command)
      allow(Vanilla::Commands::DropItemCommand).to receive(:new).with(player, item1).and_return(drop_command)
      system.instance_variable_get(:@manager).toggle_selection_mode
    end

    context 'when using an item' do
      it 'runs UseItemCommand against the world' do
        system.handle_item_action_callback(:use_item, item1.id)

        expect(use_command).to have_received(:execute).with(world)
      end

      it 'says the item was used and closes the menu' do
        system.handle_item_action_callback(:use_item, item1.id)
        system.update(nil)

        expect(message_keys).to include('inventory.item_used')
        expect(system.selection_mode?).to be false
      end

      it 'says the item cannot be used when the command fails' do
        allow(use_command).to receive(:execute).and_return(false)

        system.handle_item_action_callback(:use_item, item1.id)
        system.update(nil)

        expect(message_keys).to include('inventory.cannot_use')
        expect(message_keys).not_to include('inventory.item_used')
      end
    end

    context 'when dropping an item' do
      it 'runs DropItemCommand against the world' do
        system.handle_item_action_callback(:drop_item, item1.id)

        expect(drop_command).to have_received(:execute).with(world)
      end

      it 'says the item was dropped and closes the menu' do
        system.handle_item_action_callback(:drop_item, item1.id)
        system.update(nil)

        expect(message_keys).to include('inventory.item_dropped')
        expect(system.selection_mode?).to be false
      end

      it 'says nothing when the drop fails' do
        allow(drop_command).to receive(:execute).and_return(false)

        system.handle_item_action_callback(:drop_item, item1.id)
        system.update(nil)

        expect(message_keys).not_to include('inventory.item_dropped')
      end
    end
  end

  describe '#clear_inventory_options' do
    before do
      allow(world).to receive(:get_entity_by_name).with('Player').and_return(player)
    end

    it 'clears options from inventory messages' do
      # Add inventory option
      system.add_inventory_option_if_available(world)
      system.update(nil)

      # Show inventory
      system.handle_inventory_callback
      system.update(nil)

      messages = system.instance_variable_get(:@manager).instance_variable_get(:@message_log).messages
      inventory_messages = messages.select { |m| m.content.to_s.start_with?("inventory.") || m.content.to_s == "menu.inventory" }
      expect(inventory_messages.any? { |m| !m.options.empty? }).to be true

      # Clear options
      system.clear_inventory_options

      inventory_messages.each do |msg|
        expect(msg.options).to be_empty
      end
    end
  end

  describe '#in_combat_mode?' do
    it 'returns false when not in combat' do
      expect(system.send(:in_combat_mode?)).to be false
    end

    it 'returns true when collision data exists' do
      system.instance_variable_set(:@last_collision_data, { entity_id: 'player-id' })
      expect(system.send(:in_combat_mode?)).to be true
    end

    it 'returns true when combat options are present' do
      message_log = system.instance_variable_get(:@manager).instance_variable_get(:@message_log)
      message = Vanilla::Messages::Message.new("test", options: [
        { key: '1', content: "Attack", callback: :attack_monster }
      ])
      message_log.add_message(message)
      
      expect(system.send(:in_combat_mode?)).to be true
    end
  end

  describe 'integration: full inventory flow' do
    before do
      allow(world).to receive(:get_entity_by_name).with('Player').and_return(player)
      player.get_component(:inventory).add(item1)
    end

    it 'handles complete flow: menu -> inventory -> select item -> use' do
      # Step 1: Add inventory option
      system.add_inventory_option_if_available(world)
      system.update(nil)

      # Step 2: Handle inventory selection
      system.handle_input('i')
      system.update(nil)

      messages = system.instance_variable_get(:@manager).instance_variable_get(:@message_log).messages
      expect(messages.any? { |m| m.content.to_s == "inventory.items" }).to be true

      # Step 3: Handle item selection
      system.handle_input('1')
      system.update(nil)

      messages = system.instance_variable_get(:@manager).instance_variable_get(:@message_log).messages
      expect(messages.any? { |m| m.content.to_s == "inventory.item_actions" }).to be true
    end
  end
end

