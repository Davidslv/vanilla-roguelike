require 'spec_helper'

RSpec.describe Vanilla::Systems::MonsterSystem do
  let(:rows) { 10 }
  let(:columns) { 10 }
  let(:grid) { Vanilla::MapUtils::Grid.new(rows: rows, columns: columns) }
  let(:player) { Vanilla::Entities::Player.new(row: 1, column: 1) }

  # Make sure grid has walkable cells for monsters
  before do
    grid.each_cell do |cell|
      cell.tile = Vanilla::Support::TileType::EMPTY
    end
  end

  subject { described_class.new(grid: grid, player: player) }

  describe '#initialize' do
    it 'initializes with a grid and player' do
      expect(subject.monsters).to be_empty
    end
  end

  describe '#spawn_monsters' do
    it 'spawns monsters based on level difficulty' do
      subject.spawn_monsters(1)
      expect(subject.monsters.count).to be > 0
      expect(subject.monsters.count).to be <= 2 # Level 1 max is 2
    end

    it 'spawns more monsters at higher difficulties' do
      subject.spawn_monsters(3)
      expect(subject.monsters.count).to be > 0
      expect(subject.monsters.count).to be <= 6 # Level 3 max is 6
    end

    it 'places monsters on walkable cells' do
      subject.spawn_monsters(1)
      subject.monsters.each do |monster|
        pos = monster.get_component(:position)
        cell = grid[pos.row, pos.column]
        expect(cell).not_to be_nil
        expect(cell.tile).to eq(Vanilla::Support::TileType::MONSTER)
      end
    end
  end

  describe '#update' do
    before do
      # Place a monster at a specific location
      subject.spawn_monsters(1)
      monster = subject.monsters.first
      position = monster.get_component(:position)
      position.row = 5
      position.column = 5
      grid[5, 5].tile = Vanilla::Support::TileType::MONSTER
    end

    it 'updates monster positions', skip: 'Skipping due to movement component not being implemented' do
      # Count monsters before update
      monster_count_before = subject.monsters.count

      # Store original positions
      original_positions = subject.monsters.map do |monster|
        pos = monster.get_component(:position)
        [pos.row, pos.column]
      end

      # Force monsters to move by placing player nearby
      player_pos = player.get_component(:position)
      player_pos.row = 6
      player_pos.column = 6

      # Allow multiple updates to ensure movement happens
      5.times { subject.update }

      # Check that monsters still exist
      expect(subject.monsters.count).to eq(monster_count_before)

      # Check if at least one monster has moved
      current_positions = subject.monsters.map do |monster|
        pos = monster.get_component(:position)
        [pos.row, pos.column]
      end

      expect(current_positions).not_to eq(original_positions)
    end
  end

  describe '#monster_at' do
    before do
      # Place a monster at a specific location
      monster = Vanilla::Entities::Monster.new(row: 3, column: 4)
      grid[3, 4].tile = Vanilla::Support::TileType::MONSTER
      subject.instance_variable_set(:@monsters, [monster])
    end

    it 'returns the monster at the given position' do
      monster = subject.monster_at(3, 4)
      expect(monster).not_to be_nil
      position = monster.get_component(:position)
      expect(position.row).to eq(3)
      expect(position.column).to eq(4)
    end

    it 'returns nil if no monster at the position' do
      expect(subject.monster_at(0, 0)).to be_nil
    end
  end
end
