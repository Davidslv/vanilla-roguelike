require 'spec_helper'

RSpec.describe Vanilla::Components::MovementComponent do
  describe '#initialize' do
    it 'sets default speed and movement directions' do
      component = described_class.new
      expect(component.speed).to eq(1)
      expect(component.can_move_directions).to eq([:north, :south, :east, :west])
    end

    it 'allows custom speed to be set' do
      component = described_class.new(speed: 2)
      expect(component.speed).to eq(2)
    end

    it 'allows custom movement directions to be set' do
      component = described_class.new(can_move_directions: [:north, :south])
      expect(component.can_move_directions).to eq([:north, :south])
    end
  end

  describe '#type' do
    it 'returns :movement' do
      component = described_class.new
      expect(component.type).to eq(:movement)
    end
  end

  describe '#data' do
    it 'serializes movement data' do
      component = described_class.new(speed: 2, can_move_directions: [:north, :east])

      data = component.data
      expect(data[:speed]).to eq(2)
      expect(data[:can_move_directions]).to eq([:north, :east])
    end
  end

  describe '.from_hash' do
    it 'deserializes movement data' do
      hash = {
        type: :movement,
        speed: 3,
        can_move_directions: [:south, :west]
      }

      component = described_class.from_hash(hash)
      expect(component).to be_a(described_class)
      expect(component.speed).to eq(3)
      expect(component.can_move_directions).to eq([:south, :west])
    end

    it 'handles defaults when values are missing from hash' do
      hash = { type: :movement }

      component = described_class.from_hash(hash)
      expect(component.speed).to eq(1)
      expect(component.can_move_directions).to eq([:north, :south, :east, :west])
    end
  end

  describe 'registration' do
    it 'registers itself with the Component registry' do
      expect(Vanilla::Components::Component.component_classes[:movement]).to eq(described_class)
    end
  end
end