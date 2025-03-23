module Vanilla
  class Level
    attr_reader :grid, :difficulty, :entities, :stairs

    def initialize(rows:, columns:, difficulty:)
      @grid = Vanilla::MapUtils::Grid.new(rows, columns)
      @difficulty = difficulty
      @entities = []
    end

    def generate(algorithm)
      algorithm.on(@grid)
      self
    end

    def place_stairs
      cell = @grid.random_cell
      cell.tile = Vanilla::Support::TileType::STAIRS
      @stairs = Vanilla::EntityFactory.create_stairs(cell.row, cell.column)
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
      cell.tile = render.character if render && render.character
    end

    def update_grid_with_entities
      @grid.each_cell { |cell| cell.tile = Vanilla::Support::TileType::EMPTY }
      @entities.each { |e| update_grid_with_entity(e) }
    end
  end
end
