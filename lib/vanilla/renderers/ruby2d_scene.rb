# frozen_string_literal: true

module Vanilla
  module Renderers
    # A pure, Ruby2D-free description of one frame of the game: WHAT to draw,
    # not HOW. It reads the same world state the TerminalRenderer does (grid,
    # cell links for walls, the player's VisibilityComponent for fog of war) and
    # produces plain data structs.
    #
    # bin/play_gui.rb turns this scene into actual Ruby2D shapes. Keeping the
    # translation logic here (with no SDL/Ruby2D dependency) means it can be unit
    # tested headlessly, and the graphical binding stays a trivial loop.
    class Ruby2DScene
      # state: :visible | :explored | :hidden
      Tile = Struct.new(:row, :column, :state, :glyph, keyword_init: true)
      # side: :east | :south — an edge that is NOT a passage (a wall)
      Wall = Struct.new(:row, :column, :side, keyword_init: true)
      Hud  = Struct.new(:hp, :max_hp, :seed, :difficulty, :rows, :columns, :algorithm, keyword_init: true)
      Scene = Struct.new(:rows, :columns, :tiles, :walls, :hud, keyword_init: true)

      # Build a scene from the current world state.
      # @param world [Vanilla::World]
      # @param seed [Integer, nil] shown in the HUD
      # @return [Scene, nil] nil when no grid exists yet (before maze generation)
      def self.build(world, seed: nil)
        grid = world.grid
        return nil unless grid

        player = world.find_entity_by_tag(:player)
        visibility = player&.get_component(:visibility)
        dev_mode = player&.get_component(:dev_mode)
        fov_active = !visibility.nil? && !dev_mode&.fov_disabled

        tiles = []
        walls = []

        grid.rows.times do |row|
          grid.columns.times do |col|
            cell = grid[row, col]
            state = cell_state(row, col, fov_active, visibility)

            tiles << Tile.new(row: row, column: col, state: state, glyph: glyph_for(cell, state))
            walls.concat(walls_for(cell, row, col, grid, state))
          end
        end

        Scene.new(rows: grid.rows, columns: grid.columns, tiles: tiles, walls: walls,
                  hud: build_hud(world, player, grid, seed))
      end

      # @return [Symbol] :visible, :explored or :hidden for a cell
      def self.cell_state(row, col, fov_active, visibility)
        return :visible unless fov_active
        return :visible if visibility.tile_visible?(row, col)
        return :explored if visibility.tile_explored?(row, col)

        :hidden
      end

      # The character to draw for a cell, mirroring the terminal renderer: hidden
      # cells show nothing, explored cells show terrain only (actors hidden), and
      # visible cells show whatever currently occupies them.
      # @return [String, nil]
      def self.glyph_for(cell, state)
        case state
        when :hidden then nil
        when :explored then terrain_glyph(cell.tile)
        else cell.tile || Vanilla::Support::TileType::FLOOR
        end
      end

      # Replace actor glyphs with floor so explored-but-unseen tiles reveal the
      # map without leaking where the player/monsters currently are.
      # @return [String]
      def self.terrain_glyph(tile)
        actors = [
          Vanilla::Support::TileType::PLAYER,
          Vanilla::Support::TileType::MONSTER,
          Vanilla::Support::TileType::STAIRS
        ]
        actors.include?(tile) ? Vanilla::Support::TileType::FLOOR : (tile || Vanilla::Support::TileType::FLOOR)
      end

      # East/south wall segments for a cell that isn't hidden (a wall exists
      # wherever two adjacent cells are not linked by a passage).
      # @return [Array<Wall>]
      def self.walls_for(cell, row, col, grid, state)
        return [] if state == :hidden

        segments = []
        if col < grid.columns - 1 && !cell.linked?(cell.east)
          segments << Wall.new(row: row, column: col, side: :east)
        end
        if row < grid.rows - 1 && !cell.linked?(cell.south)
          segments << Wall.new(row: row, column: col, side: :south)
        end
        segments
      end

      # @return [Hud]
      def self.build_hud(world, player, grid, seed)
        health = player&.get_component(:health)
        Hud.new(
          hp: health&.current_health,
          max_hp: health&.max_health,
          seed: seed,
          difficulty: world.current_level&.difficulty,
          rows: grid.rows,
          columns: grid.columns,
          algorithm: world.current_level&.algorithm
        )
      end
    end
  end
end
