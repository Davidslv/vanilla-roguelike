# frozen_string_literal: true

require_relative 'system'

module Vanilla
  module Systems
    # Drives hostile monsters to hunt the player.
    #
    # Each turn, every monster that can SEE a hostile target (line of sight via
    # its VisibilityComponent, refreshed by FOVSystem) takes one step toward that
    # target along the maze's shortest path. The path is followed by descending a
    # Dijkstra distance field rooted at the target: the monster moves to the
    # linked neighbour with the lowest distance-to-target. When a monster steps
    # onto the player's cell, the existing collision -> MessageSystem flow raises
    # the Fight/Run menu (see #player_monster_pair there).
    #
    # Priority 2.6: after FOVSystem (2.5) so sight lines are fresh, and before
    # CollisionSystem (3) so a monster reaching the player is detected the same
    # turn.
    #
    # Scope (Phase 2, Proposal 011): monsters target the PLAYER only. Targeting
    # is gated by Vanilla::Factions.hostile?, so extending to arbitrary hostile
    # factions (monster infighting, allied NPCs) is a later, small change.
    class MonsterAISystem < System
      def update(_delta_time = nil)
        target = @world.find_entity_by_tag(:player)
        return unless target

        grid = @world.grid
        return unless grid

        target_cell = cell_for(grid, target)
        return unless target_cell

        # Distance from the target to every reachable cell; monsters walk down it.
        distances = target_cell.distances

        monsters.each do |monster|
          next unless Vanilla::Factions.hostile?(monster, target)
          next unless can_see?(monster, target)

          step_toward(monster, grid, distances)
        end
      end

      private

      # Living, hunt-capable monsters (have position, movement, sight and faction).
      # @return [Array<Entity>]
      def monsters
        entities_with(:position, :movement, :visibility, :faction).select do |entity|
          entity.has_tag?(:monster)
        end
      end

      # Whether the monster currently has line of sight to the target's tile.
      # @return [Boolean]
      def can_see?(monster, target)
        visibility = monster.get_component(:visibility)
        position = target.get_component(:position)
        visibility.tile_visible?(position.row, position.column)
      end

      # Move the monster one cell down the distance gradient toward the target.
      def step_toward(monster, grid, distances)
        monster_cell = cell_for(grid, monster)
        return unless monster_cell

        current_distance = distances[monster_cell]
        return unless current_distance # target unreachable from the monster's cell

        next_cell = monster_cell.links
                                .select { |cell| distances[cell] }
                                .min_by { |cell| distances[cell] }
        return unless next_cell && distances[next_cell] < current_distance

        direction = direction_between(monster_cell, next_cell)
        return unless direction

        movement_system&.move(monster, direction)
      end

      # Resolve the cardinal direction from a cell to one of its linked neighbours.
      # @return [Symbol, nil]
      def direction_between(from_cell, to_cell)
        return :north if to_cell == from_cell.north
        return :south if to_cell == from_cell.south
        return :east if to_cell == from_cell.east
        return :west if to_cell == from_cell.west

        nil
      end

      # @return [Cell, nil] the grid cell an entity currently occupies
      def cell_for(grid, entity)
        position = entity.get_component(:position)
        grid[position.row, position.column]
      end

      # The MovementSystem actually executes (and validates) the step, keeping
      # all grid/tile bookkeeping in one place. Looked up the same way commands
      # locate sibling systems.
      def movement_system
        @movement_system ||= @world.systems.find do |system, _priority|
          system.is_a?(Vanilla::Systems::MovementSystem)
        end&.first
      end
    end
  end
end
