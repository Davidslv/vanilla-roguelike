# lib/binary_tree_generator.rb
require_relative "maze_generator"

class BinaryTreeGenerator < MazeGenerator
  def generate
    # Step 1: Fill everything with walls initially
    @grid.cells.each { |row| row.each { |cell| cell.is_wall = true } }

    # Step 2: Create outer walls
    (0...@grid.width).each do |x|
      @grid.at(x, 0).is_wall = true
      @grid.at(x, @grid.height - 1).is_wall = true
    end
    (0...@grid.height).each do |y|
      @grid.at(0, y).is_wall = true
      @grid.at(@grid.width - 1, y).is_wall = true
    end

    # Step 3: Create a proper maze using binary tree algorithm
    (1...@grid.height - 1).step(2) do |y|
      (1...@grid.width - 1).step(2) do |x|
        # Carve the current cell
        @grid.at(x, y).is_wall = false

        # Randomly choose to carve north or east
        if y > 1 && (x == @grid.width - 2 || rand < 0.5)
          # Carve north
          @grid.at(x, y - 1).is_wall = false
        elsif x < @grid.width - 2
          # Carve east
          @grid.at(x + 1, y).is_wall = false
        end
      end
    end

    # Step 4: Ensure start and end points are clear
    @grid.at(1, 1).is_wall = false # Start point
    @grid.at(@grid.width - 2, @grid.height - 2).is_wall = false # End point
  end
end
