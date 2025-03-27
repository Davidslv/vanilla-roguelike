# frozen_string_literal: true

# lib/vanilla/level.rb
module Vanilla
  class Level
    attr_reader :grid, :difficulty, :entities, :algorithm

    def initialize(grid:, difficulty:, algorithm:)
      @grid = grid
      @algorithm = algorithm
      @difficulty = difficulty
      @entities = []

      @logger = Vanilla::Logger.instance
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
      cell.tile = render.character if render && render.character # Always set entity tile
      @logger.debug("Updated grid at: [#{position.row}, #{position.column}] to tile: #{cell.tile}")
    end

    def update_grid_with_entities
      @grid.each_cell do |cell|
        cell.tile = cell.links.empty? ? Vanilla::Support::TileType::WALL : Vanilla::Support::TileType::EMPTY
      end
      @entities.each { |e| update_grid_with_entity(e) }
      @logger.debug("[Level#update_grid_with_entities] Grid updated with all entities")
    end
  end
end
