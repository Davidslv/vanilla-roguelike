# frozen_string_literal: true

require 'spec_helper'
require_relative '../support/headless_game'
require_relative '../support/stairs_bot'

# Stairs-seeking certifier (Proposal 012, issue #132).
#
# The headline claim of the proposal: every generated dungeon is completable
# by an automated player. StairsBot plays the real game through the headless
# driver -- pathfinding to the stairs with the same Dijkstra distance-field
# machinery monster pursuit uses, fighting through every contact -- and this
# spec certifies a fixed corpus of seeds.
#
# The corpus example is tagged :certifier so its cost is tunable in CI later
# (exclude with `--tag ~certifier`, or deepen the run with CERTIFIER_DEPTH).
RSpec.describe 'Stairs-seeking certifier', type: :integration do
  after { Vanilla::ServiceRegistry.clear }

  # Per-level key-press budget, chosen empirically. Across seeds 1-100 the
  # worst level-1 run needs 21 presses (median 13): MazeSystem#ensure_path
  # always carves a greedy corridor from spawn to stairs, so a route never
  # exceeds ~Manhattan distance on the fixed 8x14 grid, plus a couple of
  # menu answers per fight. 300 is a hard ceiling that stays meaningful even
  # if generation changes to honour the maze's full winding paths (bounded
  # by 112 cells).
  let(:turn_budget) { 300 }

  # Any seed works; this one is pinned because its level 1 forces at least
  # one fight on the way to the stairs, which the end-to-end example asserts.
  let(:known_seed) { 3 }

  def certify(seed, turn_budget:, target_depth: 2)
    game = HeadlessGame.new(seed: seed)
    game.start
    StairsBot.new(game).play(target_depth: target_depth, turn_budget: turn_budget)
  ensure
    game&.cleanup
  end

  describe 'end to end on a known seed' do
    it 'reaches the stairs from spawn, fighting through contact, using only key presses' do
      game = HeadlessGame.new(seed: known_seed)
      game.start

      result = StairsBot.new(game).play(target_depth: 2, turn_budget: turn_budget)

      expect(game.current_level.difficulty).to eq(2)
      expect(game.events(:level_transitioned)).not_to be_empty
      expect(game.events(:combat_attack)).not_to be_empty
      expect(result.depth).to eq(2)
      expect(result.keys).to include('1')
      expect(result.keys).to all(match(/\A[hjkl1]\z/))
    ensure
      game&.cleanup
    end
  end

  describe 'failure diagnostics' do
    it 'names the seed, turn count and key script, and the script replays the run exactly' do
      expect { certify(known_seed, turn_budget: 5) }.to raise_error(StairsBot::CertificationFailure) do |error|
        expect(error.seed).to eq(known_seed)
        expect(error.keys.size).to eq(5)
        expect(error.message).to include("seed #{known_seed}")
        expect(error.message).to include("#{error.turns} turns")
        expect(error.message).to include(error.keys.join)

        replay = HeadlessGame.new(seed: known_seed)
        replay.start
        script = error.keys
        script.each { |key| replay.press(key) }
        expect(replay.player_position).to eq(error.player_position)
        expect(replay.turn).to eq(error.turns)
      ensure
        replay&.cleanup
      end
    end
  end

  describe 'the corpus', :certifier do
    it 'certifies seeds 1 to 100 within the turn budget' do
      target_depth = Integer(ENV.fetch('CERTIFIER_DEPTH', 2))

      failures = (1..100).filter_map do |seed|
        certify(seed, target_depth: target_depth, turn_budget: turn_budget)
        nil
      rescue StairsBot::CertificationFailure => e
        e.message
      rescue StandardError => e
        # A crash before the bot is even playing (maze generation, game
        # start) must still name its seed and not abort the corpus.
        Vanilla::ServiceRegistry.clear
        "seed #{seed} crashed outside play: #{e.class}: #{e.message}"
      end

      expect(failures).to eq([])
    end
  end
end
