require 'spec_helper'

RSpec.describe Vanilla::EntityFactory do
  let(:world) { Vanilla::World.new }

  describe '.create_player' do
    it 'creates a player entity with appropriate components' do
      player = described_class.create_player(world, 5, 10, "Hero")

      # Check that entity was added to world
      expect(world.entities[player.id]).to eq(player)

      # Check that entity has the required components
      expect(player.has_component?(:position)).to be true
      expect(player.has_component?(:movement)).to be true
      expect(player.has_component?(:render)).to be true
      expect(player.has_component?(:stairs)).to be true

      # Check that entity has the player tag
      expect(player.has_tag?(:player)).to be true

      # Check specific component values
      position = player.get_component(:position)
      expect(position.row).to eq(5)
      expect(position.column).to eq(10)

      render = player.get_component(:render)
      expect(render.entity_type).to eq('player')
    end
  end

  describe '.create_monster' do
    it 'creates a monster entity with appropriate components' do
      monster = described_class.create_monster(world, 7, 12, "troll", 20, 5)

      # Check that entity was added to world
      expect(world.entities[monster.id]).to eq(monster)

      # Check that entity has the required components
      expect(monster.has_component?(:position)).to be true
      expect(monster.has_component?(:movement)).to be true
      expect(monster.has_component?(:render)).to be true

      # Check that entity has the monster tag
      expect(monster.has_tag?(:monster)).to be true

      # Check specific component values
      position = monster.get_component(:position)
      expect(position.row).to eq(7)
      expect(position.column).to eq(12)

      render = monster.get_component(:render)
      expect(render.entity_type).to eq('troll')

      # Check custom data
      expect(monster.get_data(:health)).to eq(20)
      expect(monster.get_data(:damage)).to eq(5)
      expect(monster.get_data(:monster_type)).to eq('troll')
    end
  end

  describe '.create_stairs' do
    it 'creates a stairs entity with appropriate components' do
      stairs = described_class.create_stairs(world, 15, 20)

      # Check that entity was added to world
      expect(world.entities[stairs.id]).to eq(stairs)

      # Check that entity has the required components
      expect(stairs.has_component?(:position)).to be true
      expect(stairs.has_component?(:render)).to be true

      # Check that entity has the stairs tag
      expect(stairs.has_tag?(:stairs)).to be true

      # Check specific component values
      position = stairs.get_component(:position)
      expect(position.row).to eq(15)
      expect(position.column).to eq(20)

      render = stairs.get_component(:render)
      expect(render.entity_type).to eq('stairs')
    end
  end

  describe 'tag methods' do
    let(:entity) { Vanilla::Components::Entity.new }

    it 'can add, check and remove tags' do
      # Add a tag
      described_class.add_tag(entity, :test_tag)
      expect(described_class.has_tag?(entity, :test_tag)).to be true

      # Add another tag
      described_class.add_tag(entity, :another_tag)
      expect(described_class.has_tag?(entity, :another_tag)).to be true

      # Tags don't interfere with each other
      expect(described_class.has_tag?(entity, :test_tag)).to be true
    end
  end

  describe 'data methods' do
    let(:entity) { Vanilla::Components::Entity.new }

    it 'can store and retrieve arbitrary data' do
      # Store data
      described_class.add_data(entity, :health, 100)
      expect(described_class.get_data(entity, :health)).to eq(100)

      # Update data
      described_class.add_data(entity, :health, 50)
      expect(described_class.get_data(entity, :health)).to eq(50)

      # Multiple data values
      described_class.add_data(entity, :name, "Test Entity")
      expect(described_class.get_data(entity, :name)).to eq("Test Entity")
      expect(described_class.get_data(entity, :health)).to eq(50)
    end
  end
end