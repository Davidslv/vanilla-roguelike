require 'spec_helper'

RSpec.describe Vanilla::World do
  let(:world) { Vanilla::World.new }
  let(:entity) { Vanilla::Components::Entity.new }
  let(:position_component) { Vanilla::Components::PositionComponent.new(row: 5, column: 10) }
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

    it 'initializes with nil current level' do
      expect(world.current_level).to be_nil
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

    it 'returns nil if entity not found' do
      expect(world.remove_entity('nonexistent')).to be_nil
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
    before do
      entity.add_tag(:player)
      world.add_entity(entity)
    end

    it 'returns the first entity with the specified tag' do
      expect(world.find_entity_by_tag(:player)).to eq(entity)
    end

    it 'returns nil if no entities have the specified tag' do
      expect(world.find_entity_by_tag(:nonexistent)).to be_nil
    end
  end

  describe '#query_entities' do
    let(:entity_with_position) { Vanilla::Components::Entity.new }
    let(:entity_with_render) { Vanilla::Components::Entity.new }
    let(:entity_with_both) { Vanilla::Components::Entity.new }

    before do
      entity_with_position.add_component(position_component)
      entity_with_position.add_tag(:position_only)

      render_component = Vanilla::Components::RenderComponent.new(character: '@', color: :white)
      entity_with_render.add_component(render_component)
      entity_with_render.add_tag(:render_only)

      entity_with_both.add_component(position_component.dup)
      entity_with_both.add_component(render_component.dup)
      entity_with_both.add_tag(:both)

      world.add_entity(entity_with_position)
      world.add_entity(entity_with_render)
      world.add_entity(entity_with_both)
    end

    it 'returns all entities with no component types specified' do
      entities = world.query_entities([])
      expect(entities.size).to eq(3)
      expect(entities).to include(entity_with_position, entity_with_render, entity_with_both)
    end

    it 'returns entities with specified single component type' do
      entities = world.query_entities([:position])
      expect(entities.size).to eq(2)
      expect(entities).to include(entity_with_position, entity_with_both)
      expect(entities).not_to include(entity_with_render)
    end

    it 'returns entities with all specified component types' do
      entities = world.query_entities([:position, :render])
      expect(entities.size).to eq(1)
      expect(entities).to include(entity_with_both)
      expect(entities).not_to include(entity_with_position, entity_with_render)
    end

    it 'returns empty array if no entities match the criteria' do
      entities = world.query_entities([:nonexistent])
      expect(entities).to be_empty
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
      system1 = instance_double("Vanilla::Systems::System1", update: nil)
      system2 = instance_double("Vanilla::Systems::System2", update: nil)

      world.add_system(system1, 2)
      world.add_system(system2, 1)

      expect(world.systems.map(&:first)).to eq([system2, system1])
    end

    it 'returns the added system' do
      expect(world.add_system(system)).to eq(system)
    end
  end

  describe '#update' do
    before do
      world.add_system(system)
    end

    it 'updates all systems' do
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

    it 'allows unsubscribing from events' do
      world.subscribe(event_type, subscriber)
      world.unsubscribe(event_type, subscriber)
      world.emit_event(event_type, event_data)
      world.update(0.1) # Process events

      expect(subscriber).not_to have_received(:handle_event)
    end
  end

  describe '#queue_command' do
    it 'processes add_entity commands' do
      new_entity = Vanilla::Components::Entity.new

      world.queue_command(:add_entity, { entity: new_entity })
      expect(world.entities).not_to include(new_entity.id => new_entity)

      world.update(0.1) # Process commands
      expect(world.entities).to include(new_entity.id => new_entity)
    end

    it 'processes remove_entity commands' do
      world.add_entity(entity)
      world.queue_command(:remove_entity, { entity_id: entity.id })

      world.update(0.1) # Process commands
      expect(world.entities).not_to include(entity.id => entity)
    end

    it 'handles unknown command types gracefully' do
      expect {
        world.queue_command(:nonexistent_command, { data: 'test' })
        world.update(0.1)
      }.not_to raise_error
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