# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Components::HealthComponent do
  describe '#initialize' do
    it 'sets max_health and current_health' do
      component = described_class.new(max_health: 100)
      expect(component.max_health).to eq(100)
      expect(component.current_health).to eq(100)
    end

    it 'sets current_health to max_health when not specified' do
      component = described_class.new(max_health: 50)
      expect(component.current_health).to eq(50)
    end

    it 'accepts custom current_health' do
      component = described_class.new(max_health: 100, current_health: 75)
      expect(component.current_health).to eq(75)
    end

    it 'caps current_health at max_health' do
      component = described_class.new(max_health: 100, current_health: 150)
      expect(component.current_health).to eq(100)
    end
  end

  describe '#type' do
    it 'returns :health' do
      component = described_class.new(max_health: 100)
      expect(component.type).to eq(:health)
    end
  end

  describe '#current_health=' do
    it 'sets current_health to the given value' do
      component = described_class.new(max_health: 100)
      component.current_health = 50
      expect(component.current_health).to eq(50)
    end

    it 'caps current_health at max_health' do
      component = described_class.new(max_health: 100)
      component.current_health = 150
      expect(component.current_health).to eq(100)
    end

    it 'allows setting health below max' do
      component = described_class.new(max_health: 100)
      component.current_health = 25
      expect(component.current_health).to eq(25)
    end

    it 'allows setting health to 0' do
      component = described_class.new(max_health: 100)
      component.current_health = 0
      expect(component.current_health).to eq(0)
    end
  end

  describe '#to_hash' do
    it 'serializes component to hash' do
      component = described_class.new(max_health: 100, current_health: 75)
      hash = component.to_hash
      expect(hash).to eq({ max_health: 100, current_health: 75 })
    end
  end

  describe '.from_hash' do
    it 'deserializes component from hash' do
      hash = { max_health: 100, current_health: 75 }
      component = described_class.from_hash(hash)
      expect(component.max_health).to eq(100)
      expect(component.current_health).to eq(75)
    end

    it 'handles missing current_health in hash' do
      hash = { max_health: 100 }
      component = described_class.from_hash(hash)
      expect(component.max_health).to eq(100)
      expect(component.current_health).to eq(100) # Defaults to max_health
    end
  end
end

