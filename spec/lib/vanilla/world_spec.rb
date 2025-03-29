# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::World do
  let(:world) { described_class.new }
  let(:mock_display) { instance_double(Vanilla::DisplayHandler) }
  let(:mock_logger) { instance_double(Vanilla::Logger, debug: nil, warn: nil, error: nil, info: nil) }
  let(:mock_event_manager) { instance_double("EventManager", publish_event: nil) }

  before do
    allow(Vanilla::DisplayHandler).to receive(:new).and_return(mock_display)
    allow(Vanilla::Logger).to receive(:instance).and_return(mock_logger)
    allow(Vanilla::ServiceRegistry).to receive(:get).with(:event_manager).and_return(mock_event_manager)
  end

  describe '#initialize' do
    it 'initializes with empty entities and systems' do
      expect(world.entities).to be_empty
      expect(world.systems).to be_empty
      expect(world.quit).to be false
      expect(world.current_level).to be_nil
      expect(world.level_changed).to be false
    end
  end

  describe '#update' do
    it 'updates all systems in priority order' do
      system1 = instance_double("System")
      system2 = instance_double("System")

      expect(system1).to receive(:update).with(nil)
      expect(system2).to receive(:update).with(nil)

      world.add_system(system1, 10)
      world.add_system(system2, 5)

      world.update(nil)
    end

    it 'processes commands and events' do
      # Need to spy on private methods
      allow(world).to receive(:process_commands).and_call_original
      allow(world).to receive(:process_events).and_call_original

      world.update(nil)

      expect(world).to have_received(:process_commands)
      expect(world).to have_received(:process_events)
    end
  end

  describe '#quit?' do
    it 'returns the current quit state' do
      expect(world.quit?).to be false

      world.quit = true
      expect(world.quit?).to be true
    end
  end

  describe '#level_changed?' do
    it 'returns and resets the level_changed flag' do
      expect(world.level_changed?).to be false

      world.level_changed = true
      expect(world.level_changed?).to be true
      expect(world.level_changed?).to be false # Flag is reset after first check
    end
  end

  describe 'entity management' do
    let(:entity) do
      instance_double(
        "Entity",
        id: "entity-1",
        name: "Test Entity",
        has_tag?: false,
        has_component?: false
      )
    end

    let(:position_component) { instance_double("PositionComponent") }

    before do
      allow(entity).to receive(:has_tag?).with("player").and_return(true)
      allow(entity).to receive(:has_component?).with(:position).and_return(true)
      allow(entity).to receive(:get_component).with(:position).and_return(position_component)
    end

    describe '#add_entity' do
      it 'adds an entity to the world' do
        result = world.add_entity(entity)

        expect(result).to eq(entity)
        expect(world.entities[entity.id]).to eq(entity)
      end
    end

    describe '#remove_entity' do
      it 'removes an entity from the world' do
        world.add_entity(entity)
        world.remove_entity(entity.id)

        expect(world.entities).to be_empty
      end
    end

    describe '#get_entity' do
      it 'retrieves an entity by ID' do
        world.add_entity(entity)

        expect(world.get_entity(entity.id)).to eq(entity)
      end

      it 'returns nil for non-existent entities' do
        expect(world.get_entity("non-existent")).to be_nil
      end
    end

    describe '#get_entity_by_name' do
      it 'retrieves an entity by name' do
        world.add_entity(entity)

        expect(world.get_entity_by_name("Test Entity")).to eq(entity)
      end

      it 'returns nil for non-existent names' do
        expect(world.get_entity_by_name("Non-existent Name")).to be_nil
      end
    end

    describe '#find_entity_by_tag' do
      it 'finds an entity with a specific tag' do
        world.add_entity(entity)

        expect(world.find_entity_by_tag("player")).to eq(entity)
      end

      it 'returns nil for non-existent tags' do
        world.add_entity(entity)

        expect(world.find_entity_by_tag("enemy")).to be_nil
      end
    end

    describe '#query_entities' do
      let(:entity2) { instance_double("Entity", id: "entity-2", has_component?: false) }

      before do
        allow(entity2).to receive(:has_component?).with(:position).and_return(true)
        allow(entity2).to receive(:has_component?).with(:renderable).and_return(false)

        allow(entity).to receive(:has_component?).with(:renderable).and_return(true)

        world.add_entity(entity)
        world.add_entity(entity2)
      end

      it 'returns all entities when component_types is empty' do
        result = world.query_entities([])

        expect(result.size).to eq(2)
        expect(result).to include(entity, entity2)
      end

      it 'returns entities with all specified components' do
        result = world.query_entities([:position, :renderable])

        expect(result.size).to eq(1)
        expect(result).to include(entity)
        expect(result).not_to include(entity2)
      end
    end
  end

  describe 'system management' do
    let(:system1) { instance_double("System") }
    let(:system2) { instance_double("System") }

    describe '#add_system' do
      it 'adds a system with a priority' do
        world.add_system(system1, 10)

        expect(world.systems).to include([system1, 10])
      end

      it 'orders systems by priority' do
        world.add_system(system1, 10)
        world.add_system(system2, 5)

        expect(world.systems).to eq([[system2, 5], [system1, 10]])
      end
    end
  end

  describe 'event and command handling' do
    describe '#queue_command' do
      it 'adds a command to the command queue' do
        command_type = :test_command
        params = { test: 'param' }

        world.queue_command(command_type, params)

        # We can't directly test the private queue, but we can test the behavior
        # Use a test subscriber to verify commands get executed
        command_processor = Class.new do
          attr_reader :executed, :params

          def initialize
            @executed = false
            @params = nil
          end

          def execute(world)
            @params = world
            @executed = true
          end
        end.new

        world.queue_command(command_processor)
        world.update(nil) # Process commands

        expect(command_processor.executed).to be true
        expect(command_processor.params).to eq(world)
      end
    end

    describe '#emit_event and #subscribe' do
      let(:subscriber) { instance_double("Subscriber", handle_event: nil) }
      let(:event_type) { :test_event }
      let(:event_data) { { test: 'data' } }

      it 'notifies subscribers of events' do
        world.subscribe(event_type, subscriber)
        world.emit_event(event_type, event_data)
        world.update(nil) # Process events

        expect(subscriber).to have_received(:handle_event).with(event_type, event_data)
      end

      it 'notifies the event manager when available' do
        world.emit_event(event_type, event_data)
        world.update(nil) # Process events

        expect(mock_event_manager).to have_received(:publish_event).with(event_type, world, event_data)
      end

      it 'logs an error when event manager is not available' do
        allow(Vanilla::ServiceRegistry).to receive(:get).with(:event_manager).and_return(nil)

        world.emit_event(event_type, event_data)
        world.update(nil) # Process events

        expect(mock_logger).to have_received(:error).with("[World#process_events] No event manager found")
      end

      it 'allows unsubscribing from events' do
        world.subscribe(event_type, subscriber)
        world.unsubscribe(event_type, subscriber)

        world.emit_event(event_type, event_data)
        world.update(nil) # Process events

        expect(subscriber).not_to have_received(:handle_event)
      end
    end
  end

  describe 'level management' do
    let(:mock_level) { instance_double("Level", grid: 'test-grid') }

    describe '#set_level' do
      it 'sets the current level' do
        world.set_level(mock_level)

        expect(world.current_level).to eq(mock_level)
      end
    end

    describe '#grid' do
      it 'returns the current level grid' do
        world.set_level(mock_level)

        expect(world.grid).to eq('test-grid')
      end

      it 'returns nil when there is no current level' do
        expect(world.grid).to be_nil
      end
    end
  end

  describe 'private methods' do
    describe '#process_commands' do
      it 'executes Command objects directly' do
        command = instance_double("Vanilla::Commands::Command")
        allow(command).to receive(:is_a?).with(Vanilla::Commands::Command).and_return(true)
        expect(command).to receive(:execute).with(world)

        world.queue_command(command)
        world.send(:process_commands)
      end

      it 'delegates to handle_command for symbol commands (deprecated)' do
        entity = instance_double("Entity", id: "entity-1")

        world.queue_command(:add_entity, { entity: entity })
        expect(mock_logger).to receive(:warn).with("[World#handle_command] This method is deprecated; use command.execute(self) instead")

        world.send(:process_commands)

        expect(world.entities["entity-1"]).to eq(entity)
      end
    end

    describe '#handle_command' do
      it 'handles add_entity commands' do
        entity = instance_double("Entity", id: "entity-1")

        world.send(:handle_command, :add_entity, { entity: entity })

        expect(world.entities["entity-1"]).to eq(entity)
      end

      it 'handles remove_entity commands' do
        entity = instance_double("Entity", id: "entity-1")
        world.add_entity(entity)

        world.send(:handle_command, :remove_entity, { entity_id: "entity-1" })

        expect(world.entities).to be_empty
      end

      it 'handles add_to_inventory commands' do
        player = instance_double("Entity", id: "player-1")
        item = instance_double("Entity", id: "item-1")
        inventory = instance_double("InventoryComponent")

        allow(player).to receive(:has_component?).with(:inventory).and_return(true)
        allow(player).to receive(:get_component).with(:inventory).and_return(inventory)
        allow(item).to receive(:has_component?).with(:item).and_return(true)

        world.add_entity(player)
        world.add_entity(item)

        expect(inventory).to receive(:add_item).with(item)

        world.send(:handle_command, :add_to_inventory, { player_id: "player-1", item_id: "item-1" })
      end

      it 'logs an error for change_level commands (deprecated)' do
        expect(mock_logger).to receive(:error).with("[World#handle_command] Deprecated; use ChangeLevelCommand instead")

        world.send(:handle_command, :change_level, {})
      end

      it 'logs an error for unknown command types' do
        expect(mock_logger).to receive(:error).with("[World#handle_command] Unknown command type: unknown_command")

        world.send(:handle_command, :unknown_command, {})
      end
    end

    describe '#add_to_inventory' do
      it 'adds item to player inventory when both have required components' do
        player = instance_double("Entity", id: "player-1")
        item = instance_double("Entity", id: "item-1")
        inventory = instance_double("InventoryComponent")

        allow(player).to receive(:has_component?).with(:inventory).and_return(true)
        allow(player).to receive(:get_component).with(:inventory).and_return(inventory)
        allow(item).to receive(:has_component?).with(:item).and_return(true)

        world.add_entity(player)
        world.add_entity(item)

        expect(inventory).to receive(:add_item).with(item)

        world.send(:add_to_inventory, "player-1", "item-1")
      end

      it 'does nothing when player or item lack required components' do
        player = instance_double("Entity", id: "player-1")
        item = instance_double("Entity", id: "item-1")

        allow(player).to receive(:has_component?).with(:inventory).and_return(false)
        allow(item).to receive(:has_component?).with(:item).and_return(true)

        world.add_entity(player)
        world.add_entity(item)

        # No expectations on inventory.add_item - it should not be called

        world.send(:add_to_inventory, "player-1", "item-1")
      end
    end

    describe '#process_events' do
      let(:subscriber) { instance_double("Subscriber", handle_event: nil) }
      let(:event_type) { :test_event }
      let(:event_data) { { test: 'data' } }

      it 'dispatches events to subscribers' do
        world.subscribe(event_type, subscriber)
        world.emit_event(event_type, event_data)

        world.send(:process_events)

        expect(subscriber).to have_received(:handle_event).with(event_type, event_data)
      end

      it 'publishes events to the event manager if available' do
        world.emit_event(event_type, event_data)

        world.send(:process_events)

        expect(mock_event_manager).to have_received(:publish_event).with(event_type, world, event_data)
      end

      it 'logs errors when the event manager is not available' do
        allow(Vanilla::ServiceRegistry).to receive(:get).with(:event_manager).and_return(nil)

        world.emit_event(event_type, event_data)

        expect(mock_logger).to receive(:error).with("[World#process_events] No event manager found")

        world.send(:process_events)
      end
    end
  end
end
