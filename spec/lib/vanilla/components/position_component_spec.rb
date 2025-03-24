# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Vanilla::Components::PositionComponent do
  describe '#initialize' do
    it 'sets row and column' do
      component = described_class.new(row: 5, column: 10)
      expect(component.row).to eq(5)
      expect(component.column).to eq(10)
    end

    it 'defaults row and column to 0' do
      component = described_class.new
      expect(component.row).to eq(0)
      expect(component.column).to eq(0)
    end
  end

  describe '#type' do
    it 'returns :position' do
      component = described_class.new
      expect(component.type).to eq(:position)
    end
  end

  describe '#coordinates' do
    it 'returns [row, column]' do
      component = described_class.new(row: 5, column: 10)
      expect(component.coordinates).to eq([5, 10])
    end
  end

  describe '#to_hash' do
    it 'serializes position data' do
      component = described_class.new(row: 5, column: 10)
      hash = component.to_hash
      expect(hash[:type]).to eq(:position)
      expect(hash[:row]).to eq(5)
      expect(hash[:column]).to eq(10)
    end
  end

  describe '.from_hash' do
    it 'deserializes position data' do
      hash = { type: :position, row: 5, column: 10 }
      component = described_class.from_hash(hash)
      expect(component).to be_a(described_class)
      expect(component.row).to eq(5)
      expect(component.column).to eq(10)
    end
  end

  describe '#set_position' do
    let(:component) { described_class.new(row: 5, column: 10) }

    it 'sets the absolute position' do
      component.set_position(7, 12)
      expect(component.row).to eq(7)
      expect(component.column).to eq(12)
    end
  end

  describe '#translate' do
    let(:component) { described_class.new(row: 5, column: 10) }

    it 'moves the position by the given deltas' do
      component.translate(2, -3)
      expect(component.row).to eq(7)
      expect(component.column).to eq(7)
    end
  end

  describe 'backward compatibility' do
    let(:component) { described_class.new(row: 5, column: 10) }

    describe '#move_to' do
      it 'still works by calling set_position' do
        expect(component).to receive(:set_position).with(7, 12)
        component.move_to(7, 12)
      end
    end

    describe '#move_by' do
      it 'still works by calling translate' do
        expect(component).to receive(:translate).with(2, -3)
        component.move_by(2, -3)
      end
    end
  end

  describe 'encapsulation' do
    let(:component) { described_class.new(row: 5, column: 10) }

    it 'does not allow direct setting of row and column' do
      expect(component).to respond_to(:row)
      expect(component).to respond_to(:column)
      expect(component).not_to respond_to(:row=)
      expect(component).not_to respond_to(:column=)
    end

    it 'requires using set_position to change position' do
      component.set_position(7, 12)
      expect(component.row).to eq(7)
      expect(component.column).to eq(12)
    end
  end
end
