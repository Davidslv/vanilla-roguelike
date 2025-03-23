require_relative 'system'

module Vanilla
  module Systems
    class MovementSystem < System
      def initialize(world_or_grid)
        if world_or_grid.is_a?(Vanilla::World)
          super(world_or_grid)
          @direct_grid = nil
        else
          @world = nil
          @direct_grid = world_or_grid
        end
        @logger = Vanilla::Logger.instance
      end

      def update(delta_time)
        return unless @world
        movable_entities = entities_with(:position, :movement)
        movable_entities.each { |entity| process_entity_movement(entity) }
      end

      def process_entity_movement(entity)
        return unless entity.has_component?(:input)
        input = entity.get_component(:input)
        direction = input.move_direction
        return unless direction
        move(entity, direction)
        input.set_move_direction(nil)
      end

      def move(entity, direction)
        return false unless can_process?(entity)
        position = entity.get_component(:position)
        movement = entity.get_component(:movement)
        return false unless movement.active?

        direction = normalize_direction(direction)
        grid = @world ? @world.current_level.grid : @direct_grid
        return false unless grid

        current_cell = grid[position.row, position.column]
        return false unless current_cell

        target_cell = get_target_cell(current_cell, direction)
        return false unless target_cell

        return false unless can_move_to?(current_cell, target_cell, direction)

        old_position = { row: position.row, column: position.column }
        update_position(position, direction, movement.speed)
        handle_special_cell_attributes(entity, target_cell)
        log_movement(entity, direction, old_position, { row: position.row, column: position.column })

        emit_event(:entity_moved, {
          entity_id: entity.id,
          old_position: old_position,
          new_position: { row: position.row, column: position.column },
          direction: direction
        }) if @world

        true
      end

      private

      def can_process?(entity)
        entity.has_component?(:position) && entity.has_component?(:movement)
      end

      def normalize_direction(direction)
        case direction.to_s.downcase
        when 'n', 'north', 'up', 'u', 'key_up' then :north
        when 's', 'south', 'down', 'd', 'key_down' then :south
        when 'e', 'east', 'right', 'r', 'key_right' then :east
        when 'w', 'west', 'left', 'l', 'key_left' then :west
        else direction
        end
      end

      def get_target_cell(cell, direction)
        case direction
        when :north then cell.north
        when :south then cell.south
        when :east then cell.east
        when :west then cell.west
        else nil
        end
      end

      def can_move_to?(current_cell, target_cell, direction)
        current_cell.linked?(target_cell) && Vanilla::Support::TileType.walkable?(target_cell.tile)
      end

      def handle_special_cell_attributes(entity, target_cell)
        @logger.debug("Checking cell: [#{target_cell.row}, #{target_cell.column}]")
        if target_cell.tile == Vanilla::Support::TileType::STAIRS
          @logger.info("Stairs at [#{target_cell.row}, #{target_cell.column}]")
          emit_event(:stairs_found, { entity_id: entity.id }) if @world
        end
      end

      def update_position(position, direction, speed)
        case direction
        when :north then position.set_position(position.row - 1, position.column)
        when :south then position.set_position(position.row + 1, position.column)
        when :east then position.set_position(position.row, position.column + 1)
        when :west then position.set_position(position.row, position.column - 1)
        end
      end

      def log_movement(entity, direction, old_position, new_position)
        @logger.info("Entity moved #{direction} from [#{old_position[:row]}, #{old_position[:column]}] to [#{new_position[:row]}, #{new_position[:column]}]")
      end

      def emit_event(event_type, data = {})
        @world ? super : @logger.debug("Event: #{event_type} - #{data.inspect}")
      end
    end
  end
end
