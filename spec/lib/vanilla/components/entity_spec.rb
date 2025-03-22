require 'spec_helper'

RSpec.describe Vanilla::Components::Entity do
  describe '#initialize' do
    it 'creates an entity with a unique ID' do
      entity = described_class.new
      expect(entity.id).not_to be_nil
      expect(entity.id).to be_a(String)
    end

    it 'creates entities with different IDs' do
      entity1 = described_class.new
      entity2 = described_class.new
      expect(entity1.id).not_to eq(entity2.id)
    end

    it 'can be initialized with a specific ID' do
      custom_id = "custom-id-123"
      entity = described_class.new(id: custom_id)
      expect(entity.id).to eq(custom_id)
    end

    it 'starts with no components' do
      entity = described_class.new
      expect(entity.components).to be_empty
    end
  end

  describe '#add_component' do
    let(:entity) { described_class.new }
    let(:component) { double("Component", type: :test_component) }

    it 'adds a component to the entity' do
      entity.add_component(component)
      expect(entity.components).to include(component)
    end

    it 'allows access to the component by type' do
      entity.add_component(component)
      expect(entity.get_component(:test_component)).to eq(component)
    end

    it 'returns the entity for method chaining' do
      result = entity.add_component(component)
      expect(result).to eq(entity)
    end

    it 'raises an error when adding a component with a duplicate type' do
      entity.add_component(component)
      duplicate = double("Duplicate Component", type: :test_component)
      expect { entity.add_component(duplicate) }.to raise_error(ArgumentError)
    end

    it 'raises an error when component does not respond to type' do
      invalid_component = double("Invalid Component")
      expect { entity.add_component(invalid_component) }.to raise_error(ArgumentError)
    end
  end

  describe '#remove_component' do
    let(:entity) { described_class.new }
    let(:component) { double("Component", type: :test_component) }

    before do
      entity.add_component(component)
    end

    it 'removes a component by type' do
      entity.remove_component(:test_component)
      expect(entity.components).not_to include(component)
    end

    it 'returns the removed component' do
      result = entity.remove_component(:test_component)
      expect(result).to eq(component)
    end

    it 'returns nil when trying to remove a non-existent component' do
      result = entity.remove_component(:non_existent)
      expect(result).to be_nil
    end
  end

  describe '#has_component?' do
    let(:entity) { described_class.new }
    let(:component) { double("Component", type: :test_component) }

    before do
      entity.add_component(component)
    end

    it 'returns true if the entity has the component type' do
      expect(entity.has_component?(:test_component)).to be true
    end

    it 'returns false if the entity does not have the component type' do
      expect(entity.has_component?(:non_existent)).to be false
    end
  end

  describe '#get_component' do
    let(:entity) { described_class.new }
    let(:component) { double("Component", type: :test_component) }

    before do
      entity.add_component(component)
    end

    it 'returns the component of the specified type' do
      expect(entity.get_component(:test_component)).to eq(component)
    end

    it 'returns nil if the component type does not exist' do
      expect(entity.get_component(:non_existent)).to be_nil
    end
  end

  describe '#update' do
    let(:entity) { described_class.new }
    let(:component1) { double("Component1", type: :component1) }
    let(:component2) { double("Component2", type: :component2) }

    before do
      allow(component1).to receive(:update).with(entity, 1.0)
      allow(component2).to receive(:update).with(entity, 1.0)
      entity.add_component(component1)
      entity.add_component(component2)
    end

    it 'calls update on all components' do
      entity.update(1.0)
      expect(component1).to have_received(:update).with(entity, 1.0)
      expect(component2).to have_received(:update).with(entity, 1.0)
    end

    it 'skips components that do not respond to update' do
      non_updatable = double("NonUpdatable", type: :non_updatable)
      entity.add_component(non_updatable)
      expect { entity.update(1.0) }.not_to raise_error
    end
  end

  describe '#to_hash and .from_hash' do
    let(:entity) { described_class.new(id: "test-entity-1") }
    let(:component1) { double("Component1", type: :test_component1, to_hash: {type: :test_component1, data: "test-data-1"}) }
    let(:component2) { double("Component2", type: :test_component2, to_hash: {type: :test_component2, data: "test-data-2"}) }

    before do
      allow(Vanilla::Components::Component).to receive(:from_hash).with({type: :test_component1, data: "test-data-1"}).and_return(component1)
      allow(Vanilla::Components::Component).to receive(:from_hash).with({type: :test_component2, data: "test-data-2"}).and_return(component2)
      entity.add_component(component1)
      entity.add_component(component2)
    end

    it 'serializes the entity to a hash' do
      hash = entity.to_hash
      expect(hash[:id]).to eq("test-entity-1")
      expect(hash[:components]).to be_an(Array)
      expect(hash[:components].length).to eq(2)
      expect(hash[:components]).to include({type: :test_component1, data: "test-data-1"})
      expect(hash[:components]).to include({type: :test_component2, data: "test-data-2"})
    end

    it 'reconstructs an entity from a hash' do
      hash = {
        id: "test-entity-1",
        components: [
          {type: :test_component1, data: "test-data-1"},
          {type: :test_component2, data: "test-data-2"}
        ]
      }

      reconstructed = described_class.from_hash(hash)
      expect(reconstructed).to be_a(described_class)
      expect(reconstructed.id).to eq("test-entity-1")
      expect(reconstructed.components.length).to eq(2)
      expect(reconstructed.get_component(:test_component1)).to eq(component1)
      expect(reconstructed.get_component(:test_component2)).to eq(component2)
    end
  end

  describe 'compatibility with Unit' do
    # Tests to ensure the Entity can replace Unit functionality

    # First, let's create mock components for position and tile
    let(:position_component) do
      double(
        "PositionComponent",
        type: :position,
        row: 5,
        column: 10,
        coordinates: [5, 10]
      )
    end

    let(:tile_component) do
      double(
        "TileComponent",
        type: :tile,
        tile: 'T'
      )
    end

    let(:stairs_component) do
      double(
        "StairsComponent",
        type: :stairs,
        found_stairs: false,
        found_stairs?: false
      )
    end

    let(:entity) do
      entity = described_class.new
      entity.add_component(position_component)
      entity.add_component(tile_component)
      entity.add_component(stairs_component)
      entity
    end

    it 'can access row and column via method_missing' do
      expect(entity.row).to eq(5)
      expect(entity.column).to eq(10)
    end

    it 'can access tile via method_missing' do
      expect(entity.tile).to eq('T')
    end

    it 'can check if stairs are found via method_missing' do
      expect(entity.found_stairs?).to be false
    end

    it 'can get coordinates via method_missing' do
      expect(entity.coordinates).to eq([5, 10])
    end

    it 'raises NoMethodError for undefined methods' do
      expect { entity.undefined_method }.to raise_error(NoMethodError)
    end

    it 'allows setting attributes via method_missing' do
      allow(position_component).to receive(:row=).with(6)
      entity.row = 6
      expect(position_component).to have_received(:row=).with(6)
    end
  end
end