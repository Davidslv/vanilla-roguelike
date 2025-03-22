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
    # * Emitting movement events
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
    #   movement_system = MovementSystem.new(world, grid)
    #   movement_system.move(entity, :north)
    class MovementSystem < System
      # Initialize a new movement system
      # @param world [Vanilla::World] The world this system operates on
      # @param grid [Vanilla::MapUtils::Grid] The game grid
      def initialize(world, grid)
        super(world)
        @grid = grid
        @logger = Vanilla::Logger.instance

        # Subscribe to movement events
        world.subscribe(:movement_requested, self)
      end

      # Update method called each frame
      # @param delta_time [Float] Time in seconds since the last update
      def update(delta_time)
        # This system primarily works via events, but could process
        # automatic movement for AI entities here
      end

      # Handle events
      # @param event_type [Symbol] The type of event
      # @param data [Hash] Event data
      def handle_event(event_type, data)
        case event_type
        when :movement_requested
          handle_movement_request(data)
        end
      end

      private

      # Handle a movement request event
      # @param data [Hash] Event data with entity_id and direction
      def handle_movement_request(data)
        entity_id = data[:entity_id]
        direction = data[:direction]

        # Get the entity
        entity = @world.get_entity(entity_id)
        return unless entity

        # Try to move the entity
        move(entity, direction)
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

        # Store original position for event emission
        old_position = { row: position.row, column: position.column }

        # Update position
        update_position(position, direction_symbol, movement.speed)
        new_position = { row: position.row, column: position.column }

        # Check special attributes of the target cell
        check_cell_attributes(entity, target_cell)

        # Emit movement event
        emit_event(:entity_moved, {
          entity_id: entity.id,
          old_position: old_position,
          new_position: new_position,
          direction: direction_symbol
        })

        true
      end

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

      # Check special attributes of the target cell
      # @param entity [Vanilla::Components::Entity] The entity moving
      # @param target_cell [Vanilla::MapUtils::Cell] The target cell
      def check_cell_attributes(entity, target_cell)
        # Check for stairs
        if target_cell.stairs? && entity.has_component?(:stairs)
          stairs_component = entity.get_component(:stairs)

          # If stairs haven't been found yet, mark as found and emit event
          unless stairs_component.found_stairs?
            stairs_component.set_found_stairs(true)

            emit_event(:stairs_found, {
              entity_id: entity.id,
              position: { row: target_cell.row, column: target_cell.column }
            })
          end
        end

        # Additional special cell attributes can be handled here
        # and emit appropriate events
      end

      # Update the entity's position based on direction
      # @param position [Vanilla::Components::PositionComponent] The position component
      # @param direction [Symbol] The movement direction
      # @param speed [Float] The movement speed
      def update_position(position, direction, speed)
        case direction
        when :north
          position.set_position(position.row - speed.to_i, position.column)
        when :south
          position.set_position(position.row + speed.to_i, position.column)
        when :east
          position.set_position(position.row, position.column + speed.to_i)
        when :west
          position.set_position(position.row, position.column - speed.to_i)
        end
      end
    end
  end
end