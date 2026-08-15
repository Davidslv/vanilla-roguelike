# frozen_string_literal: true

require 'spec_helper'
require_relative '../support/headless_game'

# Smoke specs proving the headless driver harness (Proposal 012, issue #130).
# Each spec drives the real game loop through HeadlessGame#press with no
# terminal attached, then asserts on world state and captured events.
RSpec.describe HeadlessGame, type: :integration do
  # Any fixed seed keeps a spec deterministic; the helpers below derive the
  # actual moves from the generated maze, so the value itself is arbitrary.
  let(:seed) { 20_260_815 }

  after do
    Vanilla::ServiceRegistry.clear
  end

  # Map a movement direction to the key the real game binds it to.
  KEY_FOR = { north: 'k', south: 'j', east: 'l', west: 'h' }.freeze

  def cell_at(game, row, column)
    game.grid[row, column]
  end

  def player_cell(game)
    cell_at(game, *game.player_position)
  end

  # First direction from the cell with a linked, walkable neighbour.
  # @return [Array(Symbol, Vanilla::MapUtils::Cell)]
  def linked_direction(cell)
    KEY_FOR.each_key do |direction|
      neighbour = cell.public_send(direction_accessor(direction))
      return [direction, neighbour] if neighbour && cell.linked?(neighbour)
    end
    raise 'maze cell has no linked neighbour'
  end

  def direction_accessor(direction)
    { north: :north, south: :south, east: :east, west: :west }.fetch(direction)
  end

  # Remove spawned monsters so movement specs cannot be interrupted by a
  # hunting monster stepping into the player mid-spec. Pending spawn events
  # are flushed first so their handlers still see the monsters they announce.
  def remove_monsters(game)
    game.flush_pending_events
    monsters = game.world.entities.values.select { |e| e.has_tag?(:monster) }
    monsters.each do |monster|
      game.world.remove_entity(monster.id)
      game.current_level.remove_entity(monster)
    end
  end

  describe 'movement' do
    it 'moves the player when a movement key is pressed' do
      game = described_class.new(seed: seed)
      game.start
      remove_monsters(game)

      direction, target = linked_direction(player_cell(game))
      game.press(KEY_FOR.fetch(direction))

      expect(game.player_position).to eq([target.row, target.column])
      expect(game.events(:entity_moved)).not_to be_empty
    end
  end
end
