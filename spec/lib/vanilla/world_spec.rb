require 'spec_helper'

RSpec.describe Vanilla::World do
  describe 'initialization' do
    it 'creates an empty world' do
      world = described_class.new
      expect(world.entities).to be_empty
      expect(world.systems).to be_empty
    end
  end

  describe 'entity management' do
    let(:world) { described_class.new }
    let(:entity) { Vanilla::Components::Entity.new }

    it 'can add entities' do
      world.add_entity(entity)
      expect(world.entities[entity.id]).to eq(entity)
    end

    it 'can remove entities' do
      world.add_entity(entity)
      world.remove_entity(entity.id)
      expect(world.entities).to be_empty
    end

    it 'can get entities by ID' do
      world.add_entity(entity)
      retrieved = world.get_entity(entity.id)
      expect(retrieved).to eq(entity)
    end

    it 'returns nil for unknown entity IDs' do
      expect(world.get_entity('nonexistent')).to be_nil
    end
  end

  describe 'entity querying' do
    let(:world) { described_class.new }
    let(:player) do
      player = Vanilla::Components::Entity.new
      player.add_component(Vanilla::Components::PositionComponent.new(row: 5, column: 10))
      player.add_component(Vanilla::Components::RenderComponent.new(character: '@'))
      player.add_tag(:player)
      world.add_entity(player)
      player
    end
    let(:monster) do
      monster = Vanilla::Components::Entity.new
      monster.add_component(Vanilla::Components::PositionComponent.new(row: 7, column: 12))
      monster.add_component(Vanilla::Components::RenderComponent.new(character: 'M'))
      monster.add_tag(:monster)
      world.add_entity(monster)
      monster
    end
    let(:stairs) do
      stairs = Vanilla::Components::Entity.new
      stairs.add_component(Vanilla::Components::PositionComponent.new(row: 15, column: 20))
      stairs.add_tag(:stairs)
      world.add_entity(stairs)
      stairs
    end

    before do
      # Create entities
      player
      monster
      stairs
    end

    it 'can query entities by component types' do
      # Entities with both position and render components
      result = world.query_entities([:position, :render])
      expect(result).to contain_exactly(player, monster)

      # Entities with only position component
      result = world.query_entities([:position])
      expect(result).to contain_exactly(player, monster, stairs)
    end

    it 'returns all entities when querying with empty component types' do
      result = world.query_entities([])
      expect(result).to contain_exactly(player, monster, stairs)
    end

    it 'can find entities by tag' do
      result = world.find_entities_by_tag(:player)
      expect(result).to contain_exactly(player)
    end

    it 'can find the first entity with a tag' do
      result = world.find_entity_by_tag(:player)
      expect(result).to eq(player)
    end

    it 'returns empty array when no entities match a tag' do
      result = world.find_entities_by_tag(:nonexistent)
      expect(result).to be_empty
    end

    it 'returns nil when no entity matches a tag' do
      result = world.find_entity_by_tag(:nonexistent)
      expect(result).to be_nil
    end
  end

  describe 'system management' do
    let(:world) { described_class.new }
    let(:system1) { double('System1', update: nil) }
    let(:system2) { double('System2', update: nil) }

    it 'can add systems with priorities' do
      world.add_system(system1, 2)
      world.add_system(system2, 1)

      # Systems should be sorted by priority
      expect(world.systems).to eq([[system2, 1], [system1, 2]])
    end

    it 'updates systems in priority order' do
      world.add_system(system1, 2)
      world.add_system(system2, 1)

      expect(system2).to receive(:update).with(0.1).ordered
      expect(system1).to receive(:update).with(0.1).ordered

      world.update(0.1)
    end
  end

  describe 'serialization' do
    let(:world) { described_class.new }
    let(:entity) do
      entity = Vanilla::Components::Entity.new
      entity.add_component(Vanilla::Components::PositionComponent.new(row: 5, column: 10))
      entity.add_tag(:player)
      world.add_entity(entity)
      entity
    end

    before do
      # Ensure entity is created
      entity
    end

    it 'can be converted to hash' do
      hash = world.to_hash
      expect(hash[:entities]).to be_an(Array)
      expect(hash[:entities].size).to eq(1)
      expect(hash[:entities].first[:id]).to eq(entity.id)
    end

    it 'can be created from hash' do
      hash = world.to_hash
      recreated = described_class.from_hash(hash)

      # Check entity was restored
      expect(recreated.entities.size).to eq(1)

      # Get the recreated entity
      recreated_entity = recreated.entities.values.first

      # Check entity properties match
      expect(recreated_entity.id).to eq(entity.id)
      expect(recreated_entity.has_component?(:position)).to be true
      expect(recreated_entity.has_tag?(:player)).to be true
    end
  end
end