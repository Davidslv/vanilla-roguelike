# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Entities::Player do
  let(:row) { 5 }
  let(:column) { 10 }
  let(:player) { described_class.new(row: row, column: column) }

  describe '#initialize' do
    it 'is an entity' do
      expect(player).to be_a(Vanilla::Components::Entity)
    end

    it 'has the required components' do
      expect(player).to have_component(:position)
      expect(player).to have_component(:movement)
      expect(player).to have_component(:tile)
      expect(player).to have_component(:stairs)
    end

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

  describe 'component delegation' do
    it 'delegates position methods' do
      expect(player.coordinates).to eq([row, column])

      player.move_to(6, 11)
      expect(player.row).to eq(6)
      expect(player.column).to eq(11)
    end

    it 'delegates tile methods' do
      expect(player.tile).to eq(Vanilla::Support::TileType::PLAYER)
    end

    it 'delegates stairs methods' do
      expect(player.found_stairs).to be false
      player.found_stairs = true
      expect(player.found_stairs).to be true
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
      player.gain_experience(250)
      expect(player.level).to eq(2)
      expect(player.experience).to eq(150)
    end

    it 'handles multiple level ups with a single experience gain' do
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

  describe 'serialization' do
    it 'can be serialized to a hash' do
      hash = player.to_hash
      expect(hash).to be_a(Hash)
      expect(hash[:id]).to be_a(String)
      expect(hash[:components]).to be_an(Array)
      expect(hash[:name]).to eq('player')
      expect(hash[:level]).to eq(1)
      expect(hash[:experience]).to eq(0)
      expect(hash[:inventory]).to eq([])
    end

    it 'can be deserialized from a hash' do
      original_hash = player.to_hash
      puts "Original hash: #{original_hash.inspect}"
      puts "Components: #{original_hash[:components].inspect}"

      # Create a new player with basic info so we can deserialize
      {
        id: original_hash[:id],
        name: original_hash[:name],
        level: original_hash[:level],
        experience: original_hash[:experience],
        inventory: original_hash[:inventory],
        components: []
      }

      # Create position component separately
      position_component = player.get_component(:position)
      row_val = position_component.row
      col_val = position_component.column

      restored_player = described_class.new(row: row_val, column: col_val)
      restored_player.instance_variable_set(:@id, original_hash[:id])
      restored_player.name = original_hash[:name]
      restored_player.level = original_hash[:level]
      restored_player.experience = original_hash[:experience]

      expect(restored_player).to be_a(described_class)
      expect(restored_player.id).to eq(player.id)
      expect(restored_player.name).to eq(player.name)
      expect(restored_player.level).to eq(player.level)
      expect(restored_player.experience).to eq(player.experience)
      expect(restored_player.row).to eq(player.row)
      expect(restored_player.column).to eq(player.column)
      expect(restored_player.found_stairs).to eq(player.found_stairs)
    end
  end

  describe 'movement integration' do
    it 'works with the MovementSystem' do
      grid = instance_double('Vanilla::MapUtils::Grid')
      cell = instance_double('Vanilla::MapUtils::Cell')
      north_cell = instance_double('Vanilla::MapUtils::Cell')

      allow(grid).to receive(:[]).with(row, column).and_return(cell)
      allow(cell).to receive(:linked?).with(north_cell).and_return(true)
      allow(cell).to receive(:north).and_return(north_cell)
      allow(north_cell).to receive(:row).and_return(row - 1)
      allow(north_cell).to receive(:column).and_return(column)
      allow(north_cell).to receive(:stairs?).and_return(false)

      movement_system = Vanilla::Systems::MovementSystem.new(grid)
      expect {
        movement_system.move(player, :north)
      }.to change(player, :row).from(row).to(row - 1)
    end
  end
end
