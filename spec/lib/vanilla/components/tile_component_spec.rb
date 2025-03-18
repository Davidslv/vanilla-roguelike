require 'spec_helper'

RSpec.describe Vanilla::Components::TileComponent do
  describe '#initialize' do
    it 'sets tile character' do
      component = described_class.new(tile: '@')
      expect(component.tile).to eq('@')
    end

    it 'raises an error for invalid tile types' do
      expect { described_class.new(tile: 'invalid') }.to raise_error(ArgumentError)
    end

    it 'defaults to EMPTY tile' do
      component = described_class.new
      expect(component.tile).to eq(Vanilla::Support::TileType::EMPTY)
    end
  end

  describe '#type' do
    it 'returns :tile' do
      component = described_class.new
      expect(component.type).to eq(:tile)
    end
  end

  describe '#to_hash' do
    it 'serializes tile data' do
      component = described_class.new(tile: '@')
      hash = component.to_hash
      expect(hash[:type]).to eq(:tile)
      expect(hash[:tile]).to eq('@')
    end
  end

  describe '.from_hash' do
    it 'deserializes tile data' do
      hash = { type: :tile, tile: '@' }
      component = described_class.from_hash(hash)
      expect(component).to be_a(described_class)
      expect(component.tile).to eq('@')
    end
  end

  describe '#change_tile' do
    let(:component) { described_class.new(tile: Vanilla::Support::TileType::FLOOR) }

    it 'changes the tile character' do
      component.change_tile(Vanilla::Support::TileType::PLAYER)
      expect(component.tile).to eq(Vanilla::Support::TileType::PLAYER)
    end

    it 'raises an error for invalid tile types' do
      expect { component.change_tile('invalid') }.to raise_error(ArgumentError)
    end
  end
end