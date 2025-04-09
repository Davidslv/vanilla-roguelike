# lib/path_guarantor.rb
class PathGuarantor
  def initialize(grid)
    @grid = grid
    @visited = Array.new(@grid.height) { Array.new(@grid.width, false) }
    @path_found = false
  end

  def ensure_path(start_x, start_y, end_x, end_y)
    # Check if a path exists
    @path_found = false
    @visited = Array.new(@grid.height) { Array.new(@grid.width, false) }

    if find_path(start_x, start_y, end_x, end_y)
      return true # Path already exists
    end

    # No path found, create one
    create_path(start_x, start_y, end_x, end_y)
    true
  end

  private

  def find_path(x, y, target_x, target_y)
    # Check if out of bounds or wall or already visited
    return false if x < 0 || x >= @grid.width || y < 0 || y >= @grid.height
    return false if @grid.at(x, y).is_wall
    return false if @visited[y][x]

    # Mark as visited
    @visited[y][x] = true

    # Check if reached target
    if x == target_x && y == target_y
      @path_found = true
      return true
    end

    # Try all four directions
    return true if find_path(x + 1, y, target_x, target_y)
    return true if find_path(x - 1, y, target_x, target_y)
    return true if find_path(x, y + 1, target_x, target_y)
    return true if find_path(x, y - 1, target_x, target_y)

    false
  end

  def create_path(start_x, start_y, end_x, end_y)
    # Create a direct path by carving through walls
    current_x = start_x
    current_y = start_y

    while current_x != end_x || current_y != end_y
      # Move horizontally first
      if current_x < end_x
        current_x += 1
      elsif current_x > end_x
        current_x -= 1
      # Then move vertically
      elsif current_y < end_y
        current_y += 1
      elsif current_y > end_y
        current_y -= 1
      end

      # Carve path
      @grid.at(current_x, current_y).is_wall = false
    end
  end
end
