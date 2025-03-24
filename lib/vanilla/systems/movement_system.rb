# frozen_string_literal: true

# lib/vanilla/systems/movement_system.rb
require_relative 'system'

module Vanilla
  module Systems
    class MovementSystem < System
      def initialize(world_or_grid)
        super(world_or_grid)
        @logger = Vanilla::Logger.instance
      end

      def update(_delta_time)
        movable_entities = entities_with(:position, :movement, :input, :render)
        @logger.debug("Found #{movable_entities.size} movable entities")
        movable_entities.each { |entity| process_entity_movement(entity) }
      end

      def process_entity_movement(entity)
        input = entity.get_component(:input)
        direction = input.move_direction
        @logger.debug("Entity #{entity.id} direction: #{direction}")
        return unless direction

        success = move(entity, direction)
        @logger.debug("Movement success: #{success}")
        input.move_direction = nil if success
      end

      def move(entity, direction)
        @logger.debug("Starting move for entity #{entity.id}")

        position = entity.get_component(:position)
        @logger.debug("Position: [#{position.row}, #{position.column}]")

        render = entity.get_component(:render)
        @logger.debug("Render: to_hash #{render.to_hash}")

        movement = entity.get_component(:movement)
        @logger.debug("Movement active: #{movement.active?}")
        return false unless movement&.active?

        direction = normalize_direction(direction)
        @logger.debug("Normalized direction: #{direction}")

        grid = @world.current_level.grid
        @logger.debug("Grid rows: #{grid.rows}, columns: #{grid.columns}")
        return false unless grid

        current_cell = grid[position.row, position.column]
        @logger.debug("Current cell: #{current_cell ? "[#{current_cell.row}, #{current_cell.column}] Tile: #{current_cell.tile}" : 'nil'}")
        return false unless current_cell

        target_cell = get_target_cell(current_cell, direction)
        @logger.debug("Target cell: #{target_cell ? "[#{target_cell.row}, #{target_cell.column}] Tile: #{target_cell.tile}" : 'nil'}")
        return false unless target_cell && can_move_to?(current_cell, target_cell, direction)

        old_position = { row: position.row, column: position.column }
        position.set_position(target_cell.row, target_cell.column)

        handle_special_cell_attributes(entity, target_cell)
        log_movement(entity, direction, old_position, { row: position.row, column: position.column })

        emit_event(
          :entity_moved,
          {
            entity_id: entity.id,
            old_position: old_position,
            new_position: { row: position.row, column: position.column },
            direction: direction
          }
        )

        grid[old_position[:row], old_position[:column]].tile = Vanilla::Support::TileType::EMPTY
        grid[position.row, position.column].tile = render.character

        true
      rescue StandardError => e
        @logger.error("Error in move: #{e.message}\n#{e.backtrace.join("\n")}")
        false
      end

      private

      def can_process?(entity)
        result = entity.has_component?(:position) && entity.has_component?(:movement) && entity.has_component?(:render)
        @logger.debug("Can process entity #{entity.id}? #{result}")
        result
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

      def can_move_to?(current_cell, target_cell, _direction)
        linked = current_cell.linked?(target_cell)
        walkable = Vanilla::Support::TileType.walkable?(target_cell.tile)
        @logger.debug("Can move to [#{target_cell.row}, #{target_cell.column}]? Linked: #{linked}, Walkable: #{walkable}")
        linked && walkable
      end

      def handle_special_cell_attributes(entity, target_cell)
        @logger.debug("Checking cell: [#{target_cell.row}, #{target_cell.column}]")
        if target_cell.tile == Vanilla::Support::TileType::STAIRS
          @logger.info("Stairs at [#{target_cell.row}, #{target_cell.column}] reached by entity #{entity.id}")
          emit_event(:stairs_found, { entity_id: entity.id })
          queue_command(:change_level, { difficulty: @world.current_level.difficulty + 1, player_id: entity.id })
        end
      end

      # def update_position(position, direction, _speed)
      #   case direction
      #   when :north then position.set_position(position.row - 1, position.column)
      #   when :south then position.set_position(position.row + 1, position.column)
      #   when :east then position.set_position(position.row, position.column + 1)
      #   when :west then position.set_position(position.row, position.column - 1)
      #   end
      # end

      def log_movement(_entity, direction, old_position, new_position)
        @logger.info("Entity moved #{direction} from [#{old_position[:row]}, #{old_position[:column]}] to [#{new_position[:row]}, #{new_position[:column]}]")
      end
    end
  end
end
