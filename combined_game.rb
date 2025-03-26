# Begin lib/vanilla/map_utils//cell.rb
# frozen_string_literal: true

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
        # TODO: HACKED here... should look at @cell_type.stairs?
        tile == Vanilla::Support::TileType::STAIRS
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
# End lib/vanilla/map_utils//cell.rb

# Begin lib/vanilla/map_utils//cell_type.rb
# frozen_string_literal: true

module Vanilla
  module MapUtils
    # CellType implements the Flyweight pattern for cell types
    # It stores the intrinsic (shared) state of cells, such as
    # the tile character and properties like walkability
    class CellType
      attr_reader :key, :tile_character, :properties

      # Initialize a new cell type
      # @param key [Symbol] The key identifier for this cell type
      # @param tile_character [String] The character used to render this cell type
      # @param properties [Hash] Additional properties for this cell type
      def initialize(key, tile_character, properties = {})
        @key = key
        @tile_character = tile_character
        @properties = properties.freeze
      end

      # Check if this cell type is walkable
      # @return [Boolean] True if walkable, false otherwise
      def walkable?
        @properties.fetch(:walkable, true)
      end

      # Check if this cell type represents stairs
      # @return [Boolean] True if stairs, false otherwise
      def stairs?
        # TODO: HACKED here... should look at properties instead
        @tile_character == Vanilla::Support::TileType::STAIRS # Adjust based on your TileType definition

        # @properties.fetch(:stairs, false)
      end

      # Check if this cell type represents a player
      # @return [Boolean] True if player, false otherwise
      def player?
        @properties.fetch(:player, false)
      end

      # Get the character to render for this cell type
      # @return [String] The tile character
      def to_s
        @tile_character
      end
    end
  end
end
# End lib/vanilla/map_utils//cell_type.rb

# Begin lib/vanilla/map_utils//cell_type_factory.rb
# frozen_string_literal: true

require_relative 'cell_type'

module Vanilla
  module MapUtils
    # CellTypeFactory implements the Flyweight pattern factory
    # It creates and manages CellType instances, ensuring that
    # identical types are reused rather than duplicated
    class CellTypeFactory
      # Initialize a new factory and setup standard types
      def initialize
        @types = {}
        setup_standard_types
      end

      # Get a cell type by its key identifier
      # @param key [Symbol] The key for the cell type
      # @return [CellType] The requested cell type
      # @raise [ArgumentError] If the key is unknown
      def get_cell_type(key)
        @types[key] or raise ArgumentError, "Unknown cell type: #{key}"
      end

      # Get a cell type by its tile character
      # @param tile_character [String] The tile character
      # @return [CellType] The cell type for this character, or the empty type if not found
      def get_by_character(tile_character)
        # Find the type with matching tile character or default to empty
        @types.values.find { |t| t.tile_character == tile_character } || @types[:empty]
      end

      # Register a new cell type
      # @param key [Symbol] The identifier for this type
      # @param tile_character [String] The character used to render this type
      # @param properties [Hash] Additional properties for this type
      # @return [CellType] The newly created cell type
      def register(key, tile_character, properties = {})
        @types[key] = CellType.new(key, tile_character, properties)
      end

      private

      # Setup the standard cell types used in the game
      def setup_standard_types
        register(:empty, Vanilla::Support::TileType::EMPTY, walkable: true)
        register(:wall, Vanilla::Support::TileType::WALL, walkable: false)
        register(:player, Vanilla::Support::TileType::PLAYER, walkable: true, player: true)
        register(:stairs, Vanilla::Support::TileType::STAIRS, walkable: true, stairs: true)
        register(:door, Vanilla::Support::TileType::DOOR, walkable: true)
        register(:floor, Vanilla::Support::TileType::FLOOR, walkable: true)
        register(:monster, Vanilla::Support::TileType::MONSTER, walkable: false)
        register(:vertical_wall, Vanilla::Support::TileType::VERTICAL_WALL, walkable: false)
      end
    end
  end
end
# End lib/vanilla/map_utils//cell_type_factory.rb

# Begin lib/vanilla/map_utils//distance_between_cells.rb
# frozen_string_literal: true

module Vanilla
  module MapUtils
    # We will use this class to record the distance of each cell from the starting point (@root)
    # so the initialize constructor simply sets up the hash so that the distance of the root from itself is 0.
    class DistanceBetweenCells
      def initialize(root)
        @root = root
        @cells = {}
        @cells[@root] = 0
      end

      #  We also add an array accessor method, [](cell),
      #  so that we can query the distance of a given cell from the root
      def [](cell)
        @cells[cell]
      end

      #  And a corresponding setter, to record the distance of a given cell.
      def []=(cell, distance)
        @cells[cell] = distance
      end

      # to get a list of all of the cells that are present.
      def cells
        @cells.keys
      end

      def path_to(goal)
        current = goal

        breadcrumbs = DistanceBetweenCells.new(@root)
        breadcrumbs[current] = @cells[current]

        until current == @root
          current.links.each do |neighbor|
            if @cells[neighbor] < @cells[current]
              breadcrumbs[neighbor] = @cells[neighbor]
              current = neighbor

              break
            end
          end
        end

        breadcrumbs
      end

      def max
        max_distance = 0
        max_cell = @root

        @cells.each do |cell, distance|
          if distance > max_distance
            max_cell = cell
            max_distance = distance
          end
        end

        [max_cell, max_distance]
      end
    end
  end
end
# End lib/vanilla/map_utils//distance_between_cells.rb

# Begin lib/vanilla/map_utils//grid.rb
# frozen_string_literal: true

module Vanilla
  module MapUtils
    class Grid
      attr_reader :rows, :columns

      def initialize(rows, columns)
        @rows = rows
        @columns = columns
        @grid = Array.new(rows * columns) { |i| Cell.new(self, i / columns, i % columns) }
        # Set neighbors for each cell
        each_cell do |cell|
          row, col = cell.row, cell.column
          cell.north = self[row - 1, col] if row > 0
          cell.south = self[row + 1, col] if row < @rows - 1
          cell.east  = self[row, col + 1] if col < @columns - 1
          cell.west  = self[row, col - 1] if col > 0
        end
      end

      def [](row, col)
        return nil unless row.is_a?(Integer) && col.is_a?(Integer)
        return nil unless row.between?(0, @rows - 1) && col.between?(0, @columns - 1)

        @grid[row * @columns + col]
      end

      def each_cell
        @grid.each { |cell| yield cell }
      end

      def random_cell
        @grid.sample
      end

      def size
        @rows * @columns
      end
    end

    class Cell
      attr_reader :row, :column, :grid
      attr_accessor :north, :south, :east, :west, :tile

      def initialize(grid, row, column)
        @grid = grid
        @row = row
        @column = column
        @links = {}
        @tile = Vanilla::Support::TileType::EMPTY # Default to walkable
      end

      def link(cell:, bidirectional: true)
        @links[cell] = true
        cell.links[self] = true if bidirectional && cell
      end

      def unlink(cell:, bidirectional: true)
        @links.delete(cell)
        cell.links.delete(self) if bidirectional && cell
      end

      def linked?(cell)
        @links.key?(cell)
      end

      def links
        @links
      end

      def neighbors
        [north, south, east, west].compact
      end

      def distances
        Distances.new(self)
      end
    end

    class Distances
      def initialize(root)
        @root = root
        @cells = { root => 0 }
      end

      def [](cell)
        @cells[cell]
      end

      def path_to(_goal)
        self # Placeholder
      end

      def cells
        @cells.keys
      end

      def max
        max_distance = 0
        max_cell = @root
        @cells.each { |cell, distance| max_cell, max_distance = cell, distance if distance > max_distance }
        [max_cell, max_distance]
      end
    end
  end
end
# End lib/vanilla/map_utils//grid.rb

