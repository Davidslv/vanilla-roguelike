#!/usr/bin/env ruby
# frozen_string_literal: true

# (Re-)records replay regression tapes (Proposal 012, issue #134).
#
# Usage:
#   bundle exec ruby scripts/record_tape.rb <name>          re-record one tape
#   bundle exec ruby scripts/record_tape.rb --all           re-record every tape
#   bundle exec ruby scripts/record_tape.rb <name> --seed=N --keys=SCRIPT \
#     [--difficulty=D] [--covers=type1,type2]               create a new tape
#
# A tape replays from its seed and key script alone, so recording is just
# re-running the script through the headless driver and rewriting the
# expected stream. A re-record that loses the event coverage the tape
# declares aborts (Tape::CoverageError): the scenario itself has changed,
# so the key script needs re-deriving, not the expectations rewriting
# (see spec/fixtures/tapes/README.md).

# Match the spec environment, so recorded streams are exactly the streams
# the replayer spec will observe.
ENV['VANILLA_TEST_MODE'] = 'true'
ENV['VANILLA_LOG_DIR'] ||= 'test/logs'

require 'optparse'
require_relative '../lib/vanilla'
require_relative '../lib/vanilla/events'
require_relative '../spec/support/tape'

def report(name, stream)
  tally = stream.map { |event| event.fetch('type') }.tally
  puts "recorded #{name}: #{stream.size} events (#{tally.map { |type, count| "#{type} x#{count}" }.join(', ')})"
end

options = {}
parser = OptionParser.new do |opts|
  opts.banner = 'Usage: bundle exec ruby scripts/record_tape.rb <name> [options]'
  opts.on('--all', 'Re-record every tape under spec/fixtures/tapes/') { options[:all] = true }
  opts.on('--seed=SEED', Integer, 'Seed for a new tape') { |seed| options[:seed] = seed }
  opts.on('--difficulty=LEVEL', Integer, 'Difficulty for a new tape (default 1)') { |level| options[:difficulty] = level }
  opts.on('--keys=SCRIPT', 'Key script for a new tape, e.g. jjl11lll') { |keys| options[:keys] = keys }
  opts.on('--covers=TYPES', Array, 'Event types the recorded stream must include') { |types| options[:covers] = types }
end
names = parser.parse(ARGV)

if options[:all]
  abort 'no tapes found under spec/fixtures/tapes/' if Tape.names.empty?
  Tape.names.each { |name| report(name, Tape.record(name)) }
elsif names.size != 1
  abort parser.to_s
elsif options[:seed]
  keys = options.fetch(:keys) { abort '--keys is required when creating a tape with --seed' }
  name = names.first
  report(name, Tape.create(name,
                           seed: options.fetch(:seed),
                           difficulty: options.fetch(:difficulty, 1),
                           keys: keys,
                           covers: options.fetch(:covers, [])))
else
  report(names.first, Tape.record(names.first))
end
