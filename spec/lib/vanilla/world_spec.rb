# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::World do
  let(:world) { Vanilla::World.new }
  let(:entity) { Vanilla::Components::Entity.new }
  let(:system) { instance_double("Vanilla::Systems::System", update: nil) }

  describe '#initialize' do
    it 'initializes with empty entities and systems' do
      expect(world.entities).to be_empty
      expect(world.systems).to be_empty
    end

    it 'initializes with keyboard and display handlers' do
      expect(world.keyboard).to be_a(Vanilla::KeyboardHandler)
      expect(world.display).to be_a(Vanilla::DisplayHandler)
    end
  end

  describe '#add_entity' do
    it 'adds an entity to the world' do
      world.add_entity(entity)
      expect(world.entities).to include(entity.id => entity)
    end

    it 'returns the added entity' do
      expect(world.add_entity(entity)).to eq(entity)
    end
  end

  describe '#remove_entity' do
    it 'removes an entity from the world' do
      world.add_entity(entity)
      world.remove_entity(entity.id)
      expect(world.entities).not_to include(entity.id => entity)
    end
  end

  describe '#get_entity' do
    it 'returns an entity by id' do
      world.add_entity(entity)
      expect(world.get_entity(entity.id)).to eq(entity)
    end

    it 'returns nil if entity not found' do
      expect(world.get_entity('nonexistent-id')).to be_nil
    end
  end

  describe '#find_entity_by_tag' do
    it 'returns the first entity with the specified tag' do
      entity.add_tag(:player)
      world.add_entity(entity)
      expect(world.find_entity_by_tag(:player)).to eq(entity)
    end

    it 'returns nil if no entities have the specified tag' do
      expect(world.find_entity_by_tag(:nonexistent)).to be_nil
    end
  end

  describe '#query_entities' do
    let(:position_component) { instance_double("Vanilla::Components::PositionComponent") }
    let(:render_component) { instance_double("Vanilla::Components::RenderComponent") }

    before do
      allow(entity).to receive(:has_component?).with(:position).and_return(true)
      allow(entity).to receive(:has_component?).with(:render).and_return(true)
      allow(entity).to receive(:has_component?).with(:input).and_return(false)
      world.add_entity(entity)
    end

    it 'returns all entities with no component types specified' do
      expect(world.query_entities([])).to eq([entity])
    end

    it 'returns entities with specified component types' do
      expect(world.query_entities([:position, :render])).to eq([entity])
    end

    it 'returns empty array if no entities match the criteria' do
      expect(world.query_entities([:position, :input])).to be_empty
    end
  end

  describe '#add_system' do
    it 'adds a system to the world' do
      world.add_system(system)
      expect(world.systems.map(&:first)).to include(system)
    end

    it 'assigns the specified priority' do
      world.add_system(system, 5)
      expect(world.systems).to include([system, 5])
    end

    it 'sorts systems by priority' do
      system1 = instance_double("Vanilla::Systems::System", update: nil)
      system2 = instance_double("Vanilla::Systems::System", update: nil)

      world.add_system(system1, 2)
      world.add_system(system2, 1)

      expect(world.systems.map(&:first)).to eq([system2, system1])
    end
  end

  describe '#update' do
    it 'updates all systems' do
      world.add_system(system)
      world.update(0.1)
      expect(system).to have_received(:update).with(0.1)
    end
  end

  describe '#emit_event and #subscribe' do
    let(:subscriber) { double("Subscriber", handle_event: nil) }
    let(:event_type) { :test_event }
    let(:event_data) { { test: 'data' } }

    it 'notifies subscribers of events' do
      world.subscribe(event_type, subscriber)
      world.emit_event(event_type, event_data)
      world.update(0.1) # Process events

      expect(subscriber).to have_received(:handle_event).with(event_type, event_data)
    end

    it 'does not notify unsubscribed systems' do
      other_subscriber = double("OtherSubscriber", handle_event: nil)

      world.subscribe(event_type, subscriber)
      world.emit_event(event_type, event_data)
      world.update(0.1) # Process events

      expect(other_subscriber).not_to have_received(:handle_event)
    end

    it 'does not notify subscribers of different events' do
      world.subscribe(:other_event, subscriber)
      world.emit_event(event_type, event_data)
      world.update(0.1) # Process events

      expect(subscriber).not_to have_received(:handle_event)
    end
  end

  describe '#queue_command' do
    it 'processes commands in the update loop' do
      entity_to_add = Vanilla::Components::Entity.new

      world.queue_command(:add_entity, { entity: entity_to_add })
      expect(world.entities).not_to include(entity_to_add.id => entity_to_add)

      world.update(0.1) # Process commands
      expect(world.entities).to include(entity_to_add.id => entity_to_add)
    end

    it 'handles remove_entity commands' do
      world.add_entity(entity)
      world.queue_command(:remove_entity, { entity_id: entity.id })

      world.update(0.1) # Process commands
      expect(world.entities).not_to include(entity.id => entity)
    end
  end

  describe '#set_level' do
    let(:level) { instance_double("Vanilla::Level") }

    it 'sets the current level' do
      world.set_level(level)
      expect(world.current_level).to eq(level)
    end
  end
end
