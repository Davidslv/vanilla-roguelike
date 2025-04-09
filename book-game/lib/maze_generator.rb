# lib/maze_generator.rb
class MazeGenerator
  def initialize(grid)
    @grid = grid # The Grid instance to modify
  end

  def generate
    raise NotImplementedError, "Subclasses must implement 'generate'"
  end
end
