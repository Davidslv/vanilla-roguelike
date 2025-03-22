require 'spec_helper'

RSpec.describe Vanilla::Systems::System do
  let(:world) { Vanilla::World.new }

  # Test implementation of System for testing
  class TestSystem < Vanilla::Systems::System
    attr_reader :update_called, :event_handled, :last_event

    def initialize(world)
      super
      @update_called = false
      @event_handled = false
      @last_event = nil
    end

    def update(delta_time)
      @update_called = true
    end

    def handle_event(event_type, data)
      @event_handled = true
      @last_event = { type: event_type, data: data }
    end
  end

  describe '#initialize' do
    it 'stores the world reference' do
      system = TestSystem.new(world)
      expect(system.world).to eq(world)
    end
  end

  describe '#update' do
    it 'requires subclasses to implement update' do
      system = described_class.new(world)
      expect { system.update(0.1) }.to raise_error(NotImplementedError)
    end

    it 'can be overridden by subclasses' do
      system = TestSystem.new(world)
      system.update(0.1)
      expect(system.update_called).to be true
    end
  end

  describe '#handle_event' do
    it 'has a default implementation' do
      system = described_class.new(world)
      # Should not raise error
      system.handle_event(:test_event, { data: 'value' })
    end

    it 'can be overridden by subclasses' do
      system = TestSystem.new(world)
      system.handle_event(:test_event, { data: 'value' })
      expect(system.event_handled).to be true
      expect(system.last_event[:type]).to eq(:test_event)
      expect(system.last_event[:data]).to eq({ data: 'value' })
    end
  end

  describe '#entities_with' do
    it 'queries entities from the world' do
      # Create test entities with different components
      entity1 = Vanilla::Components::Entity.new
      entity1.add_component(Vanilla::Components::PositionComponent.new(row: 1, column: 1))
      world.add_entity(entity1)

      entity2 = Vanilla::Components::Entity.new
      entity2.add_component(Vanilla::Components::PositionComponent.new(row: 2, column: 2))
      entity2.add_component(Vanilla::Components::RenderComponent.new(character: '@'))
      world.add_entity(entity2)

      system = TestSystem.new(world)

      # Query for entities with position components
      position_entities = system.entities_with(:position)
      expect(position_entities).to contain_exactly(entity1, entity2)

      # Query for entities with position and render components
      render_entities = system.entities_with(:position, :render)
      expect(render_entities).to contain_exactly(entity2)
    end
  end

  describe '#emit_event' do
    it 'delegates to the world' do
      system = TestSystem.new(world)

      # Create a spy system to catch events
      spy_system = TestSystem.new(world)
      world.subscribe(:test_event, spy_system)

      # Emit event
      system.emit_event(:test_event, { value: 42 })

      # Update world to process events
      world.update(0.1)

      # Check if the spy system received the event
      expect(spy_system.event_handled).to be true
      expect(spy_system.last_event[:type]).to eq(:test_event)
      expect(spy_system.last_event[:data]).to eq({ value: 42 })
    end
  end
end