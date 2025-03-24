# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Map do
  let(:rows) { 8 }
  let(:columns) { 10 }
  let(:algorithm) { Vanilla::Algorithms::BinaryTree }
  let(:seed) { 12345 }
  let(:map) { described_class.new(rows: rows, columns: columns, algorithm: algorithm, seed: seed) }

  describe '#initialize' do
    it 'sets up the correct seed' do
      # We need to save and restore the global seed since the Map class sets it
      original_seed = $seed

      map # Initialize the map
      expect($seed).to eq(seed)

      # Restore original seed to avoid affecting other tests
      $seed = original_seed
    end

    it 'properly stores rows, columns and algorithm' do
      expect(map.instance_variable_get(:@rows)).to eq(rows)
      expect(map.instance_variable_get(:@columns)).to eq(columns)
      expect(map.instance_variable_get(:@algorithm)).to eq(algorithm)
    end

    it 'generates a random seed when none is provided' do
      original_seed = $seed

      # Use a higher-order mock to capture the random seed
      allow(Random).to receive(:new).and_call_original

      map_with_random_seed = described_class.new(rows: rows, columns: columns, algorithm: algorithm)

      # Verify seed was set to something
      expect($seed).not_to be_nil

      # Restore original seed
      $seed = original_seed
    end
  end

  describe '.create' do
    it 'returns a grid with the correct dimensions' do
      grid = described_class.create(rows: rows, columns: columns, algorithm: algorithm, seed: seed)

      expect(grid.rows).to eq(rows)
      expect(grid.columns).to eq(columns)
    end

    it 'applies the specified algorithm to the grid' do
      # Create a spy algorithm to verify it's called with the grid
      spy_algorithm = spy('Algorithm')
      allow(spy_algorithm).to receive(:on)

      described_class.create(rows: rows, columns: columns, algorithm: spy_algorithm, seed: seed)

      expect(spy_algorithm).to have_received(:on).once
    end

    it 'adds algorithm accessor to the grid' do
      grid = described_class.create(rows: rows, columns: columns, algorithm: algorithm, seed: seed)

      expect(grid.algorithm).to eq(algorithm)
    end
  end

  describe '#create' do
    it 'creates a grid with the specified dimensions' do
      grid = map.create

      expect(grid.rows).to eq(rows)
      expect(grid.columns).to eq(columns)
    end

    it 'applies the algorithm to the grid' do
      # Use a spy to verify the algorithm is called
      spy_algorithm = spy('Algorithm')
      allow(spy_algorithm).to receive(:on)

      map_with_spy = described_class.new(
        rows: rows,
        columns: columns,
        algorithm: spy_algorithm,
        seed: seed
      )

      map_with_spy.create

      expect(spy_algorithm).to have_received(:on).once
    end

    it 'sets dead_ends on the grid' do
      # Create a grid spy to verify dead_ends is called
      grid_spy = instance_double('Vanilla::MapUtils::Grid')
      allow(Vanilla::MapUtils::Grid).to receive(:new).and_return(grid_spy)
      allow(grid_spy).to receive(:dead_ends).and_return([])
      allow(grid_spy).to receive(:instance_variable_set)
      allow(grid_spy).to receive(:define_singleton_method)
      allow(algorithm).to receive(:on).with(grid_spy)

      map.create

      expect(grid_spy).to have_received(:dead_ends)
    end
  end
end
