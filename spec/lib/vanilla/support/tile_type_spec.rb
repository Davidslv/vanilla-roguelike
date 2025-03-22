require 'spec_helper'

RSpec.describe Vanilla::Support::TileType do
  describe '.values' do
    it 'returns all the defined tile values' do
      expect(described_class.values).to eq([
        ' ',  # EMPTY
        '#',  # WALL
        '/',  # DOOR
        '.',  # FLOOR
        '@',  # PLAYER
        'M',  # MONSTER
        '%',  # STAIRS
        '|',  # VERTICAL_WALL
        '$'   # GOLD
      ])
    end
  end

  describe '.valid?' do
    context 'with valid tiles' do
      it 'returns true for all defined tile types' do
        described_class.values.each do |tile|
          expect(described_class.valid?(tile)).to be true
        end
      end
    end

    context 'with invalid tiles' do
      it 'returns false for undefined tile types' do
        invalid_tiles = ['x', 'A', '1', '?', '*']

        invalid_tiles.each do |tile|
          expect(described_class.valid?(tile)).to be false
        end
      end
    end
  end

  describe '.walkable?' do
    it 'returns true for walkable tiles' do
      walkable_tiles = [
        described_class::EMPTY,
        described_class::FLOOR,
        described_class::DOOR,
        described_class::STAIRS,
      ]

      walkable_tiles.each do |tile|
        expect(described_class.walkable?(tile)).to be true
      end
    end

    it 'returns false for non-walkable tiles' do
      non_walkable_tiles = [
        described_class::WALL,
        described_class::VERTICAL_WALL,
        described_class::PLAYER
      ]

      non_walkable_tiles.each do |tile|
        expect(described_class.walkable?(tile)).to be false
      end
    end

    it 'returns false for invalid tiles' do
      expect(described_class.walkable?('X')).to be false
    end
  end

  describe '.wall?' do
    it 'returns true for wall tiles' do
      wall_tiles = [
        described_class::WALL,
        described_class::VERTICAL_WALL
      ]

      wall_tiles.each do |tile|
        expect(described_class.wall?(tile)).to be(true)
      end
    end

    it 'returns false for non-wall tiles' do
      non_wall_tiles = [
        described_class::EMPTY,
        described_class::FLOOR,
        described_class::DOOR,
        described_class::STAIRS,
        described_class::PLAYER
      ]

      non_wall_tiles.each do |tile|
        expect(described_class.wall?(tile)).to be(false)
      end
    end

    it 'returns false for invalid tiles' do
      expect(described_class.wall?('X')).to be false
    end
  end
end