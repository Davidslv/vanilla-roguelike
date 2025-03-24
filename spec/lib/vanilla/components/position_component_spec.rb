# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Components::PositionComponent do
  describe '#initialize' do
    it 'sets row and column' do
      component = described_class.new(row: 5, column: 10)
      expect(component.row).to eq(5)
      expect(component.column).to eq(10)
    end
  end

  describe '#type' do
    it 'returns :position' do
      component = described_class.new(row: 0, column: 0)
      expect(component.type).to eq(:position)
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
end
