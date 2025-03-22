module Vanilla
  module Systems
    # The MovementSystem implements movement logic for entities in the game world.
    #
    # This system follows the pure ECS pattern by operating on entities with the
    # required components rather than the components containing their own behavior.
    # It separates the movement logic from the data, making the system more modular
    # and easier to maintain.
    #
    # The MovementSystem is responsible for:
    # * Checking if movement is possible for an entity
    # * Updating entity positions based on movement direction
    # * Handling collisions with the grid
    # * Processing special cell attributes (like stairs)
    # * Logging movement events
    #
    # == Required Components
    # Entities must have both of these components to be processed by this system:
    # * PositionComponent - For tracking and updating entity position
    # * MovementComponent - For movement capabilities and restrictions
    #
    # == Optional Components
    # These components will be updated if present:
    # * StairsComponent - Updated when stairs are encountered
    # * TileComponent - Could be used for visual representation (not implemented yet)
    #
    # == Usage
    #   entity = Entity.new
    #   entity.add_component(PositionComponent.new)
    #   entity.add_component(MovementComponent.new)
    #
    #   movement_system = MovementSystem.new(grid)
    #   movement_system.move(entity, :north)
    class MovementSystem
      # Initialize a new movement system
      # @param grid [Vanilla::MapUtils::Grid] The game grid
      def initialize(grid)
        @grid = grid
        @logger = Vanilla::Logger.instance
      end

      # Move an entity in the specified direction
      # @param entity [Vanilla::Components::Entity] The entity to move
      # @param direction [Symbol] The direction to move (:north, :south, :east, :west)
      # @return [Boolean] Whether the movement was successful
      def move(entity, direction)
        return false unless can_process?(entity)

        position = entity.get_component(:position)
        movement = entity.get_component(:movement)

        # Check if entity can move in this direction
        direction_symbol = normalize_direction(direction)
        return false unless movement.can_move_directions.include?(direction_symbol)

        # Get cells
        current_cell = @grid[position.row, position.column]
        return false unless current_cell

        target_cell = get_target_cell(current_cell, direction_symbol)
        return false unless target_cell && can_move_to?(current_cell, target_cell, direction_symbol)

        # Store original position for logging
        old_position = [position.row, position.column]

        # Handle special attributes
        handle_special_cell_attributes(entity, target_cell)

        # Check if we're on stairs and update the stairs component
        if target_cell.stairs? && entity.has_component?(:stairs) && !entity.get_component(:stairs).found_stairs
          entity.get_component(:stairs).found_stairs = true

          # Log a message about finding stairs
          # Use the MessageSystem service if available
          message_system = Vanilla::Messages::MessageSystem.instance

          if message_system
            # Log message using the facade
            message_system.log_message("exploration.find_stairs",
                                    category: :exploration,
                                    importance: :success)
          else
            @logger.info("Player found stairs")
          end

          # Continue movement - don't return early
        end

        # Update position
        update_position(position, direction_symbol, movement.speed)

        # Log movement
        log_movement(entity, direction_symbol, old_position, [position.row, position.column])

        true
      end

      private

      # Check if the entity has the required components
      # @param entity [Vanilla::Components::Entity] The entity to check
      # @return [Boolean] Whether the entity can be processed
      def can_process?(entity)
        entity.has_component?(:position) && entity.has_component?(:movement)
      end

      # Convert various direction formats to a standard symbol
      # @param direction [Symbol, String] The direction to normalize
      # @return [Symbol] The normalized direction
      def normalize_direction(direction)
        case direction.to_s.downcase
        when 'up', 'north', ':north'
          :north
        when 'down', 'south', ':south'
          :south
        when 'left', 'west', ':west'
          :west
        when 'right', 'east', ':east'
          :east
        else
          direction.to_sym
        end
      end

      # Get the target cell for movement
      # @param cell [Vanilla::MapUtils::Cell] The current cell
      # @param direction [Symbol] The direction to move
      # @return [Vanilla::MapUtils::Cell, nil] The target cell or nil
      def get_target_cell(cell, direction)
        case direction
        when :north
          cell.north
        when :south
          cell.south
        when :east
          cell.east
        when :west
          cell.west
        else
          nil
        end
      end

      # Check if movement to the target cell is possible
      # @param current_cell [Vanilla::MapUtils::Cell] The current cell
      # @param target_cell [Vanilla::MapUtils::Cell] The target cell
      # @param direction [Symbol] The movement direction
      # @return [Boolean] Whether movement is possible
      def can_move_to?(current_cell, target_cell, direction)
        # Check if cells are linked (i.e., no wall between them)
        current_cell.linked?(target_cell)
      end

      # Handle special attributes of the target cell
      # @param entity [Vanilla::Components::Entity] The entity moving
      # @param target_cell [Vanilla::MapUtils::Cell] The target cell
      def handle_special_cell_attributes(entity, target_cell)
        # Enhanced debugging for stairs
        @logger.debug("Checking if cell has special attributes: [#{target_cell.row}, #{target_cell.column}]")
        @logger.debug("Cell is stairs? #{target_cell.stairs?}")
        @logger.debug("Entity has stairs component? #{entity.has_component?(:stairs)}")

        # Check for stairs
        if entity.has_component?(:stairs) && target_cell.stairs?
          stairs_component = entity.get_component(:stairs)
          old_value = stairs_component.found_stairs
          stairs_component.found_stairs = true
          @logger.info("STAIRS FOUND: Entity found stairs at [#{target_cell.row}, #{target_cell.column}]")
          @logger.info("STAIRS FOUND: Changed found_stairs from #{old_value} to #{stairs_component.found_stairs}")
        end

        # Additional special cell attributes can be handled here
      end

      # Update the entity's position based on direction
      # @param position [Vanilla::Components::PositionComponent] The position component
      # @param direction [Symbol] The movement direction
      # @param speed [Float] The movement speed
      def update_position(position, direction, speed)
        # For grid-based movement, speed is typically 1 (move 1 cell)
        # But we include it for future time-based movement systems
        case direction
        when :north
          position.row -= speed.to_i
        when :south
          position.row += speed.to_i
        when :east
          position.column += speed.to_i
        when :west
          position.column -= speed.to_i
        end
      end

      # Log the movement for debugging
      # @param entity [Vanilla::Components::Entity] The entity that moved
      # @param direction [Symbol] The movement direction
      # @param old_position [Array<Integer>] The original position [row, col]
      # @param new_position [Array<Integer>] The new position [row, col]
      def log_movement(entity, direction, old_position, new_position)
        @logger.info("Entity moved #{direction} from #{old_position} to #{new_position}")

        # If this is a player entity, add a message to the message system
        if entity.is_a?(Vanilla::Entities::Player)
          # Get the message system using the service locator pattern
          message_system = Vanilla::Messages::MessageSystem.instance

          if message_system
            # Translate direction for user-friendly message
            message_system.log_message("exploration.move",
                                    category: :movement,
                                    metadata: { direction: direction })
          end
        end
      end
    end
  end
end