require 'spec_helper'
require 'vanilla/algorithms/binary_tree'
require 'vanilla/map_utils/grid'

RSpec.describe Vanilla::Algorithms::BinaryTree do
  describe '.on' do
    # Use a very small grid to reduce memory usage
    let(:grid) { Vanilla::MapUtils::Grid.new(rows: 3, columns: 3) }

    it 'returns the modified grid' do
      result = described_class.on(grid)
      expect(result).to eq(grid)
    end

    it 'inherits from AbstractAlgorithm' do
      expect(described_class).to be < Vanilla::Algorithms::AbstractAlgorithm
    end

    it 'creates a valid binary tree maze' do
      described_class.on(grid)
      
      # In a binary tree, each cell should only have outgoing links to north or east
      grid.each_cell do |cell|
        # Check if this cell has north or east neighbors
        has_north = !cell.north.nil?
        has_east = !cell.east.nil?
        
        # For cells that have options, ensure they linked to either north or east
        if has_north || has_east
          north_linked = has_north && cell.linked?(cell.north)
          east_linked = has_east && cell.linked?(cell.east)
          
          # Each cell should link to either north or east (if available)
          # But not both (binary tree property)
          if has_north && has_east
            expect(north_linked ^ east_linked).to be(true), 
              "Cell at (#{cell.row}, #{cell.column}) should link to exactly one of north or east"
          elsif has_north
            expect(north_linked).to be(true),
              "Cell at (#{cell.row}, #{cell.column}) should link north when it's the only option"
          elsif has_east
            expect(east_linked).to be(true),
              "Cell at (#{cell.row}, #{cell.column}) should link east when it's the only option"
          end
          
          # Cell should not make outgoing links to south or west
          # (though it may have incoming links from those directions)
          if cell.south
            expect(cell.south.linked?(cell)).to be(cell.linked?(cell.south)),
              "Links should be bidirectional"
          end
          
          if cell.west
            expect(cell.west.linked?(cell)).to be(cell.linked?(cell.west)),
              "Links should be bidirectional"
          end
        end
      end
    end
    
    context 'with mocks' do
      it 'processes cells correctly' do
        # Create mock grid and cells with minimal implementation
        north = double('north')
        east = double('east')
        cell = double('cell', north: north, east: east)
        
        # Set expectations for linking
        expect(cell).to receive(:link).with(cell: anything)
        
        # Minimal grid implementation
        grid = double('grid')
        allow(grid).to receive(:each_cell).and_yield(cell)
        
        # Run algorithm
        described_class.on(grid)
      end
    end
  end
end 