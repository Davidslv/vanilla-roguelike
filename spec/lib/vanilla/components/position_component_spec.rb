require 'spec_helper'

RSpec.describe Vanilla::Components::PositionComponent do
  describe '#initialize' do
    it 'initializes with default values when no parameters are provided' do
      component = Vanilla::Components::PositionComponent.new
      expect(component.row).to eq(0)
      expect(component.column).to eq(0)
    end

    it 'initializes with provided values' do
      component = Vanilla::Components::PositionComponent.new(row: 5, column: 10)
      expect(component.row).to eq(5)
      expect(component.column).to eq(10)
    end
  end

  describe '#type' do
    it 'returns the correct component type' do
      component = Vanilla::Components::PositionComponent.new
      expect(component.type).to eq(:position)
    end
  end

  describe '#coordinates' do
    it 'returns the position as an array' do
      component = Vanilla::Components::PositionComponent.new(row: 3, column: 7)
      expect(component.coordinates).to eq([3, 7])
    end
  end

  describe '#set_position' do
    it 'updates the position' do
      component = Vanilla::Components::PositionComponent.new(row: 1, column: 2)
      component.set_position(3, 4)
      expect(component.row).to eq(3)
      expect(component.column).to eq(4)
    end
  end

  describe '#translate' do
    it 'moves the position by the specified deltas' do
      component = Vanilla::Components::PositionComponent.new(row: 5, column: 5)
      component.translate(2, -3)
      expect(component.row).to eq(7)
      expect(component.column).to eq(2)
    end

    it 'handles negative values correctly' do
      component = Vanilla::Components::PositionComponent.new(row: 5, column: 5)
      component.translate(-3, -2)
      expect(component.row).to eq(2)
      expect(component.column).to eq(3)
    end
  end

  describe '#move_to' do
    it 'calls set_position' do
      component = Vanilla::Components::PositionComponent.new
      expect(component).to receive(:set_position).with(7, 8)
      component.move_to(7, 8)
    end
  end

  describe '#move_by' do
    it 'calls translate' do
      component = Vanilla::Components::PositionComponent.new
      expect(component).to receive(:translate).with(2, 3)
      component.move_by(2, 3)
    end
  end

  describe '#data' do
    it 'returns a hash with the component data' do
      component = Vanilla::Components::PositionComponent.new(row: 3, column: 7)
      expect(component.data).to eq({ row: 3, column: 7 })
    end
  end

  describe '.from_hash' do
    it 'creates a component from a hash' do
      hash = { row: 5, column: 9 }
      component = Vanilla::Components::PositionComponent.from_hash(hash)
      expect(component.row).to eq(5)
      expect(component.column).to eq(9)
    end

    it 'handles missing values' do
      hash = { row: 5 }
      component = Vanilla::Components::PositionComponent.from_hash(hash)
      expect(component.row).to eq(5)
      expect(component.column).to eq(0)
    end
  end
end