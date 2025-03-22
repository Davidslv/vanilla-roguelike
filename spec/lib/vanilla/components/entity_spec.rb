require 'spec_helper'

RSpec.describe Vanilla::Components::Entity do
  describe 'initialization' do
    it 'generates a UUID if no ID is provided' do
      entity = described_class.new
      expect(entity.id).not_to be_nil
      expect(entity.id).to be_a(String)
    end

    it 'uses the provided ID if one is given' do
      custom_id = 'custom-entity-id'
      entity = described_class.new(id: custom_id)
      expect(entity.id).to eq(custom_id)
    end

    it 'initializes with empty components' do
      entity = described_class.new
      expect(entity.components).to be_empty
    end

    it 'initializes with empty data and tags' do
      entity = described_class.new
      expect(entity.data).to eq({ tags: [] })
    end
  end

  describe 'component management' do
    let(:entity) { described_class.new }
    let(:position_component) { Vanilla::Components::PositionComponent.new(row: 5, column: 10) }
    let(:render_component) { Vanilla::Components::RenderComponent.new(character: '@') }

    it 'can add components' do
      entity.add_component(position_component)
      expect(entity.components).to include(position_component)
      expect(entity.has_component?(:position)).to be true
    end

    it 'can get components by type' do
      entity.add_component(position_component)
      retrieved = entity.get_component(:position)
      expect(retrieved).to eq(position_component)
    end

    it 'can remove components' do
      entity.add_component(position_component)
      removed = entity.remove_component(:position)
      expect(removed).to eq(position_component)
      expect(entity.has_component?(:position)).to be false
    end

    it 'prevents adding duplicate component types' do
      entity.add_component(position_component)
      expect {
        entity.add_component(Vanilla::Components::PositionComponent.new(row: 0, column: 0))
      }.to raise_error(ArgumentError)
    end
  end

  describe 'tag management' do
    let(:entity) { described_class.new }

    it 'can add tags' do
      entity.add_tag(:player)
      expect(entity.has_tag?(:player)).to be true
    end

    it 'can remove tags' do
      entity.add_tag(:player)
      entity.remove_tag(:player)
      expect(entity.has_tag?(:player)).to be false
    end

    it 'prevents duplicate tags' do
      entity.add_tag(:player)
      entity.add_tag(:player)
      expect(entity.data[:tags].count(:player)).to eq(1)
    end
  end

  describe 'data management' do
    let(:entity) { described_class.new }

    it 'can store arbitrary data' do
      entity.set_data(:health, 100)
      expect(entity.get_data(:health)).to eq(100)
    end

    it 'can update data' do
      entity.set_data(:health, 100)
      entity.set_data(:health, 50)
      expect(entity.get_data(:health)).to eq(50)
    end

    it 'returns nil for unknown data keys' do
      expect(entity.get_data(:nonexistent)).to be_nil
    end
  end

  describe 'serialization' do
    let(:entity) { described_class.new }
    let(:position_component) { Vanilla::Components::PositionComponent.new(row: 5, column: 10) }

    before do
      entity.add_component(position_component)
      entity.add_tag(:player)
      entity.set_data(:health, 100)
    end

    it 'can be converted to hash' do
      hash = entity.to_hash
      expect(hash[:id]).to eq(entity.id)
      expect(hash[:components]).to be_an(Array)
      expect(hash[:data]).to include(tags: [:player], health: 100)
    end

    it 'can be created from hash' do
      hash = entity.to_hash
      recreated = described_class.from_hash(hash)

      expect(recreated.id).to eq(entity.id)
      expect(recreated.has_component?(:position)).to be true
      expect(recreated.has_tag?(:player)).to be true
      expect(recreated.get_data(:health)).to eq(100)
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