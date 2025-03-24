require 'spec_helper'

RSpec.describe Vanilla::Level do
  let(:rows) { 10 }
  let(:columns) { 10 }
  let(:difficulty) { 2 }
  let(:seed) { 12345 }

  describe '#initialize' do
    it 'stores the difficulty value' do
      allow_any_instance_of(described_class).to receive(:update_grid_with_entities)

      level = described_class.new(rows: rows, columns: columns, difficulty: difficulty, seed: seed)
      expect(level.difficulty).to eq(difficulty)
    end

    it 'creates a player entity' do
      allow_any_instance_of(described_class).to receive(:update_grid_with_entities)

      level = described_class.new(rows: rows, columns: columns, difficulty: difficulty, seed: seed)
      expect(level.player).to be_a(Vanilla::Entities::Player)
    end

    it 'creates a stairs entity' do
      allow_any_instance_of(described_class).to receive(:update_grid_with_entities)

      level = described_class.new(rows: rows, columns: columns, difficulty: difficulty, seed: seed)
      expect(level.stairs).to be_a(Vanilla::Entities::Stairs)
    end
  end

  describe '.random' do
    before do
      allow_any_instance_of(described_class).to receive(:update_grid_with_entities)
    end

    it 'scales level size based on difficulty' do
      level = instance_double(described_class, grid: instance_double('Grid', rows: 10, columns: 10), difficulty: 3)
      allow(described_class).to receive(:new).and_return(level)

      [1, 3, 5].each do |diff|
        expect(described_class).to receive(:new).with(hash_including(difficulty: diff))
        described_class.random(difficulty: diff)
      end
    end

    it 'returns a valid level instance' do
      level = instance_double(described_class, grid: instance_double('Grid', rows: 10, columns: 10), difficulty: difficulty)
      allow(described_class).to receive(:new).and_return(level)

      result = described_class.random(difficulty: difficulty)
      expect(result).to eq(level)
    end
  end

  describe '#all_entities' do
    let(:player) { instance_double('Vanilla::Entities::Player') }
    let(:stairs) { instance_double('Vanilla::Entities::Stairs') }
    let(:level) do
      allow_any_instance_of(described_class).to receive(:initialize)
      level = described_class.allocate
      level.instance_variable_set(:@player, player)
      level.instance_variable_set(:@stairs, stairs)
      level
    end

    it 'returns player and stairs entities' do
      entities = level.all_entities
      expect(entities).to include(player)
      expect(entities).to include(stairs)
      expect(entities.size).to eq(2)
    end
  end
end
