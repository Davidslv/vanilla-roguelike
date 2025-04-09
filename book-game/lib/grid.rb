# lib/grid.rb
class Grid
  class Cell
    attr_accessor :is_wall

    def initialize(is_wall = true)
      @is_wall = is_wall # True = wall, False = path
    end

    def to_s
      @is_wall ? "#" : "." # For debugging or simple rendering
    end
  end

  attr_reader :width, :height, :cells

  def initialize(width, height)
    @width = width
    @height = height
    @cells = Array.new(height) { Array.new(width) { Cell.new } }
  end

  def at(x, y)
    return nil if x < 0 || x >= @width || y < 0 || y >= @height

    @cells[y][x]
  end

  def generate_maze(generator_class = BinaryTreeGenerator)
    generator = generator_class.new(self)
    generator.generate
  end
end
