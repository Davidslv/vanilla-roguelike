require_relative 'system'

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
    class MovementSystem < System
      # Initialize a new movement system
      # @param world_or_grid [World, Grid] The world or grid this system will use
      def initialize(world_or_grid)
        if world_or_grid.is_a?(Vanilla::World)
          # New ECS style: initialize with world
          super(world_or_grid)
          @direct_grid = nil
        else
          # Legacy style: initialize with grid
          @world = nil
          @direct_grid = world_or_grid
        end
        @logger = Vanilla::Logger.instance
      end

      # Update method called once per frame
      # @param delta_time [Float] Time since last update
      def update(delta_time)
        return unless @world # Skip if initialized with direct grid

        # Get all entities with position and movement components
        movable_entities = entities_with(:position, :movement)

        movable_entities.each do |entity|
          process_entity_movement(entity)
        end
      end

      # Process movement for an entity
      # @param entity [Entity] The entity to process
      def process_entity_movement(entity)
        # Skip if entity has no input component or no movement direction
        return unless entity.has_component?(:input)

        input = entity.get_component(:input)
        direction = input.move_direction
        return unless direction

        # Process the movement
        move(entity, direction)

        # Clear movement direction after processing
        input.set_move_direction(nil)
      end

      # Move an entity in a direction
      # @param entity [Entity] The entity to move
      # @param direction [Symbol] The direction to move (:north, :south, :east, :west)
      # @return [Boolean] Whether the movement was successful
      def move(entity, direction)
        return false unless can_process?(entity)

        # Get the position and movement components
        position = entity.get_component(:position)
        movement = entity.get_component(:movement)

        # Skip if movement is not active
        return false unless movement.active?

        # Normalize the direction
        direction = normalize_direction(direction)

        # Get the grid - either from world or direct grid
        if @world
          @grid = @world.current_level.grid
        else
          @grid = @direct_grid
        end
        return false unless @grid

        # Get current grid cell
        current_cell = @grid[position.row, position.column]
        return false unless current_cell

        # Get target cell based on direction
        target_cell = get_target_cell(current_cell, direction)
        return false unless target_cell

        # Check if we can move to the target cell
        return false unless can_move_to?(current_cell, target_cell, direction)

        # Save the old position for logging
        old_position = { row: position.row, column: position.column }

        # Update the entity's position
        update_position(position, direction, movement.speed)

        # Handle any special cell attributes
        handle_special_cell_attributes(entity, target_cell)

        # Log the movement
        log_movement(entity, direction, old_position, { row: position.row, column: position.column })

        # Emit movement event for other systems
        if @world
          emit_event(:entity_moved, {
            entity_id: entity.id,
            old_position: old_position,
            new_position: { row: position.row, column: position.column },
            direction: direction
          })
        end

        true
      end

      private

      # Check if this system can process the entity
      def can_process?(entity)
        entity.has_component?(:position) && entity.has_component?(:movement)
      end

      # Normalize the direction to a standard symbol
      def normalize_direction(direction)
        case direction.to_s.downcase
        when 'n', 'north', 'up', 'u', 'key_up'
          :north
        when 's', 'south', 'down', 'd', 'key_down'
          :south
        when 'e', 'east', 'right', 'r', 'key_right'
          :east
        when 'w', 'west', 'left', 'l', 'key_left'
          :west
        else
          direction
        end
      end

      # Get the target cell based on the current cell and direction
      def get_target_cell(cell, direction)
        case direction
        when :north
          @grid[cell.row - 1, cell.column] if cell.row > 0
        when :south
          @grid[cell.row + 1, cell.column] if cell.row < @grid.rows - 1
        when :east
          @grid[cell.row, cell.column + 1] if cell.column < @grid.columns - 1
        when :west
          @grid[cell.row, cell.column - 1] if cell.column > 0
        else
          nil
        end
      end

      # Check if the entity can move to the target cell
      def can_move_to?(current_cell, target_cell, direction)
        # Check if cells are linked (i.e., no wall between them)
        current_cell.linked?(target_cell)
      end

      # Handle special cell attributes (like stairs)
      def handle_special_cell_attributes(entity, target_cell)
        # Enhanced debugging for stairs
        @logger.debug("Checking if cell has special attributes: [#{target_cell.row}, #{target_cell.column}]")

        # Check for stairs
        if defined?(Vanilla::Support::TileType) &&
           Vanilla::Support::TileType.const_defined?(:STAIRS) &&
           target_cell.tile == Vanilla::Support::TileType::STAIRS

          @logger.info("Entity encountered stairs at [#{target_cell.row}, #{target_cell.column}]")

          # Update the stairs component if the entity has one
          if entity.has_component?(:stairs)
            stairs_component = entity.get_component(:stairs)
            if stairs_component.respond_to?(:found=)
              stairs_component.found = true
            elsif stairs_component.respond_to?(:found_stairs=)
              stairs_component.found_stairs = true
            end
            @logger.debug("Updated stairs component")
          end

          # Emit a stairs found event
          emit_event(:stairs_found, { entity_id: entity.id }) if @world
        end
      end

      # Update the entity's position
      def update_position(position, direction, speed)
        # For grid-based movement, speed is typically 1 (move 1 cell)
        # But we include it for future time-based movement systems
        case direction
        when :north
          position.set_position(position.row - 1, position.column)
        when :south
          position.set_position(position.row + 1, position.column)
        when :east
          position.set_position(position.row, position.column + 1)
        when :west
          position.set_position(position.row, position.column - 1)
        end
      end

      # Log movement for debugging
      def log_movement(entity, direction, old_position, new_position)
        @logger.info("Entity moved #{direction} from [#{old_position[:row]}, #{old_position[:column]}] to [#{new_position[:row]}, #{new_position[:column]}]")
      end

      # Helper for using emit_event even when @world is nil
      def emit_event(event_type, data = {})
        if @world
          super
        else
          # Log the event for legacy code
          @logger.debug("Event: #{event_type} - #{data.inspect}")
        end
      end
    end
  end
end