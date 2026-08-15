# frozen_string_literal: true

require 'spec_helper'
require_relative '../support/headless_game'
require_relative '../support/event_stream'

# Determinism tripwire (Proposal 012, issue #131).
#
# The convention this spec enforces: every gameplay decision that consumes
# randomness must flow through the GLOBAL RNG (Kernel#rand / Array#sample /
# Array#shuffle with no explicit Random instance), which the game pins with
# srand(seed) at startup. Same seed plus same key script must then replay the
# same run, event for event. The certifier bot's "seed N failed" only
# reproduces, and a replay tape only replays, if this holds. A privately
# seeded `Random.new` anywhere in a system breaks the property silently —
# this spec is the tripwire that catches it.
#
# Entity ids and event ids/timestamps are entropy-based by design
# (SecureRandom.uuid, Time.now) and sit outside the contract; EventStream
# normalises them away before comparison.
RSpec.describe 'Determinism tripwire', type: :integration do
  # Any fixed seed works: the script below is derived from the maze that the
  # seed generates, so the run replays on every machine.
  let(:seed) { 20_260_815 }
  let(:script) { derive_script(seed) }

  after { Vanilla::ServiceRegistry.clear }

  it 'crosses movement, at least one combat resolution, and a level transition' do
    types = play_run(seed, script).map(&:type)

    expect(types).to include(:entity_moved)
    expect(types).to include(:combat_attack)
    expect(types).to include(:combat_death)
    expect(types).to include(:level_transitioned)
  end

  it 'replays the same seed and key script into an identical event stream' do
    first = EventStream.normalize(play_run(seed, script))
    second = EventStream.normalize(play_run(seed, script))

    expect(first).not_to be_empty
    expect(second).to eq(first)
  end

  # --- the scripted run ---------------------------------------------------

  # Every measured run stages the same fight and presses the same keys:
  # walk into a stationary goblin, fight it to the death, answer the loot
  # menu, then walk the maze to the stairs and descend. The script is
  # replayed blindly, so any run-to-run divergence comes from the game's
  # randomness, never from the spec adapting.
  def play_run(seed, script)
    game = HeadlessGame.new(seed: seed)
    game.start
    stage_fight(game)
    script.each { |key| game.press(key) }
    game.events
  ensure
    game.cleanup
  end

  # Derives the fixed key script for this seed by playing one exploratory
  # run. The maze-dependent parts (which direction the goblin is staged in,
  # the route to the stairs) are read from the generated grid; the only
  # dynamic part is how many menu keys the fight leaves to answer (the loot
  # drop menu), observed by pressing through it once.
  def derive_script(seed)
    game = HeadlessGame.new(seed: seed)
    game.start
    direction, goblin_cell = goblin_site(game)
    route = route_keys(game, goblin_cell)
    stage_fight(game)
    keys = [key_for(direction), '1'] # step into the goblin, choose Fight
    keys.each { |key| game.press(key) }
    while game.selection_mode?
      raise 'combat menus never cleared' if keys.size > 20

      keys << '1' # answer the follow-up menu (loot: pick up)
      game.press('1')
    end
    keys + route
  ensure
    game.cleanup
  end

  # Replace the maze's own monsters with one stationary goblin adjacent to
  # the player, so the fight happens at a scripted cell. Identical on both
  # runs because the maze (and so the chosen cell) is identical.
  def stage_fight(game)
    game.flush_pending_events
    game.world.entities.values.select { |entity| entity.has_tag?(:monster) }.each do |monster|
      game.world.remove_entity(monster.id)
      game.current_level.remove_entity(monster)
    end
    _, goblin_cell = goblin_site(game)
    goblin = Vanilla::EntityFactory.create_monster('goblin', goblin_cell.row, goblin_cell.column, 20, 5)
    goblin.remove_component(:movement)
    game.world.add_entity(goblin)
    game.current_level.add_entity(goblin)
  end

  # First linked neighbour of the player's cell in fixed compass order;
  # deterministic for a given maze.
  def goblin_site(game)
    cell = game.grid[*game.player_position]
    [:north, :south, :east, :west].each do |direction|
      neighbour = cell.public_send(direction)
      return [direction, neighbour] if neighbour && cell.linked?(neighbour)
    end
    raise 'player cell has no linked neighbour'
  end

  # Movement keys from the goblin's cell down to the stairs.
  def route_keys(game, from_cell)
    stairs_position = game.world.find_entity_by_tag(:stairs).get_component(:position)
    stairs_cell = game.grid[stairs_position.row, stairs_position.column]
    shortest_path(from_cell, stairs_cell)
      .each_cons(2)
      .map { |from, to| key_for(direction_between(from, to)) }
  end

  # Breadth-first search over cell links, the same passages MovementSystem
  # honours. Returns the full path including both endpoints.
  def shortest_path(start_cell, goal_cell)
    frontier = [[start_cell]]
    visited = [start_cell]
    until frontier.empty?
      path = frontier.shift
      return path if path.last == goal_cell

      (path.last.links - visited).each do |neighbour|
        visited << neighbour
        frontier << (path + [neighbour])
      end
    end
    raise 'no path from the goblin to the stairs'
  end

  def key_for(direction)
    { north: 'k', south: 'j', east: 'l', west: 'h' }.fetch(direction)
  end

  def direction_between(from, to)
    return :north if to.row < from.row
    return :south if to.row > from.row
    return :east if to.column > from.column

    :west
  end
end
