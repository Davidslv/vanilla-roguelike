# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Factions do
  # Build a bare entity optionally carrying a FactionComponent.
  def entity_with_faction(faction_id: nil, hostile_to: [])
    Vanilla::Entities::Entity.new.tap do |entity|
      next if faction_id.nil?

      entity.add_component(
        Vanilla::Components::FactionComponent.new(faction_id: faction_id, hostile_to: hostile_to)
      )
    end
  end

  let(:hero)    { entity_with_faction(faction_id: described_class::HERO, hostile_to: [described_class::MONSTER]) }
  let(:monster) { entity_with_faction(faction_id: described_class::MONSTER, hostile_to: [described_class::HERO]) }
  let(:ally)    { entity_with_faction(faction_id: described_class::HERO, hostile_to: [described_class::MONSTER]) }
  let(:neutral) { entity_with_faction(faction_id: described_class::NEUTRAL) }
  let(:factionless) { entity_with_faction(faction_id: nil) }

  describe '.hostile?' do
    it 'is true when the attacker faction lists the target faction as hostile' do
      expect(described_class.hostile?(hero, monster)).to be true
    end

    it 'is reciprocal when both factions list each other as hostile' do
      expect(described_class.hostile?(monster, hero)).to be true
    end

    it 'is false between members of the same faction' do
      expect(described_class.hostile?(hero, ally)).to be false
    end

    it 'is false toward a neutral faction nobody declared hostile' do
      expect(described_class.hostile?(hero, neutral)).to be false
    end

    it 'is false when either entity lacks a faction component' do
      expect(described_class.hostile?(hero, factionless)).to be false
      expect(described_class.hostile?(factionless, hero)).to be false
    end

    it 'is false when either entity is nil' do
      expect(described_class.hostile?(hero, nil)).to be false
      expect(described_class.hostile?(nil, monster)).to be false
    end
  end

  describe '.allies?' do
    it 'is true for entities sharing a faction' do
      expect(described_class.allies?(hero, ally)).to be true
    end

    it 'is false for entities in different factions' do
      expect(described_class.allies?(hero, monster)).to be false
    end

    it 'is false when either entity lacks a faction component' do
      expect(described_class.allies?(hero, factionless)).to be false
    end

    it 'is false when either entity is nil' do
      expect(described_class.allies?(nil, hero)).to be false
    end
  end
end
