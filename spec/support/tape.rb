# frozen_string_literal: true

require 'json'
require 'fileutils'
require_relative 'headless_game'
require_relative 'event_stream'

# Replay regression tapes (Proposal 012, issue #134).
#
# A tape pins one recorded run — seed, difficulty, key script — to the exact
# normalised event stream it produced when recorded. The replayer spec
# re-runs every tape and compares bit-exact, so any PR that changes
# behaviour fails loudly; an intentional change re-records its tapes in the
# same PR (bundle exec ruby scripts/record_tape.rb <name>).
#
# One directory per tape under spec/fixtures/tapes/:
#   <name>/tape.json     seed, difficulty, keys, covers — the event types
#                        the recorded stream must include, so a re-record
#                        cannot silently lose the scenario the tape pins
#   <name>/events.jsonl  the expected stream, one normalised {type, data}
#                        object per line, the same shape event_logs/ uses
#
# Streams compare in JSON space: the live capture is normalised by
# EventStream (entropy fields dropped, uuids canonicalised) then
# round-tripped through JSON, so symbols and strings canonicalise
# identically to what the fixture parsed from disk.
module Tape
  DIR = File.expand_path('../fixtures/tapes', __dir__)

  # Raised when a (re-)record's stream lost an event type the tape declares:
  # the scenario the tape exists to pin has changed shape, so the key script
  # needs re-deriving, not just the expectations rewriting.
  class CoverageError < StandardError; end

  module_function

  def names
    return [] unless File.directory?(DIR)

    Dir.children(DIR).select { |entry| File.directory?(File.join(DIR, entry)) }.sort
  end

  def load(name)
    JSON.parse(File.read(File.join(DIR, name, 'tape.json')))
  end

  def expected_events(name)
    File.readlines(File.join(DIR, name, 'events.jsonl')).map { |line| JSON.parse(line) }
  end

  # Run a key script through the headless driver and return the normalised
  # stream as parsed-JSON data (string keys) — the exact form the fixture
  # stores, so replay and fixture compare like for like.
  def play(seed:, difficulty:, keys:)
    game = HeadlessGame.new(seed: seed, difficulty: difficulty)
    game.start
    keys.chars.each { |key| game.press(key) }
    EventStream.normalize(game.events).map { |event| JSON.parse(JSON.generate(event)) }
  ensure
    game&.cleanup
  end

  # Create (or overwrite) a tape: write its metadata, then record its
  # expected stream.
  def create(name, seed:, difficulty:, keys:, covers: [])
    FileUtils.mkdir_p(File.join(DIR, name))
    metadata = { 'seed' => seed, 'difficulty' => difficulty, 'keys' => keys, 'covers' => covers }
    File.write(File.join(DIR, name, 'tape.json'), "#{JSON.pretty_generate(metadata)}\n")
    record(name)
  end

  # Re-run an existing tape's script and rewrite its expected stream.
  # @return [Array<Hash>] the recorded stream
  def record(name)
    tape = load(name)
    stream = play(seed: tape.fetch('seed'), difficulty: tape.fetch('difficulty'), keys: tape.fetch('keys'))
    missing = tape.fetch('covers', []) - stream.map { |event| event.fetch('type') }
    unless missing.empty?
      raise CoverageError,
            "tape #{name} no longer covers: #{missing.join(', ')} — re-derive its key script"
    end

    File.write(File.join(DIR, name, 'events.jsonl'), stream.map { |event| "#{JSON.generate(event)}\n" }.join)
    stream
  end

  # nil when the streams are identical; otherwise a message naming the first
  # diverging event with both sides pretty-printed. A stream that ends early
  # or runs long mismatches at the first index only one side has.
  def mismatch_message(name, expected, actual)
    index = (0...[expected.size, actual.size].max).find { |position| expected[position] != actual[position] }
    return nil unless index

    <<~MESSAGE
      tape #{name}: expected #{expected.size} events, replay produced #{actual.size}; first mismatch at event #{index}
      expected: #{pretty(expected[index])}
        actual: #{pretty(actual[index])}
    MESSAGE
  end

  def pretty(event)
    event.nil? ? '(no event — stream ended)' : JSON.pretty_generate(event)
  end
end
