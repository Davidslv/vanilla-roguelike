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
  def key_for(direction)
    { north: 'k', south: 'j', east: 'l', west: 'h' }.fetch(direction)
  end

  def cell_at(game, row, column)
    game.grid[row, column]
  end

  def player_cell(game)
    cell_at(game, *game.player_position)
  end

  # First direction from the cell with a linked neighbour.
  # @return [Array(Symbol, Vanilla::MapUtils::Cell)]
  def linked_direction(cell)
    [:north, :south, :east, :west].each do |direction|
      neighbour = cell.public_send(direction)
      return [direction, neighbour] if neighbour && cell.linked?(neighbour)
    end
    raise 'maze cell has no linked neighbour'
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

  # Place a goblin on a cell linked to the player's, so one key press walks
  # the player into it. The goblin's movement component is removed so it
  # stands still: a hunting monster would step into the player during the
  # same frame and the two would swap cells before collision detection runs.
  def stage_adjacent_monster(game)
    direction, target = linked_direction(player_cell(game))
    monster = Vanilla::EntityFactory.create_monster('goblin', target.row, target.column, 20, 5)
    monster.remove_component(:movement)
    game.world.add_entity(monster)
    game.current_level.add_entity(monster)
    game.current_level.update_grid_with_entity(monster)
    [key_for(direction), monster]
  end

  describe 'movement' do
    it 'moves the player when a movement key is pressed' do
      game = described_class.new(seed: seed)
      game.start
      remove_monsters(game)

      direction, target = linked_direction(player_cell(game))
      game.press(key_for(direction))

      expect(game.player_position).to eq([target.row, target.column])
      expect(game.events(:entity_moved)).not_to be_empty
    end
  end

  describe 'the Fight/Run menu' do
    it 'raises the menu when the player walks into a monster' do
      game = described_class.new(seed: seed)
      game.start
      remove_monsters(game)
      key, monster = stage_adjacent_monster(game)

      game.press(key)

      monster_position = monster.get_component(:position)
      expect(game.player_position).to eq([monster_position.row, monster_position.column])
      expect(game.selection_mode?).to be(true)
      expect(game.message_system.valid_menu_option?('1')).to be(true)
      expect(game.message_system.valid_menu_option?('2')).to be(true)
      expect(game.events(:entities_collided)).not_to be_empty
    end

    it 'resolves combat when the fight key is pressed' do
      game = described_class.new(seed: seed)
      game.start
      remove_monsters(game)
      key, monster = stage_adjacent_monster(game)
      game.press(key)
      expect(game.selection_mode?).to be(true)

      game.press('1')

      expect(game.world.get_entity(monster.id)).to be_nil
      expect(game.events(:combat_attack)).not_to be_empty
      death_events = game.events(:combat_death)
      expect(death_events.map { |e| e.data[:entity_id] }).to include(monster.id)
    end
  end

  describe 'stairs' do
    # Direction that moves from one cell to an adjacent one.
    def direction_between(from, to)
      return :north if to.row < from.row
      return :south if to.row > from.row
      return :east if to.column > from.column

      :west
    end

    it 'triggers a level transition when the player steps onto the stairs' do
      game = described_class.new(seed: seed)
      game.start
      remove_monsters(game)

      stairs_position = game.world.find_entity_by_tag(:stairs).get_component(:position)
      stairs_cell = cell_at(game, stairs_position.row, stairs_position.column)
      standing_cell = stairs_cell.links.first
      game.player.get_component(:position).set_position(standing_cell.row, standing_cell.column)
      # Level#entities starts empty after maze generation and is only synced
      # from world entities by MovementSystem#move. A real player has always
      # moved before reaching the stairs; teleporting skips that sync, so
      # MoveCommand's stairs check would miss. Sync the way the engine does.
      game.current_level.entities.clear
      game.world.entities.each_value { |entity| game.current_level.add_entity(entity) }

      game.press(key_for(direction_between(standing_cell, stairs_cell)))

      expect(game.events(:level_transitioned)).not_to be_empty
      expect(game.current_level.difficulty).to eq(2)
      expect(game.player_position).to eq([0, 0])
    end
  end

  describe 'spec hygiene' do
    it 'writes no event log files during a run' do
      before_files = Dir.glob('event_logs/*').sort

      game = described_class.new(seed: seed)
      game.start
      direction, = linked_direction(player_cell(game))
      game.press(key_for(direction))

      expect(Dir.glob('event_logs/*').sort).to eq(before_files)
    end

    it 'leaves the ServiceRegistry clean after cleanup' do
      game = described_class.new(seed: seed)
      game.start
      game.cleanup

      expect(Vanilla::ServiceRegistry.get(:event_manager)).to be_nil
      expect(Vanilla::ServiceRegistry.get(:message_system)).to be_nil
    end
  end
end
