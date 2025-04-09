# lib/systems/movement_system.rb
require_relative "../logger"

module Systems
  class MovementSystem
    def initialize(world)
      @world = world # Access to all entities for collision checks
    end

    def process(entities, grid_width, grid_height)
      Logger.debug("MovementSystem processing #{entities.size} entities")

      entities.each do |entity|
        next unless entity.has_component?(Components::Position) &&
                    entity.has_component?(Components::Movement)

        pos = entity.get_component(Components::Position)
        mov = entity.get_component(Components::Movement)

        # Skip if no movement
        if mov.dx == 0 && mov.dy == 0
          Logger.debug("No movement for entity #{entity.id}")
          next
        end

        Logger.debug("Processing movement for entity #{entity.id}: dx=#{mov.dx}, dy=#{mov.dy}")
        Logger.debug("Current position: x=#{pos.x}, y=#{pos.y}")

        # Calculate proposed new position
        new_x = pos.x + mov.dx
        new_y = pos.y + mov.dy
        Logger.debug("Proposed new position: x=#{new_x}, y=#{new_y}")

        # Check grid boundaries
        unless new_x.between?(0, grid_width - 1) && new_y.between?(0, grid_height - 1)
          Logger.debug("Out of bounds: x=#{new_x}, y=#{new_y}, width=#{grid_width}, height=#{grid_height}")
          mov.dx = 0
          mov.dy = 0
          next
        end

        # Check for wall collision
        if wall_at?(new_x, new_y)
          Logger.debug("Wall collision at x=#{new_x}, y=#{new_y}")
          # Reset movement if blocked
          mov.dx = 0
          mov.dy = 0
          next
        end

        # If clear, update position
        pos.x = new_x
        pos.y = new_y
        Logger.debug("Position updated: x=#{pos.x}, y=#{pos.y}")

        # Reset movement after applying
        mov.dx = 0
        mov.dy = 0
      end
    end

    private

    def wall_at?(x, y)
      @world.entities.values.any? do |entity|
        pos = entity.get_component(Components::Position)
        render = entity.get_component(Components::Render)
        pos && pos.x == x && pos.y == y && render && render.character == "#"
      end
    end
  end
end
