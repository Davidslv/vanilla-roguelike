require_relative 'cell_type_factory'

module Vanilla
  module MapUtils
    # Represents a single cell in a maze or grid-based map
    # It has a position in the grid and can be linked to other cells.
    # Cells can be linked to other cells to form a path or maze.
    # Cells can also have various properties, such as whether they are a dead end, or contain a player or stairs.
    #
    # @example
    #  cell = Vanilla::MapUtils::Cell.new(row: 0, column: 0)
    #  cell.north = Vanilla::MapUtils::Cell.new(row: 0, column: 0)
    #  cell.north.link(cell: cell)
    #
    # The `link` method is used to link this cell to another cell.
    # The `unlink` method is used to unlink this cell from another cell.
    # The `links` method returns an array of all cells linked to this cell.
    # The `linked?` method checks if this cell is linked to another cell.
    # The `neighbors` method returns an array of all neighboring cells (north, south, east, west).
    # The `distances` method calculates the distance from the current cell to all other cells in the map.
    # The `dead_end?` method checks if this cell is a dead end.
    # The `player?` method checks if this cell contains the player.
    # The `stairs?` method checks if this cell contains stairs.
    class Cell
      attr_reader :row, :column, :cell_type
      attr_accessor :north, :south, :east, :west
      attr_accessor :dead_end

      # Initialize a new cell with its position in the grid
      # @param row [Integer] The row position of the cell
      # @param column [Integer] The column position of the cell
      # @param type_factory [CellTypeFactory] Factory for cell types
      def initialize(row:, column:, type_factory: nil)
        @row, @column = row, column
        @links = {}

        # Use the provided factory or create a default one
        @type_factory = type_factory || CellTypeFactory.new
        @cell_type = @type_factory.get_cell_type(:empty)
      end

      # Get the position of the cell as an array
      # @return [Array<Integer>] An array containing the row and column
      def position
        [row, column]
      end

      # Link this cell to another cell
      # @param cell [Cell] The cell to link to
      # @param bidirectional [Boolean] Whether to create a bidirectional link
      # @return [Cell] Returns self for method chaining
      def link(cell:, bidirectional: true)
        raise ArgumentError, "Cannot link a cell to itself" if cell == self

        @links[cell] = true
        cell.link(cell: self, bidirectional: false) if bidirectional
        self
      end

      # Unlink this cell from another cell
      # @param cell [Cell] The cell to unlink from
      # @param bidirectional [Boolean] Whether to remove the link in both directions
      def unlink(cell:, bidirectional: true)
        @links.delete(cell)
        cell.unlink(cell: self, bidirectional: false) if bidirectional

        self
      end

      # Get all cells linked to this cell
      # @return [Array<Cell>] An array of linked cells
      def links
        @links.keys
      end

      # Check if this cell is linked to another cell
      # @param cell [Cell] The cell to check for a link
      # @return [Boolean] True if linked, false otherwise
      def linked?(cell)
        @links.key?(cell)
      end

      # Check if this cell is a dead end
      # @return [Boolean] True if it's a dead end, false otherwise
      def dead_end?
        !!dead_end
      end

      # Check if this cell contains the player
      # @return [Boolean] True if it contains the player, false otherwise
      def player?
        @cell_type.player?
      end

      # Check if this cell contains stairs
      # @return [Boolean] True if it contains stairs, false otherwise
      def stairs?
        @cell_type.stairs?
      end

      # Get all neighboring cells (north, south, east, west)
      # @return [Array<Cell>] An array of neighboring cells
      def neighbors
        [north, south, east, west].compact
      end

      # Set the cell type from a tile character
      # @param tile_character [String] The character to set
      def tile=(tile_character)
        @cell_type = @type_factory.get_by_character(tile_character)
      end

      # Get the tile character for this cell
      # @return [String] The tile character
      def tile
        @cell_type.tile_character
      end

      # Calculate distances from this cell to all other cells in the maze
      # @return [DistanceBetweenCells] A DistanceBetweenCells object containing distances
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
  end
end
