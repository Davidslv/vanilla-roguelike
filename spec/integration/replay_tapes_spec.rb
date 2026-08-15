# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require_relative '../support/tape'

# Replay regression tapes (Proposal 012, issue #134).
#
# Part one, the mechanics: the Tape helper's fixture format round-trips
# through disk, playback is deterministic and serialises to plain JSON data,
# a re-record refuses to lose the coverage a tape declares, and a mismatch
# renders a readable diff of the first diverging event. The replayer over the
# committed fixtures builds on these guarantees.
RSpec.describe 'Replay regression tapes', type: :integration do
  after { Vanilla::ServiceRegistry.clear }

  describe 'the fixture format' do
    let(:dir) { Dir.mktmpdir('tapes') }

    before { stub_const('Tape::DIR', dir) }
    after { FileUtils.remove_entry(dir) }

    it 'round-trips a created tape through disk' do
      Tape.create('smoke', seed: 1, difficulty: 1, keys: 'jl', covers: ['entity_moved'])

      expect(Tape.names).to eq(['smoke'])
      tape = Tape.load('smoke')
      expect(tape.fetch('seed')).to eq(1)
      expect(tape.fetch('difficulty')).to eq(1)
      expect(tape.fetch('keys')).to eq('jl')
      expect(tape.fetch('covers')).to eq(['entity_moved'])
      expect(Tape.expected_events('smoke')).to eq(Tape.play(seed: 1, difficulty: 1, keys: 'jl'))
    end

    it 'refuses to record a tape whose run no longer covers its declared events' do
      expect do
        Tape.create('smoke', seed: 1, difficulty: 1, keys: 'jl', covers: ['combat_death'])
      end.to raise_error(Tape::CoverageError, /combat_death/)
    end
  end

  describe 'playback' do
    it 'is deterministic: two plays of the same script produce identical JSON streams' do
      first = Tape.play(seed: 1, difficulty: 1, keys: 'jjj')
      second = Tape.play(seed: 1, difficulty: 1, keys: 'jjj')

      expect(first).not_to be_empty
      expect(second).to eq(first)
    end

    it 'serialises every event to plain JSON data: type and data, string keys' do
      Tape.play(seed: 1, difficulty: 1, keys: 'j').each do |event|
        expect(event.keys).to contain_exactly('type', 'data')
        expect(event.fetch('type')).to be_a(String)
        expect(event.fetch('data')).to be_a(Hash)
      end
    end
  end

  describe 'the committed fixtures' do
    # The canonical scenarios and the event types each exists to pin
    # (issue #134's acceptance criteria). A tape may widen its covers;
    # this is the floor a re-record can never drop below.
    canonical_coverage = {
      'movement-level-transition' => %w[level_transitioned],
      'combat-death-loot' => %w[entities_collided combat_death loot_dropped]
    }

    it 'keeps at least two tapes on the shelf' do
      expect(Tape.names.size).to be >= 2
    end

    canonical_coverage.each do |name, types|
      it "pins #{name} to cover #{types.join(', ')}" do
        expect(Tape.load(name).fetch('covers')).to include(*types)
      end
    end

    Tape.names.each do |name|
      describe "tape #{name}" do
        it 'declares coverage its recorded stream includes' do
          types = Tape.expected_events(name).map { |event| event.fetch('type') }

          expect(types).to include(*Tape.load(name).fetch('covers'))
        end

        it 'replays bit-exact' do
          tape = Tape.load(name)
          expected = Tape.expected_events(name)

          actual = Tape.play(seed: tape.fetch('seed'), difficulty: tape.fetch('difficulty'),
                             keys: tape.fetch('keys'))

          expect(actual).to eq(expected), Tape.mismatch_message(name, expected, actual)
        end
      end
    end
  end

  describe 'the mismatch diff' do
    let(:expected) do
      [
        { 'type' => 'entity_moved', 'data' => {} },
        { 'type' => 'entity_moved', 'data' => { 'row' => 1 } }
      ]
    end

    it 'is nil when the streams match' do
      expect(Tape.mismatch_message('walk', expected, expected.map(&:dup))).to be_nil
    end

    it 'names the first mismatching index and shows both events' do
      actual = [expected[0], { 'type' => 'entity_moved', 'data' => { 'row' => 2 } }]

      message = Tape.mismatch_message('walk', expected, actual)

      expect(message).to include('first mismatch at event 1')
      expect(message).to include('"row": 1')
      expect(message).to include('"row": 2')
    end

    it 'reports a replay that ends early' do
      message = Tape.mismatch_message('walk', expected, expected.take(1))

      expect(message).to include('expected 2 events, replay produced 1')
      expect(message).to include('first mismatch at event 1')
      expect(message).to include('stream ended')
    end

    it 'reports a replay with extra trailing events' do
      actual = expected + [{ 'type' => 'combat_attack', 'data' => {} }]

      message = Tape.mismatch_message('walk', expected, actual)

      expect(message).to include('expected 2 events, replay produced 3')
      expect(message).to include('first mismatch at event 2')
      expect(message).to include('combat_attack')
    end
  end
end
