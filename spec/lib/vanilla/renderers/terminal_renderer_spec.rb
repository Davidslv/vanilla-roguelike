# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Renderers::TerminalRenderer do
  let(:renderer) { described_class.new }
  let(:rows) { 5 }
  let(:columns) { 5 }
  let(:grid) do
    grid = instance_double(
      'Vanilla::MapUtils::Grid',
      rows: rows,
      columns: columns
    )

    # Set up cells in grid
    cells = {}
    rows.times do |row|
      columns.times do |col|
        cell = instance_double(
          'Vanilla::MapUtils::Cell',
          row: row,
          column: col
        )

        # Allow linked? to be called on cells
        allow(cell).to receive(:linked?).and_return(true)

        # Store in our cells hash
        cells[[row, col]] = cell

        # Allow grid to access this cell
        allow(grid).to receive(:[]).with(row, col).and_return(cell)

        # Allow grid to access adjacent cells for boundaries
        allow(grid).to receive(:[]).with(row, col + 1).and_return(cells[[row, col + 1]])
        allow(grid).to receive(:[]).with(row + 1, col).and_return(cells[[row + 1, col]])
      end
    end

    grid
  end

  before do
    # Stub system and puts to avoid terminal output during tests
    allow(renderer).to receive(:system)
    allow(renderer).to receive(:puts)

    # Set test value for global seed variable
    $seed = 12345
  end

  # Reset global seed after each test
  after do
    $seed = nil
  end

  describe '#initialize' do
    it 'sets default values for instance variables' do
      expect(renderer.instance_variable_get(:@buffer)).to be_nil
      expect(renderer.instance_variable_get(:@grid)).to be_nil
      expect(renderer.instance_variable_get(:@header)).to eq("")
    end
  end

  describe '#clear' do
    it 'resets the buffer' do
      # Set up buffer first
      renderer.instance_variable_set(:@buffer, [['x']])

      renderer.clear

      expect(renderer.instance_variable_get(:@buffer)).to be_nil
    end

    it 'calls system clear command' do
      expect(renderer).to receive(:system).with("clear")

      renderer.clear
    end
  end

  describe '#draw_grid' do
    it 'initializes buffer with grid dimensions' do
      renderer.draw_grid(grid)

      buffer = renderer.instance_variable_get(:@buffer)
      expect(buffer).to be_an(Array)
      expect(buffer.size).to eq(rows)
      expect(buffer.first.size).to eq(columns)
    end

    it 'stores grid reference' do
      renderer.draw_grid(grid)

      expect(renderer.instance_variable_get(:@grid)).to eq(grid)
    end

    it 'initializes buffer with spaces' do
      renderer.draw_grid(grid)

      buffer = renderer.instance_variable_get(:@buffer)
      buffer.each do |row|
        row.each do |cell|
          expect(cell).to eq(' ')
        end
      end
    end

    it 'sets header with grid information' do
      renderer.draw_grid(grid)

      header = renderer.instance_variable_get(:@header)
      expect(header).to include("Seed: #{$seed}")
      expect(header).to include("Rows: #{rows}")
      expect(header).to include("Columns: #{columns}")
    end
  end

  describe '#draw_character' do
    before do
      # Initialize buffer first
      renderer.draw_grid(grid)
    end

    it 'places character in buffer at specified position' do
      renderer.draw_character(1, 2, '@')

      buffer = renderer.instance_variable_get(:@buffer)
      expect(buffer[1][2]).to eq('@')
    end

    it 'does nothing if buffer is not initialized' do
      # Reset buffer
      renderer.instance_variable_set(:@buffer, nil)

      # This should not raise an error
      expect {
        renderer.draw_character(1, 2, '@')
      }.not_to raise_error
    end

    it 'ignores positions outside buffer bounds' do
      # These should not raise errors
      expect {
        renderer.draw_character(-1, 0, '@')
        renderer.draw_character(0, -1, '@')
        renderer.draw_character(rows, 0, '@')
        renderer.draw_character(0, columns, '@')
      }.not_to raise_error
    end

    it 'accepts a color parameter but does not use it yet' do
      # The method should accept the color parameter without error
      expect {
        renderer.draw_character(1, 2, '@', :red)
      }.not_to raise_error

      # The character should still be set correctly
      buffer = renderer.instance_variable_get(:@buffer)
      expect(buffer[1][2]).to eq('@')
    end
  end

  describe '#present' do
    before do
      # Initialize buffer and grid
      renderer.draw_grid(grid)

      # Add some characters to the buffer
      renderer.draw_character(1, 1, '@')
      renderer.draw_character(2, 3, 'M')
    end

    it 'prints header information' do
      expect(renderer).to receive(:puts).with(renderer.instance_variable_get(:@header))
      expect(renderer).to receive(:puts).with("-" * 35)
      expect(renderer).to receive(:puts).with("\n")
      expect(renderer).to receive(:puts)  # For the final output

      renderer.present
    end

    it 'does nothing if buffer is nil' do
      renderer.instance_variable_set(:@buffer, nil)

      # Should return early without errors
      expect(renderer).not_to receive(:puts)
      renderer.present
    end

    it 'does nothing if grid is nil' do
      renderer.instance_variable_set(:@grid, nil)

      # Should return early without errors
      expect(renderer).not_to receive(:puts)
      renderer.present
    end

    it 'generates correct output string with grid and buffer content' do
      # Capture the output parameter passed to puts
      output_captured = nil
      expect(renderer).to receive(:puts).at_least(:once) do |output|
        output_captured = output if output.is_a?(String) && output.include?('+---+')
      end

      renderer.present

      # Now test the captured output
      expect(output_captured).to include('+---+')  # Grid borders
      expect(output_captured).to include(' @ ')  # Character at 1,1
      expect(output_captured).to include(' M ')  # Character at 2,3
    end

    it 'formats characters in the buffer correctly' do
      # Test single character padding
      renderer.draw_character(0, 0, 'X')

      # Test multi-character handling
      renderer.draw_character(0, 1, 'AB')

      # Capture and examine the output containing our characters
      output_captured = nil
      allow(renderer).to receive(:puts) do |output|
        output_captured = output if output.is_a?(String) && output.include?('|')
      end

      renderer.present

      # Verify the captured output contains our formatted characters
      expect(output_captured).to include(' X ')
      expect(output_captured).to include(' AB')
    end

    it 'renders cell boundaries based on linked cells' do
      # Set up cells with different link patterns
      cell1 = grid[0, 0]
      cell2 = grid[0, 1]

      # These cells aren't linked
      allow(cell1).to receive(:linked?).with(cell2).and_return(false)

      # Simulate vertical link
      cell3 = grid[1, 0]
      allow(cell1).to receive(:linked?).with(cell3).and_return(true)

      expect(renderer).to receive(:puts).at_least(:once)

      renderer.present
    end
  end
end
