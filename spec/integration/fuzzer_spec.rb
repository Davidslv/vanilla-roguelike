# frozen_string_literal: true

require 'spec_helper'
require_relative '../support/headless_game'
require_relative '../support/fuzzer'
require_relative '../support/event_stream'

# Random-walk fuzzer (Proposal 012, issue #133).
#
# The certifier proves dungeons are completable; this spec hunts the other
# class of broken: crashes, stuck states, and impossible game states that
# goal-directed play walks straight past. RandomWalkFuzzer feeds seeded
# random key sequences through the headless driver and checks invariants
# after every single press (see spec/support/fuzzer.rb for the list).
#
# The corpus example is tagged :fuzz so its cost is tunable in CI
# (exclude with `--tag ~fuzz`, or deepen the run via FUZZ_SEEDS/FUZZ_KEYS).
RSpec.describe 'Random-walk fuzzer', type: :integration do
  # Fuzz depth, in ONE place: M seeds x N random key presses per seed.
  # Deepen locally or in a scheduled CI job with e.g. FUZZ_SEEDS=200.
  let(:fuzz_seeds) { Integer(ENV.fetch('FUZZ_SEEDS', 25)) }
  let(:fuzz_keys)  { Integer(ENV.fetch('FUZZ_KEYS', 150)) }

  after { Vanilla::ServiceRegistry.clear }

  def fuzz(seed, keys:, extra_invariants: {})
    game = HeadlessGame.new(seed: seed)
    game.start
    RandomWalkFuzzer.new(game, extra_invariants: extra_invariants).walk(keys: keys)
  ensure
    game&.cleanup
  end

  describe 'seeded key sequences' do
    it 'derives the whole walk from the run seed: same seed, same script, same events' do
      first_game = HeadlessGame.new(seed: 7)
      first_game.start
      first = RandomWalkFuzzer.new(first_game).walk(keys: 60)
      first_events = EventStream.normalize(first_game.events)
      first_game.cleanup

      second_game = HeadlessGame.new(seed: 7)
      second_game.start
      second = RandomWalkFuzzer.new(second_game).walk(keys: 60)

      expect(first.keys).not_to be_empty
      expect(second.keys).to eq(first.keys)
      expect(EventStream.normalize(second_game.events)).to eq(first_events)
    ensure
      second_game&.cleanup
    end

    it 'ends every walk by quitting through the real exit path' do
      result = fuzz(7, keys: 30)

      expect(result.keys.last).to eq('q')
      expect(result.quit).to be(true)
    end
  end

  describe 'failure diagnostics' do
    it 'names the seed and full key script, and replaying the script reproduces the run' do
      tripwire = { 'tripwire: never reach turn 3' => ->(game) { game.turn < 3 } }

      expect { fuzz(7, keys: 60, extra_invariants: tripwire) }
        .to raise_error(RandomWalkFuzzer::InvariantViolation) do |error|
          expect(error.seed).to eq(7)
          expect(error.keys).not_to be_empty
          expect(error.message).to include('tripwire: never reach turn 3')
          expect(error.message).to include('seed 7')
          expect(error.message).to include(error.keys.join)

          replay = HeadlessGame.new(seed: 7)
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

  describe 'the corpus', :fuzz do
    it 'walks M seeds x N random keys with zero invariant violations' do
      failures = (1..fuzz_seeds).filter_map do |seed|
        fuzz(seed, keys: fuzz_keys)
        nil
      rescue RandomWalkFuzzer::InvariantViolation => e
        e.message
      rescue StandardError => e
        # A crash before the walk even starts (maze generation, game start)
        # must still name its seed and not abort the corpus.
        Vanilla::ServiceRegistry.clear
        "seed #{seed} crashed outside the walk: #{e.class}: #{e.message}"
      end

      expect(failures).to eq([])
    end
  end
end
