# lib/systems/maze_system.rb
require_relative "../grid"
require_relative "../binary_tree_generator" # Default generator
require_relative "../path_guarantor"
require_relative "../logger"

module Systems
  class MazeSystem
    def initialize(world, generator_class = BinaryTreeGenerator)
      @world = world
      @generator_class = generator_class
      @generated = false
      @level = 1
    end

    def process(_entities)
      # Only regenerate maze if it's a new level or hasn't been generated yet
      if @level == @world.current_level && @generated
        return
      end

      Logger.debug("Generating maze for level #{@world.current_level}")
      @level = @world.current_level
      @generated = false

      # Step 1: Generate the maze
      grid = Grid.new(@world.width, @world.height)
      grid.generate_maze(@generator_class)

      # Step 2: Ensure there's a path from start to end
      Logger.debug("Ensuring path exists from start to end")
      guarantor = PathGuarantor.new(grid)
      guarantor.ensure_path(1, 1, @world.width - 2, @world.height - 2)

      # Step 3: Create wall entities
      grid.cells.each_with_index do |row, y|
        row.each_with_index do |cell, x|
          next unless cell.is_wall

          wall = @world.create_entity
          wall.add_component(Components::Position.new(x, y))
          wall.add_component(Components::Render.new("#"))
        end
      end

      @generated = true
    end

    private

    attr_reader :world
  end
end
