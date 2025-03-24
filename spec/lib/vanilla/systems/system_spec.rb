require 'spec_helper'

RSpec.describe Vanilla::Systems::System do
  let(:world) { instance_double("Vanilla::World") }
  let(:system) { Vanilla::Systems::System.new(world) }

  describe '#initialize' do
    it 'sets the world reference' do
      expect(system.world).to eq(world)
    end
  end

  describe '#update' do
    it 'has an update method that can be overridden' do
      expect { system.update(0.1) }.not_to raise_error
    end
  end

  describe '#handle_event' do
    it 'has a handle_event method that can be overridden' do
      expect { system.handle_event(:test, {}) }.not_to raise_error
    end
  end

  describe '#entities_with' do
    it 'delegates to world.query_entities' do
      component_types = [:position, :render]

      expect(world).to receive(:query_entities).with(component_types)
      system.entities_with(*component_types)
    end
  end

  describe '#emit_event' do
    it 'delegates to world.emit_event' do
      event_type = :entity_moved
      event_data = { entity_id: 'test-id' }

      expect(world).to receive(:emit_event).with(event_type, event_data)
      system.emit_event(event_type, event_data)
    end
  end

  describe '#queue_command' do
    it 'delegates to world.queue_command' do
      command_type = :add_entity
      command_params = { entity: 'test-entity' }

      expect(world).to receive(:queue_command).with(command_type, command_params)
      system.queue_command(command_type, command_params)
    end
  end
end
