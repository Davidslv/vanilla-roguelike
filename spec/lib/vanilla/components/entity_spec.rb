require 'spec_helper'

RSpec.describe Vanilla::Components::Entity do
  let(:entity) { Vanilla::Components::Entity.new }
  let(:position_component) { Vanilla::Components::PositionComponent.new(row: 5, column: 10) }
  let(:movement_component) { Vanilla::Components::MovementComponent.new }
  let(:input_component) { Vanilla::Components::InputComponent.new }

  describe '#initialize' do
    it 'creates an entity with a default ID' do
      entity = Vanilla::Components::Entity.new
      expect(entity.id).not_to be_nil
      expect(entity.id).to be_a(String)
    end

    it 'creates an entity with a provided ID' do
      entity = Vanilla::Components::Entity.new(id: 'custom-id')
      expect(entity.id).to eq('custom-id')
    end

    it 'initializes with empty components' do
      expect(entity.components).to be_empty
    end

    it 'initializes with a default name based on id' do
      entity = Vanilla::Components::Entity.new(id: '12345678-abcd-efgh')
      expect(entity.name).to eq('Entity_12345678')
    end
  end

  describe '#add_component' do
    it 'adds a component to the entity' do
      entity.add_component(position_component)
      expect(entity.components).to include(position_component)
    end

    it 'returns self for method chaining' do
      result = entity.add_component(position_component)
      expect(result).to eq(entity)
    end

    it 'raises an error when adding a component without a type method' do
      invalid_component = double('InvalidComponent')
      expect { entity.add_component(invalid_component) }.to raise_error(ArgumentError, /must respond to #type/)
    end

    it 'raises an error when adding a duplicate component type' do
      entity.add_component(position_component)
      duplicate_component = Vanilla::Components::PositionComponent.new
      expect { entity.add_component(duplicate_component) }.to raise_error(ArgumentError, /already has a component/)
    end
  end

  describe '#remove_component' do
    before { entity.add_component(position_component) }

    it 'removes a component from the entity' do
      entity.remove_component(:position)
      expect(entity.components).not_to include(position_component)
    end

    it 'returns the removed component' do
      result = entity.remove_component(:position)
      expect(result).to eq(position_component)
    end

    it 'returns nil when removing a non-existent component' do
      result = entity.remove_component(:nonexistent)
      expect(result).to be_nil
    end
  end

  describe '#has_component?' do
    before { entity.add_component(position_component) }

    it 'returns true when the entity has the component' do
      expect(entity.has_component?(:position)).to be true
    end

    it 'returns false when the entity does not have the component' do
      expect(entity.has_component?(:render)).to be false
    end
  end

  describe '#get_component' do
    before { entity.add_component(position_component) }

    it 'returns the component when it exists' do
      expect(entity.get_component(:position)).to eq(position_component)
    end

    it 'returns nil when the component does not exist' do
      expect(entity.get_component(:render)).to be_nil
    end
  end

  describe '#add_tag' do
    it 'adds a tag to the entity' do
      entity.add_tag(:player)
      expect(entity.has_tag?(:player)).to be true
    end

    it 'converts string tags to symbols' do
      entity.add_tag('enemy')
      expect(entity.has_tag?(:enemy)).to be true
    end

    it 'returns self for method chaining' do
      result = entity.add_tag(:player)
      expect(result).to eq(entity)
    end
  end

  describe '#remove_tag' do
    before { entity.add_tag(:player) }

    it 'removes a tag from the entity' do
      entity.remove_tag(:player)
      expect(entity.has_tag?(:player)).to be false
    end

    it 'handles string tags' do
      entity.remove_tag('player')
      expect(entity.has_tag?(:player)).to be false
    end

    it 'returns self for method chaining' do
      result = entity.remove_tag(:player)
      expect(result).to eq(entity)
    end
  end

  describe '#has_tag?' do
    before { entity.add_tag(:player) }

    it 'returns true when the entity has the tag' do
      expect(entity.has_tag?(:player)).to be true
    end

    it 'returns false when the entity does not have the tag' do
      expect(entity.has_tag?(:enemy)).to be false
    end

    it 'handles string tags' do
      expect(entity.has_tag?('player')).to be true
    end
  end

  describe '#tags' do
    before do
      entity.add_tag(:player)
      entity.add_tag(:controllable)
    end

    it 'returns all tags as an array' do
      expect(entity.tags).to match_array([:player, :controllable])
    end
  end

  describe '#update' do
    let(:updatable_component) { double('UpdatableComponent', type: :updatable, update: nil) }
    let(:static_component) { double('StaticComponent', type: :static) }

    before do
      allow(updatable_component).to receive(:to_hash).and_return({ type: :updatable })
      allow(static_component).to receive(:to_hash).and_return({ type: :static })
      entity.add_component(updatable_component)
      entity.add_component(static_component)
    end

    it 'calls update on components that respond to update' do
      entity.update(0.1)
      expect(updatable_component).to have_received(:update).with(0.1)
    end

    it 'does not call update on components that do not respond to update' do
      entity.update(0.1)
      # No expectation needed as static_component doesn't have an update method
    end
  end

  describe '#to_hash' do
    before do
      entity.name = 'TestEntity'
      entity.add_tag(:player)
      entity.add_component(position_component)
    end

    it 'returns a hash representation of the entity' do
      hash = entity.to_hash
      expect(hash[:id]).to eq(entity.id)
      expect(hash[:name]).to eq('TestEntity')
      expect(hash[:tags]).to include(:player)
      expect(hash[:components].size).to eq(1)
      expect(hash[:components].first[:type]).to eq(:position)
    end
  end

  describe '.from_hash' do
    let(:hash) do
      {
        id: 'test-entity-id',
        name: 'TestEntity',
        tags: [:player, :controllable],
        components: [
          { type: :position, row: 5, column: 10 }
        ]
      }
    end

    before do
      # Stub Component.get_class to return actual component classes
      allow(Vanilla::Components::Component).to receive(:get_class).with(:position).and_return(Vanilla::Components::PositionComponent)
    end

    it 'creates an entity from a hash' do
      entity = Vanilla::Components::Entity.from_hash(hash)
      expect(entity.id).to eq('test-entity-id')
      expect(entity.name).to eq('TestEntity')
      expect(entity.tags).to match_array([:player, :controllable])
      expect(entity.has_component?(:position)).to be true
      expect(entity.get_component(:position).row).to eq(5)
      expect(entity.get_component(:position).column).to eq(10)
    end

    it 'handles missing tags' do
      hash_without_tags = hash.dup
      hash_without_tags.delete(:tags)
      entity = Vanilla::Components::Entity.from_hash(hash_without_tags)
      expect(entity.tags).to be_empty
    end

    it 'handles missing components' do
      hash_without_components = hash.dup
      hash_without_components.delete(:components)
      entity = Vanilla::Components::Entity.from_hash(hash_without_components)
      expect(entity.components).to be_empty
    end
  end

  describe 'deprecated method_missing' do
    before do
      # Stub logger to avoid test output pollution
      logger = double('Logger')
      allow(logger).to receive(:warn)
      allow(Vanilla::Logger).to receive(:instance).and_return(logger)

      entity.add_component(position_component)
    end

    it 'accesses components directly by name' do
      expect(entity.position).to eq(position_component)
    end

    it 'checks component existence with predicate methods' do
      expect(entity.position?).to be true
      expect(entity.render?).to be false
    end

    it 'falls back to super for unknown methods' do
      expect { entity.unknown_method }.to raise_error(NoMethodError)
    end
  end

  describe 'deprecated respond_to_missing?' do
    before do
      # Stub logger to avoid test output pollution
      logger = double('Logger')
      allow(logger).to receive(:warn)
      allow(Vanilla::Logger).to receive(:instance).and_return(logger)

      entity.add_component(position_component)
    end

    it 'returns true for component accessors' do
      expect(entity.respond_to?(:position)).to be true
    end

    it 'returns true for component predicates' do
      expect(entity.respond_to?(:position?)).to be true
    end

    it 'returns false for unknown methods' do
      expect(entity.respond_to?(:unknown_method)).to be false
    end
  end
end
