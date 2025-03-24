# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::MapUtils::CellType do
  describe '#initialize' do
    it 'sets key, tile_character and properties' do
      properties = { walkable: false, stairs: true }
      cell_type = described_class.new(:test, '@', properties)

      expect(cell_type.key).to eq(:test)
      expect(cell_type.tile_character).to eq('@')
      expect(cell_type.properties).to eq(properties)
    end

    it 'freezes the properties hash' do
      properties = { walkable: true }
      cell_type = described_class.new(:test, '.', properties)

      expect(cell_type.properties).to be_frozen
    end
  end

  describe '#walkable?' do
    it 'returns true when property is true' do
      cell_type = described_class.new(:test, '.', walkable: true)
      expect(cell_type.walkable?).to eq(true)
    end

    it 'returns false when property is false' do
      cell_type = described_class.new(:test, '#', walkable: false)
      expect(cell_type.walkable?).to eq(false)
    end

    it 'defaults to true when property is not set' do
      cell_type = described_class.new(:test, '.')
      expect(cell_type.walkable?).to eq(true)
    end
  end

  describe '#stairs?' do
    it 'returns true when property is true' do
      cell_type = described_class.new(:test, '%', stairs: true)
      expect(cell_type.stairs?).to eq(true)
    end

    it 'returns false when property is false' do
      cell_type = described_class.new(:test, '.', stairs: false)
      expect(cell_type.stairs?).to eq(false)
    end

    it 'defaults to false when property is not set' do
      cell_type = described_class.new(:test, '.')
      expect(cell_type.stairs?).to eq(false)
    end
  end

  describe '#player?' do
    it 'returns true when property is true' do
      cell_type = described_class.new(:test, '@', player: true)
      expect(cell_type.player?).to eq(true)
    end

    it 'returns false when property is false' do
      cell_type = described_class.new(:test, '.', player: false)
      expect(cell_type.player?).to eq(false)
    end

    it 'defaults to false when property is not set' do
      cell_type = described_class.new(:test, '.')
      expect(cell_type.player?).to eq(false)
    end
  end

  describe '#to_s' do
    it 'returns the tile character' do
      cell_type = described_class.new(:test, '@')
      expect(cell_type.to_s).to eq('@')
    end
  end
end
