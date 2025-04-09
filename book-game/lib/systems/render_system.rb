module Systems
  class RenderSystem
    def initialize(width, height)
      @width = width
      @height = height
    end

    def process(entities)
      # Clear the screen
      system("clear") || system("cls")

      # Build an empty grid
      grid = Array.new(@height) { Array.new(@width) { "." } }

      # Place entities on the grid
      entities.each do |entity|
        next unless entity.has_component?(Components::Position) &&
                    entity.has_component?(Components::Render)

        pos = entity.get_component(Components::Position)
        render = entity.get_component(Components::Render)

        if pos.x.between?(0, @width - 1) && pos.y.between?(0, @height - 1)
          grid[pos.y][pos.x] = render.character
        end
      end

      # Render the grid to the console
      puts "\n" # Add some spacing
      grid.each { |row| puts row.join(" ") }
      puts "\nControls: WASD to move, Q to quit"
      print "> " # Prompt for input
    end
  end
end
