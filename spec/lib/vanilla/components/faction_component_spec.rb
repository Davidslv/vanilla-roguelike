# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Components::FactionComponent do
  describe '#initialize' do
    it 'sets faction_id and hostile_to' do
      component = described_class.new(faction_id: :hero, hostile_to: [:monster])
      expect(component.faction_id).to eq(:hero)
      expect(component.hostile_to).to eq(Set.new([:monster]))
    end

    it 'stores hostile_to as a Set (deduplicating entries)' do
      component = described_class.new(faction_id: :hero, hostile_to: [:monster, :monster, :undead])
      expect(component.hostile_to).to eq(Set.new([:monster, :undead]))
    end

    it 'defaults to a neutral faction hostile to nobody' do
      component = described_class.new
      expect(component.faction_id).to eq(:neutral)
      expect(component.hostile_to).to be_empty
    end
  end

  describe '#type' do
    it 'returns :faction' do
      expect(described_class.new.type).to eq(:faction)
    end
  end

  describe 'registration' do
    it 'is registered with the component registry' do
      expect(Vanilla::Components::Component.get_class(:faction)).to eq(described_class)
    end
  end

  describe '#to_hash' do
    it 'serializes faction data with its type' do
      component = described_class.new(faction_id: :hero, hostile_to: [:monster])
      hash = component.to_hash
      expect(hash[:type]).to eq(:faction)
      expect(hash[:faction_id]).to eq(:hero)
      expect(hash[:hostile_to]).to contain_exactly(:monster)
    end
  end

  describe '.from_hash' do
    it 'deserializes faction data' do
      hash = { type: :faction, faction_id: :hero, hostile_to: [:monster, :undead] }
      component = described_class.from_hash(hash)
      expect(component).to be_a(described_class)
      expect(component.faction_id).to eq(:hero)
      expect(component.hostile_to).to eq(Set.new([:monster, :undead]))
    end

    it 'tolerates missing fields by falling back to neutral defaults' do
      component = described_class.from_hash({ type: :faction })
      expect(component.faction_id).to eq(:neutral)
      expect(component.hostile_to).to be_empty
    end
  end

  describe 'round-trip serialization' do
    it 'preserves faction data through to_hash/from_hash' do
      original = described_class.new(faction_id: :hero, hostile_to: [:monster, :undead])
      restored = described_class.from_hash(original.to_hash)
      expect(restored.faction_id).to eq(original.faction_id)
      expect(restored.hostile_to).to eq(original.hostile_to)
    end
  end
end
