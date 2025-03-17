require 'spec_helper'

RSpec.describe Vanilla::Characters::Player do
  let(:row) { 5 }
  let(:column) { 10 }
  let(:player) { described_class.new(row: row, column: column) }

  describe '#initialize' do
    it 'sets default attributes' do
      expect(player.name).to eq('player')
      expect(player.level).to eq(1)
      expect(player.experience).to eq(0)
      expect(player.inventory).to be_empty
      expect(player.row).to eq(row)
      expect(player.column).to eq(column)
      expect(player.tile).to eq(Vanilla::Support::TileType::PLAYER)
      expect(player.found_stairs).to be false
    end

    it 'can be initialized with a custom name' do
      custom_player = described_class.new(name: 'hero', row: row, column: column)
      expect(custom_player.name).to eq('hero')
    end
  end

  describe '#found_stairs?' do
    it 'returns false by default' do
      expect(player.found_stairs?).to be false
    end

    it 'returns true when found_stairs is set to true' do
      player.found_stairs = true
      expect(player.found_stairs?).to be true
    end
  end

  describe '#gain_experience' do
    it 'increases experience by the given amount' do
      player.gain_experience(50)
      expect(player.experience).to eq(50)
    end

    it 'does not level up if experience is below threshold' do
      player.gain_experience(99)
      expect(player.level).to eq(1)
      expect(player.experience).to eq(99)
    end

    it 'levels up when experience reaches threshold' do
      player.gain_experience(100)
      expect(player.level).to eq(2)
      expect(player.experience).to eq(0)
    end

    it 'handles experience that exceeds level threshold' do
      # If we gain 250 XP at level 1:
      # - Need 100 XP to reach level 2, leaving 150 XP remaining
      # - At level 2, need 200 XP to reach level 3
      # - So we stay at level 2 with 150 XP
      player.gain_experience(250)
      expect(player.level).to eq(2)
      expect(player.experience).to eq(150)
    end

    it 'handles multiple level ups with a single experience gain' do
      # If we gain 350 XP at level 1:
      # - Need 100 XP to reach level 2, leaving 250 XP remaining
      # - Need 200 XP to reach level 3, leaving 50 XP remaining
      # - So we end at level 3 with 50 XP
      player.gain_experience(350)
      expect(player.level).to eq(3)
      expect(player.experience).to eq(50)
    end
  end

  describe '#level_up' do
    it 'increases level by 1' do
      initial_level = player.level
      player.level_up
      expect(player.level).to eq(initial_level + 1)
    end

    it 'subtracts the experience needed for the current level' do
      # At level 1, XP to level is 100
      player.experience = 150
      original_xp = player.experience
      original_xp_to_level = player.send(:experience_to_next_level)

      player.level_up
      expect(player.experience).to eq(original_xp - original_xp_to_level)
    end
  end

  describe '#add_to_inventory' do
    it 'adds an item to the inventory' do
      item = double('Item')
      player.add_to_inventory(item)
      expect(player.inventory).to include(item)
    end
  end

  describe '#remove_from_inventory' do
    it 'removes an item from the inventory' do
      item = double('Item')
      player.add_to_inventory(item)
      player.remove_from_inventory(item)
      expect(player.inventory).not_to include(item)
    end

    it 'does nothing if the item is not in inventory' do
      item = double('Item')
      other_item = double('OtherItem')
      player.add_to_inventory(item)

      expect { player.remove_from_inventory(other_item) }.not_to change(player, :inventory)
    end
  end

  describe 'coordinates' do
    it 'returns the row and column as an array' do
      expect(player.coordinates).to eq([row, column])
    end
  end

  describe 'movement integration' do
    it 'can be moved through the Vanilla::Movement module' do
      grid = instance_double('Vanilla::MapUtils::Grid')
      cell = instance_double('Vanilla::MapUtils::Cell')
      north_cell = instance_double('Vanilla::MapUtils::Cell')

      allow(grid).to receive(:[]).with(row, column).and_return(cell)
      allow(cell).to receive(:linked?).with(north_cell).and_return(true)
      allow(cell).to receive(:north).and_return(north_cell)
      allow(north_cell).to receive(:stairs?).and_return(false)
      allow(north_cell).to receive(:row).and_return(row - 1)
      allow(north_cell).to receive(:column).and_return(column)
      allow(cell).to receive(:tile=)
      allow(north_cell).to receive(:tile=)

      expect {
        Vanilla::Movement.move_up(cell, player)
      }.to change(player, :row).from(row).to(row - 1)
    end

    it 'sets found_stairs to true when moving to stairs' do
      grid = instance_double('Vanilla::MapUtils::Grid')
      cell = instance_double('Vanilla::MapUtils::Cell')
      east_cell = instance_double('Vanilla::MapUtils::Cell')

      allow(grid).to receive(:[]).with(row, column).and_return(cell)
      allow(cell).to receive(:linked?).with(east_cell).and_return(true)
      allow(cell).to receive(:east).and_return(east_cell)
      allow(east_cell).to receive(:stairs?).and_return(true)
      allow(east_cell).to receive(:row).and_return(row)
      allow(east_cell).to receive(:column).and_return(column + 1)
      allow(cell).to receive(:tile=)
      allow(east_cell).to receive(:tile=)

      expect {
        Vanilla::Movement.move_right(cell, player)
      }.to change(player, :found_stairs).from(false).to(true)
    end
  end
end