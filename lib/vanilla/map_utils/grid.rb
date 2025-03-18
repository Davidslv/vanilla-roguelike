require_relative 'cell'
require_relative 'cell_type_factory'

module Vanilla
  module MapUtils
    class Grid
      attr_reader :rows, :columns
      attr_accessor :distances

      # Get the shared cell type factory for all grids
      # @return [CellTypeFactory] The shared factory instance
      def self.cell_type_factory
        @cell_type_factory ||= CellTypeFactory.new
      end

      def initialize(rows:, columns:)
        raise ArgumentError, "Rows must be greater than 0" if rows <= 0
        raise ArgumentError, "Columns must be greater than 0" if columns <= 0

        @rows, @columns = rows, columns

        @grid = prepare_grid

        configure_cells
      end

      # custom array accessor
      # primarily for granting random access to arbitrary cells in the grid
      # but also do bounds checking, so when a coordinate is passed that
      # is out of bounds, it returns nil.
      def [](row, column)
        return nil unless row.between?(0, @rows - 1)
        return nil unless column.between?(0, @grid[row].count - 1)

        @grid[row][column]
      end

      def random_cell
        row = rand(@rows)
        column = rand(@grid[row].count)

        self[row, column]
      end

      def size
        @rows * @columns
      end

      def contents_of(cell)
        if cell.player?
          cell.cell_type.to_s
        elsif cell.cell_type && cell.cell_type.tile_character != Vanilla::Support::TileType::EMPTY
          cell.cell_type.to_s
        elsif distances && distances[cell]
          distances[cell].to_s(36)
        else
          " "
        end
      end

      def dead_ends
        each_cell do |cell|
          cell.dead_end = cell.links.count == 1
        end
      end

      # iterator to loop over cells on the grid
      # some algorithms want to look at cells a row at a time (Sidewinder)
      # others just want to look at cells (Binary Tree)
      def each_row
        @grid.each do |row|
          yield row
        end
      end

      def each_cell
        each_row do |row|
          row.each do |cell|
            yield cell if cell
          end
        end
      end

      private

      # initial grid setup with cells
      def prepare_grid
        Array.new(rows) do |row|
          Array.new(columns) do |column|
            Cell.new(row: row, column: column, type_factory: self.class.cell_type_factory)
          end
        end
      end

      # each cell is assigned a neighbor
      def configure_cells
        each_cell do |cell|
          row, col = cell.row, cell.column

          cell.north = self[row - 1, col]
          cell.south = self[row + 1, col]
          cell.west  = self[row, col - 1]
          cell.east  = self[row, col + 1]
        end
      end
    end
  end
end
