# frozen_string_literal: true

require 'spec_helper'
require_relative '../support/headless_game'

# Issue #159: the player's death ends the game and says why. Before this,
# CombatSystem removed the player entity and the loop kept running without one.
RSpec.describe 'Game over', type: :integration do # rubocop:disable RSpec/DescribeClass -- a flow across World, systems and Game
  let(:seed) { 20_261_003 }

  def key_for(direction)
    { north: 'k', south: 'j', east: 'l', west: 'h' }.fetch(direction)
  end

  # Clear the level, then put an unbeatable, stationary troll on a cell
  # linked to the player's, so one key walks the player into it.
  def stage_deadly_monster(game)
    game.flush_pending_events
    game.world.entities.values.select { |e| e.has_tag?(:monster) }.each do |monster|
      game.world.remove_entity(monster.id)
      game.current_level.remove_entity(monster)
    end

    row, column = game.player_position
    cell = game.grid[row, column]
    direction = [:north, :south, :east, :west].find { |dir| cell.public_send(dir) && cell.linked?(cell.public_send(dir)) }
    target = cell.public_send(direction)

    troll = Vanilla::EntityFactory.create_monster('troll', target.row, target.column, 1_000, 50)
    troll.remove_component(:movement)
    game.world.add_entity(troll)
    game.current_level.add_entity(troll)
    [key_for(direction), troll]
  end

  describe 'killed in combat (headless)' do
    let(:game) { HeadlessGame.new(seed: seed) }

    after do
      game.cleanup
      Vanilla::ServiceRegistry.clear
    end

    it 'ends the game with the combat cause, the killer and the floor' do
      game.start
      key, troll = stage_deadly_monster(game)
      game.player.get_component(:health).current_health = 1

      game.press(key)
      game.press('1') # Attack: the fight runs until one side dies

      expect(game.world.game_over?).to be(true)
      expect(game.world.game_over).to include(cause: :combat, killer_id: troll.id, killer_name: 'Troll', floor: 1)
      expect(game.events(:player_died).size).to eq(1)
      expect(game.recent_messages.map(&:content)).to include('death.player_dies')
      expect(game.player).not_to be_nil
    end
  end

  describe 'the real game loop after a death' do
    let(:keyboard) { HeadlessGame::ScriptedKeyboard.new }

    # Construct the real Game the way game_lifecycle_spec does: no event
    # files, and the SIGINT handler Game#initialize installs is restored.
    def with_real_game
      allow(Vanilla::Events::EventManager).to receive(:new).and_wrap_original do |original, *|
        original.call(store_config: { file: false })
      end
      previous_trap = Signal.trap('INT') {}
      game = Vanilla::Game.new(seed: seed)
      game.world.display.instance_variable_set(:@keyboard_handler, keyboard)
      yield game
    ensure
      Signal.trap('INT', previous_trap) if previous_trap
      Vanilla::ServiceRegistry.clear
    end

    def capture_stdout
      original = $stdout
      $stdout = StringIO.new
      yield
      $stdout.string
    ensure
      $stdout = original
    end

    it 'shows the summary, waits for one key, then stops' do
      with_real_game do |game|
        game.world.systems.find { |s, _| s.is_a?(Vanilla::Systems::MazeSystem) }.first.update(nil)
        game.world.player_died(cause: :starvation)
        keyboard.push('x')

        output = capture_stdout { game.send(:game_loop) }

        expect(game.world.quit?).to be(true)
        expect(output).to include("You reached floor 1. Seed: #{seed}.")
        expect(output).to include('Press any key to exit.')
        expect { keyboard.wait_for_input }.to raise_error(/no key queued/)
      end
    end
  end
end
