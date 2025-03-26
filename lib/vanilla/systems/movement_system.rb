# frozen_string_literal: true

# lib/vanilla/systems/movement_system.rb
require_relative 'system'

module Vanilla
  module Systems
    class MovementSystem < System
      class InvalidDirectionError < StandardError; end

      def initialize(world)
        super(world)
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
        @logger.debug("Entity #{entity} direction: #{direction}")
        return unless direction

        success = move(entity, direction)
        @logger.debug("Movement success: #{success}")
        input.move_direction = nil if success
      end

      def move(entity, direction)
        @logger.debug("Starting move for entity <<#{entity.class.name}>>")

        position = entity.get_component(:position)
        @logger.debug("Position: [#{position.row}, #{position.column}]")

        render = entity.get_component(:render)
        @logger.debug("Render: to_hash #{render.to_hash}")

        movement = entity.get_component(:movement)
        @logger.debug("Movement active: #{movement.active?}")
        return false unless movement&.active?

        @logger.debug("Movement direction: #{direction}")

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

        clear_old_position(grid, old_position)

        position.set_position(target_cell.row, target_cell.column)

        @world.current_level.update_grid_with_entity(entity)
        @logger.info("Entity moved #{direction} from [#{old_position[:row]}, #{old_position[:column]}] to [#{position.row}, #{position.column}]")

        emit_event(
          :entity_moved,
          {
            entity_id: entity.id,
            old_position: old_position,
            new_position: { row: position.row, column: position.column },
            direction: direction
          }
        )

        true
      rescue StandardError => e
        @logger.error("Error in move: #{e.message}\n#{e.backtrace.join("\n")}")
        false
      end

      def clear_old_position(grid, old_position)
        # Clear old position unless it’s a special cell (e.g., stairs)
        old_cell = grid[old_position[:row], old_position[:column]]

        unless old_cell.cell_type.stairs? || occupied_by_another_entity_except_player?(old_position)
          old_cell.tile = Vanilla::Support::TileType::EMPTY
          @logger.debug("Cleared old position [#{old_position[:row]}, #{old_position[:column]}] to EMPTY")
        end
      end

      def occupied_by_another_entity_except_player?(old_position)
        @world.current_level.entities.any? do |entity|
          entity.get_component(:position)&.row == old_position[:row] &&
            entity.get_component(:position)&.column == old_position[:column] &&
            entity.has_tag?(:player)
        end
      end

      private

      def can_process?(entity)
        result = entity.has_component?(:position) && entity.has_component?(:movement) && entity.has_component?(:render)
        @logger.debug("Can process entity #{entity}? #{result}")
        result
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
        # TODO: Check CellTypeFactory #setup_standard_types for walkable
        walkable = Vanilla::Support::TileType.walkable?(target_cell.tile)
        @logger.debug("Can move to [#{target_cell.row}, #{target_cell.column}]? Linked: #{linked}, Walkable: #{walkable}")
        linked && walkable
      end
    end
  end
end
