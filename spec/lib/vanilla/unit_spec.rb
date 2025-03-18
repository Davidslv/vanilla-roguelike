require 'spec_helper'

RSpec.describe Vanilla::Unit do
  let(:logger) { instance_double('Vanilla::Logger') }

  before do
    allow(Vanilla::Logger).to receive(:instance).and_return(logger)
    allow(logger).to receive(:warn)
  end

  describe '#initialize' do
    it 'logs a deprecation warning' do
      expect(logger).to receive(:warn).with(/DEPRECATED: Vanilla::Unit is deprecated/)

      described_class.new(row: 5, column: 10, tile: '@')
    end

    it 'sets initial properties' do
      unit = described_class.new(row: 5, column: 10, tile: '@')

      expect(unit.row).to eq(5)
      expect(unit.column).to eq(10)
      expect(unit.tile).to eq('@')
      expect(unit.found_stairs).to be false
    end
  end

  describe '#coordinates' do
    it 'logs a deprecation warning' do
      unit = described_class.new(row: 5, column: 10, tile: '@')

      expect(logger).to receive(:warn).with(/DEPRECATED: Vanilla::Unit#coordinates is deprecated/)

      unit.coordinates
    end

    it 'returns [row, column]' do
      unit = described_class.new(row: 5, column: 10, tile: '@')

      expect(unit.coordinates).to eq([5, 10])
    end
  end

  describe '#found_stairs?' do
    it 'is an alias for found_stairs' do
      unit = described_class.new(row: 5, column: 10, tile: '@')
      unit.found_stairs = true

      expect(unit.found_stairs?).to be true
    end
  end
end