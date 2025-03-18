require 'spec_helper'

RSpec.describe Vanilla::Characters::Player do
  let(:row) { 5 }
  let(:column) { 10 }
  let(:logger) { instance_double('Vanilla::Logger') }

  before do
    allow(Vanilla::Logger).to receive(:instance).and_return(logger)
    allow(logger).to receive(:warn)
    allow(logger).to receive(:debug)
    allow(logger).to receive(:info)
  end

  describe '#initialize' do
    it 'logs a deprecation warning' do
      expect(logger).to receive(:warn).with(/DEPRECATED: Vanilla::Characters::Player is deprecated/)

      described_class.new(row: row, column: column)
    end

    it 'sets default attributes' do
      allow(logger).to receive(:warn)
      player = described_class.new(row: row, column: column)

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
      allow(logger).to receive(:warn)
      custom_player = described_class.new(name: 'hero', row: row, column: column)
      expect(custom_player.name).to eq('hero')
    end
  end

  describe 'movement methods' do
    let(:player) do
      allow(logger).to receive(:warn)
      described_class.new(row: row, column: column)
    end

    it 'logs deprecation warnings when movement methods are called' do
      expect(logger).to receive(:warn).with(/DEPRECATED: Vanilla::Characters::Player#move is deprecated/)
      player.move(:left)
    end
  end

  describe 'other methods' do
    let(:player) do
      allow(logger).to receive(:warn)
      described_class.new(row: row, column: column)
    end

    it 'still supports gaining experience' do
      player.gain_experience(50)
      expect(player.experience).to eq(50)
    end

    it 'still supports leveling up' do
      player.gain_experience(100)
      expect(player.level).to eq(2)
      expect(player.experience).to eq(0)
    end

    it 'still supports inventory management' do
      item = double('Item')
      player.add_to_inventory(item)
      expect(player.inventory).to include(item)

      player.remove_from_inventory(item)
      expect(player.inventory).not_to include(item)
    end
  end
end



