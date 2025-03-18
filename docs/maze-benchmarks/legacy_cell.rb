module Vanilla
  module MapUtils
    # A legacy version of Cell that doesn't use the Flyweight pattern
    # This is used for benchmarking comparisons only
    class LegacyCell
      attr_reader :row, :column
      attr_accessor :north, :south, :east, :west
      attr_accessor :dead_end, :tile

      def initialize(row:, column:)
        @row, @column = row, column
        @links = {}
        @tile = ' ' # Default empty tile
      end

      def position
        [row, column]
      end

      def link(cell:, bidirectional: true)
        raise ArgumentError, "Cannot link a cell to itself" if cell == self

        @links[cell] = true
        cell.link(cell: self, bidirectional: false) if bidirectional
        self
      end

      def unlink(cell:, bidirectional: true)
        @links.delete(cell)
        cell.unlink(cell: self, bidirectional: false) if bidirectional

        self
      end

      def links
        @links.keys
      end

      def linked?(cell)
        @links.key?(cell)
      end

      def dead_end?
        !!dead_end
      end

      def player?
        tile == Vanilla::Support::TileType::PLAYER
      end

      def stairs?
        tile == Vanilla::Support::TileType::STAIRS
      end

      def neighbors
        [north, south, east, west].compact
      end

      def walkable?
        Vanilla::Support::TileType.walkable?(tile)
      end

      def distances
        distances = Vanilla::MapUtils::DistanceBetweenCells.new(self)
        frontier = [self]

        while frontier.any?
          new_frontier = []

          frontier.each do |cell|
            cell.links.each do |linked|
              next if distances[linked]

              distances[linked] = distances[cell] + 1
              new_frontier << linked
            end
          end

          frontier = new_frontier
        end

        distances
      end
    end

    # Legacy grid that doesn't use the Flyweight pattern
    class LegacyGrid
      attr_reader :rows, :columns
      attr_accessor :distances

      def initialize(rows:, columns:)
        raise ArgumentError, "Rows must be greater than 0" if rows <= 0
        raise ArgumentError, "Columns must be greater than 0" if columns <= 0

        @rows, @columns = rows, columns
        @grid = prepare_grid
        configure_cells
      end

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
          Vanilla::Support::TileType::PLAYER
        elsif Vanilla::Support::TileType.values.include?(cell.tile)
          cell.tile
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

      def prepare_grid
        Array.new(rows) do |row|
          Array.new(columns) do |column|
            LegacyCell.new(row: row, column: column)
          end
        end
      end

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