# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Components::CombatComponent do
  describe '#initialize' do
    it 'sets attack_power, defense, and accuracy' do
      component = described_class.new(attack_power: 10, defense: 2, accuracy: 0.8)
      expect(component.attack_power).to eq(10)
      expect(component.defense).to eq(2)
      expect(component.accuracy).to eq(0.8)
    end

    it 'defaults accuracy to 0.8' do
      component = described_class.new(attack_power: 10, defense: 2)
      expect(component.accuracy).to eq(0.8)
    end

    it 'validates accuracy is between 0.0 and 1.0' do
      expect do
        described_class.new(attack_power: 10, defense: 2, accuracy: 1.5)
      end.to raise_error(ArgumentError, /accuracy must be between 0.0 and 1.0/)

      expect do
        described_class.new(attack_power: 10, defense: 2, accuracy: -0.1)
      end.to raise_error(ArgumentError, /accuracy must be between 0.0 and 1.0/)
    end

    it 'allows accuracy at boundaries' do
      component_min = described_class.new(attack_power: 10, defense: 2, accuracy: 0.0)
      expect(component_min.accuracy).to eq(0.0)

      component_max = described_class.new(attack_power: 10, defense: 2, accuracy: 1.0)
      expect(component_max.accuracy).to eq(1.0)
    end
  end

  describe '#type' do
    it 'returns :combat' do
      component = described_class.new(attack_power: 10, defense: 2)
      expect(component.type).to eq(:combat)
    end
  end

  describe '#to_hash' do
    it 'serializes component data' do
      component = described_class.new(attack_power: 10, defense: 2, accuracy: 0.85)
      hash = component.to_hash
      expect(hash[:type]).to eq(:combat)
      expect(hash[:attack_power]).to eq(10)
      expect(hash[:defense]).to eq(2)
      expect(hash[:accuracy]).to eq(0.85)
    end
  end

  describe '.from_hash' do
    it 'deserializes component data' do
      hash = { type: :combat, attack_power: 10, defense: 2, accuracy: 0.85 }
      component = described_class.from_hash(hash)
      expect(component).to be_a(described_class)
      expect(component.attack_power).to eq(10)
      expect(component.defense).to eq(2)
      expect(component.accuracy).to eq(0.85)
    end

    it 'defaults accuracy when not in hash' do
      hash = { type: :combat, attack_power: 10, defense: 2 }
      component = described_class.from_hash(hash)
      expect(component.accuracy).to eq(0.8)
    end
  end
end

