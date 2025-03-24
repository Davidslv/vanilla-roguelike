# lib/vanilla/level.rb
module Vanilla
  class Level
    attr_reader :grid, :difficulty, :entities, :stairs, :algorithm, :entrance_row, :entrance_column

    def initialize(rows:, columns:, difficulty:)
      @grid = Vanilla::MapUtils::Grid.new(rows, columns)
      @difficulty = difficulty
      @entities = []
      @entrance_row = 0
      @entrance_column = 0
      @logger = Vanilla::Logger.instance
    end

    def generate(algorithm)
      @algorithm = algorithm
      algorithm.on(@grid)
      self
    end

    def place_stairs(row, column)
      cell = @grid[row, column]
      @logger.debug("Placing stairs at: [#{row}, #{column}]")
      cell.tile = Vanilla::Support::TileType::STAIRS
      @stairs = Vanilla::EntityFactory.create_stairs(row, column)
      add_entity(@stairs)
    end

    def add_entity(entity)
      @entities << entity
      update_grid_with_entity(entity)
    end

    def remove_entity(entity)
      @entities.delete(entity)
    end

    def all_entities
      @entities
    end

    def update_grid_with_entity(entity)
      position = entity.get_component(:position)
      return unless position
      cell = @grid[position.row, position.column]
      return unless cell
      render = entity.get_component(:render)
      if render && render.character
        # Only update if cell isn’t already occupied by a higher-priority entity (e.g., player over stairs)
        if cell.tile == Vanilla::Support::TileType::EMPTY || entity.has_tag?(:player)
          cell.tile = render.character
          @logger.debug("Updated grid with entity at: [#{position.row}, #{position.column}] to tile: #{cell.tile}")
        end
      end
    end

    def update_grid_with_entities
      @grid.each_cell do |cell|
        cell.tile = cell.links.empty? ? Vanilla::Support::TileType::WALL : Vanilla::Support::TileType::EMPTY
      end
      # Process stairs first, then other entities, then player last
      @entities.sort_by { |e| e.has_tag?(:player) ? 1 : e.has_tag?(:stairs) ? 0 : 2 }.each { |e| update_grid_with_entity(e) }
    end
  end
end
