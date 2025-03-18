require 'spec_helper'

RSpec.describe Vanilla::Entities::Monster do
  let(:row) { 10 }
  let(:column) { 15 }
  let(:monster) { described_class.new(monster_type: 'troll', row: row, column: column, health: 20, damage: 5) }

  describe '#initialize' do
    it 'creates a monster with the specified attributes' do
      expect(monster.monster_type).to eq('troll')
      expect(monster.health).to eq(20)
      expect(monster.damage).to eq(5)
    end

    it 'has the correct components' do
      expect(monster.has_component?(:position)).to be(true)
      expect(monster.has_component?(:movement)).to be(true)
      expect(monster.has_component?(:render)).to be(true)
    end

    it 'positions the monster at the given coordinates' do
      position = monster.get_component(:position)
      expect(position.row).to eq(row)
      expect(position.column).to eq(column)
    end

    it 'uses the monster character for rendering' do
      render = monster.get_component(:render)
      expect(render.character).to eq(Vanilla::Support::TileType::MONSTER)
    end

    it 'has the correct entity type' do
      render = monster.get_component(:render)
      expect(render.entity_type).to eq('troll')
    end
  end

  describe '#alive?' do
    it 'returns true when health is positive' do
      expect(monster.alive?).to be(true)
    end

    it 'returns false when health is zero' do
      monster.health = 0
      expect(monster.alive?).to be(false)
    end
  end

  describe '#take_damage' do
    it 'reduces health by the damage amount' do
      expect { monster.take_damage(5) }.to change { monster.health }.by(-5)
    end

    it 'does not reduce health below zero' do
      monster.take_damage(30)
      expect(monster.health).to eq(0)
    end

    it 'returns the remaining health' do
      expect(monster.take_damage(5)).to eq(15)
    end
  end

  describe '#attack' do
    let(:target) { double('target') }

    context 'when target can take damage' do
      before do
        allow(target).to receive(:respond_to?).with(:take_damage).and_return(true)
        allow(target).to receive(:take_damage).and_return(15)
      end

      it 'inflicts damage on the target' do
        expect(target).to receive(:take_damage).with(monster.damage)
        monster.attack(target)
      end

      it 'returns the damage amount' do
        expect(monster.attack(target)).to eq(monster.damage)
      end
    end

    context 'when target cannot take damage' do
      before do
        allow(target).to receive(:respond_to?).with(:take_damage).and_return(false)
      end

      it 'returns zero damage' do
        expect(monster.attack(target)).to eq(0)
      end
    end
  end

  describe 'serialization' do
    let(:serialized) { monster.to_hash }

    it 'serializes all required attributes' do
      expect(serialized[:monster_type]).to eq(monster.monster_type)
      expect(serialized[:health]).to eq(monster.health)
      expect(serialized[:damage]).to eq(monster.damage)

      # Check that the components were serialized
      components = serialized[:components]
      expect(components).to be_an(Array)
      expect(components.map { |c| c[:type] }).to include(:position, :movement, :render)
    end

    # Test deserialization with a hand-crafted hash with proper component structure
    it 'can be deserialized from a hash with properly structured components' do
      hash = {
        id: 'test-id',
        monster_type: 'ogre',
        health: 30,
        damage: 8,
        components: [
          {
            type: :position,
            data: { row: 5, column: 8 }
          },
          {
            type: :movement,
            data: {}
          },
          {
            type: :render,
            data: { character: Vanilla::Support::TileType::MONSTER, entity_type: 'ogre' }
          }
        ]
      }

      monster = described_class.from_hash(hash)
      expect(monster.id).to eq('test-id')
      expect(monster.monster_type).to eq('ogre')
      expect(monster.health).to eq(30)
      expect(monster.damage).to eq(8)

      position = monster.get_component(:position)
      expect(position).not_to be_nil
      expect(position.row).to eq(5)
      expect(position.column).to eq(8)
    end
  end
end