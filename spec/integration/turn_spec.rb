# frozen_string_literal: true

require 'spec_helper'
require_relative '../support/headless_game'

# Issue #160: one turn is one player action that takes time. Free actions
# (menus, toggles, unknown keys, walking into a wall) do not advance it.
RSpec.describe 'Turns', type: :integration do
  let(:seed) { 20_261_003 }
  let(:game) { HeadlessGame.new(seed: seed) }
  let(:keys) { { north: 'k', south: 'j', east: 'l', west: 'h' } }

  after do
    game.cleanup
    Vanilla::ServiceRegistry.clear
  end

  def clear_monsters
    game.flush_pending_events
    game.world.entities.values.select { |e| e.has_tag?(:monster) }.each do |monster|
      game.world.remove_entity(monster.id)
      game.current_level.remove_entity(monster)
    end
  end

  def player_cell
    game.grid[*game.player_position]
  end

  def open_direction
    keys.keys.find { |dir| player_cell.public_send(dir) && player_cell.linked?(player_cell.public_send(dir)) }
  end

  def walled_direction
    keys.keys.find { |dir| !(player_cell.public_send(dir) && player_cell.linked?(player_cell.public_send(dir))) }
  end

  def turns_ended
    game.events(:turn_ended).size
  end

  before do
    game.start
    clear_monsters
  end

  it 'ends one turn per step' do
    game.press(keys.fetch(open_direction))

    expect(turns_ended).to eq(1)
    expect(game.turn).to eq(1)
    expect(Vanilla.game_turn).to eq(1)
    expect(game.events(:turn_ended).last.data).to eq(turn: 1)
  end

  it 'costs nothing to walk into a wall' do
    game.press(keys.fetch(walled_direction))

    expect(turns_ended).to eq(0)
  end

  it 'costs nothing to toggle field of view, press an unknown key, or open and close the menu' do
    %w[f z m m].each { |key| game.press(key) }

    expect(turns_ended).to eq(0)
    expect(game.turn).to eq(0)
  end

  it 'costs one turn to step into a monster and one more to attack it' do
    target = player_cell.public_send(open_direction)
    goblin = Vanilla::EntityFactory.create_monster('goblin', target.row, target.column, 1, 1)
    goblin.remove_component(:movement)
    game.world.add_entity(goblin)
    game.current_level.add_entity(goblin)

    game.press(keys.fetch(open_direction))
    game.press('1')

    expect(turns_ended).to eq(2)
  end
end
