require 'spec_helper'

RSpec.describe Vanilla::MapUtils::CellTypeFactory do
  let(:factory) { described_class.new }

  describe '#initialize' do
    it 'sets up standard cell types' do
      expect(factory.get_cell_type(:empty)).to be_a(Vanilla::MapUtils::CellType)
      expect(factory.get_cell_type(:wall)).to be_a(Vanilla::MapUtils::CellType)
      expect(factory.get_cell_type(:player)).to be_a(Vanilla::MapUtils::CellType)
      expect(factory.get_cell_type(:stairs)).to be_a(Vanilla::MapUtils::CellType)
    end
  end

  describe '#get_cell_type' do
    it 'returns the requested cell type' do
      cell_type = factory.get_cell_type(:empty)
      expect(cell_type.key).to eq(:empty)
      expect(cell_type.tile_character).to eq(Vanilla::Support::TileType::EMPTY)
    end

    it 'raises an error for unknown cell types' do
      expect { factory.get_cell_type(:nonexistent) }.to raise_error(ArgumentError)
    end

    it 'returns the same instance for repeated requests' do
      cell_type1 = factory.get_cell_type(:wall)
      cell_type2 = factory.get_cell_type(:wall)
      expect(cell_type1).to be(cell_type2) # same object, not just equal
    end
  end

  describe '#get_by_character' do
    it 'returns the cell type matching the character' do
      cell_type = factory.get_by_character(Vanilla::Support::TileType::PLAYER)
      expect(cell_type.key).to eq(:player)
    end

    it 'returns the empty type for unknown characters' do
      cell_type = factory.get_by_character('X')
      expect(cell_type.key).to eq(:empty)
    end
  end

  describe '#register' do
    it 'adds a new cell type' do
      factory.register(:custom, 'X', walkable: true, custom: true)

      cell_type = factory.get_cell_type(:custom)
      expect(cell_type.key).to eq(:custom)
      expect(cell_type.tile_character).to eq('X')
      expect(cell_type.properties[:custom]).to eq(true)
    end

    it 'overwrites an existing cell type with the same key' do
      factory.register(:wall, '+', walkable: true)

      cell_type = factory.get_cell_type(:wall)
      expect(cell_type.tile_character).to eq('+')
      expect(cell_type.walkable?).to eq(true)
    end
  end

  describe 'standard cell types' do
    it 'sets correct properties for wall' do
      wall = factory.get_cell_type(:wall)
      expect(wall.walkable?).to eq(false)
      expect(wall.tile_character).to eq(Vanilla::Support::TileType::WALL)
    end

    it 'sets correct properties for player' do
      player = factory.get_cell_type(:player)
      expect(player.player?).to eq(true)
      expect(player.walkable?).to eq(true)
      expect(player.tile_character).to eq(Vanilla::Support::TileType::PLAYER)
    end

    it 'sets correct properties for stairs' do
      stairs = factory.get_cell_type(:stairs)
      expect(stairs.stairs?).to eq(true)
      expect(stairs.walkable?).to eq(true)
      expect(stairs.tile_character).to eq(Vanilla::Support::TileType::STAIRS)
    end
  end
end
