# lib/vanilla/level.rb
module Vanilla
  class Level
    attr_reader :grid, :difficulty, :entities, :stairs, :algorithm

    def initialize(rows:, columns:, difficulty:)
      @grid = Vanilla::MapUtils::Grid.new(rows, columns)
      @difficulty = difficulty
      @entities = []
    end

    def generate(algorithm)
      @algorithm = algorithm
      algorithm.on(@grid)
      self
    end

    def place_stairs(row, column)
      cell = @grid[row, column]
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
      cell.tile = render.character if render && render.character
    end

    def update_grid_with_entities
      # Reset grid to base state (walls and empty spaces)
      @grid.each_cell do |cell|
        cell.tile = cell.links.empty? ? Vanilla::Support::TileType::WALL : Vanilla::Support::TileType::EMPTY
      end
      # Overlay entities
      @entities.each { |e| update_grid_with_entity(e) }
    end
  end
end
