# frozen_string_literal: true

require 'spec_helper'

# Filename intentionally matches the lib file (ruby2d_scene.rb) rather than
# RuboCop's digit-split inflection (ruby2_d_scene).
# rubocop:disable RSpec/SpecFilePathFormat
RSpec.describe Vanilla::Renderers::Ruby2DScene do
  # rubocop:enable RSpec/SpecFilePathFormat
  subject(:scene) { described_class.build(world, seed: 99) }

  let(:grid) { Vanilla::MapUtils::Grid.new(2, 2) }
  let(:world) { Vanilla::World.new }
  let(:level) { Vanilla::Level.new(grid: grid, difficulty: 2, algorithm: 'TestAlgo') }

  let(:visible_tiles) { [[0, 0]] }
  let(:explored_tiles) { [[0, 0], [0, 1]] }
  let(:with_visibility) { true }
  let(:player) do
    Vanilla::Entities::Entity.new.tap do |e|
      e.add_tag(:player)
      e.add_component(Vanilla::Components::PositionComponent.new(row: 0, column: 0))
      e.add_component(Vanilla::Components::HealthComponent.new(max_health: 100, current_health: 80))
      if with_visibility
        visibility = Vanilla::Components::VisibilityComponent.new(vision_radius: 3)
        visible_tiles.each { |(r, c)| visibility.add_visible_tile(r, c) }
        visibility.explored_tiles.merge(explored_tiles)
        e.add_component(visibility)
      end
    end
  end

  before do
    # Passage east from (0,0); wall to the south of (0,0).
    grid[0, 0].link(cell: grid[0, 1], bidirectional: true)
    grid[0, 0].tile = Vanilla::Support::TileType::PLAYER
    grid[0, 1].tile = Vanilla::Support::TileType::MONSTER
    grid[1, 0].tile = Vanilla::Support::TileType::FLOOR
    grid[1, 1].tile = Vanilla::Support::TileType::FLOOR

    world.set_level(level)
    world.add_entity(player)
  end

  def tile_at(row, col)
    scene.tiles.find { |t| t.row == row && t.column == col }
  end

  describe '.build' do
    it 'returns nil when there is no grid yet' do
      empty_world = Vanilla::World.new
      expect(described_class.build(empty_world)).to be_nil
    end

    it 'describes the full grid' do
      expect(scene.rows).to eq(2)
      expect(scene.columns).to eq(2)
      expect(scene.tiles.size).to eq(4)
    end

    it 'shows the player glyph on the currently visible cell' do
      tile = tile_at(0, 0)
      expect(tile.state).to eq(:visible)
      expect(tile.glyph).to eq(Vanilla::Support::TileType::PLAYER)
    end

    it 'hides actors on explored-but-not-visible cells (shows terrain only)' do
      tile = tile_at(0, 1)
      expect(tile.state).to eq(:explored)
      expect(tile.glyph).to eq(Vanilla::Support::TileType::FLOOR) # the monster is not leaked
    end

    it 'marks unexplored cells hidden with no glyph' do
      tile = tile_at(1, 1)
      expect(tile.state).to eq(:hidden)
      expect(tile.glyph).to be_nil
    end

    it 'emits a wall where adjacent cells are not linked' do
      expect(scene.walls).to include(
        an_object_having_attributes(row: 0, column: 0, side: :south)
      )
    end

    it 'does not emit a wall across a passage' do
      expect(scene.walls).not_to include(
        an_object_having_attributes(row: 0, column: 0, side: :east)
      )
    end

    it 'populates the HUD from world state' do
      expect(scene.hud).to have_attributes(
        hp: 80, max_hp: 100, seed: 99, difficulty: 2, rows: 2, columns: 2, algorithm: 'TestAlgo'
      )
    end
  end

  context 'when fog of war is off (no visibility component)' do
    let(:with_visibility) { false }

    it 'renders every cell as visible' do
      expect(scene.tiles.map(&:state).uniq).to eq([:visible])
    end
  end
end
