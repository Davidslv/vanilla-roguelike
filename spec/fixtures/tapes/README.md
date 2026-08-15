# Replay regression tapes

A tape is a recorded run of the real game: a seed, a difficulty, and a key
script (`tape.json`), plus the exact event stream that run produces
(`events.jsonl`). The replayer spec (`spec/integration/replay_tapes_spec.rb`)
re-runs every tape through the headless driver and asserts the normalised
event stream matches bit for bit. Any PR that changes behaviour, intentionally
or not, fails the replay loudly.

## Layout

```
spec/fixtures/tapes/<name>/tape.json     seed, difficulty, keys, covers
spec/fixtures/tapes/<name>/events.jsonl  expected normalised event stream
```

`covers` lists the event types the tape exists to guard (e.g.
`combat_death`, `level_transitioned`). Recording aborts if a re-record no
longer produces them.

## Recording

```
bundle exec ruby scripts/record_tape.rb <name>          re-record one tape
bundle exec ruby scripts/record_tape.rb --all           re-record every tape
bundle exec ruby scripts/record_tape.rb <name> --seed=N --keys=SCRIPT \
  [--difficulty=D] [--covers=type1,type2]               create a new tape
```

## The re-record rule

A tape failing is information, never an obstacle. When your PR changes
behaviour on purpose (new mechanic, tuning change, event payload change),
re-record the affected tapes **in the same PR** and let the reviewer see the
event-stream diff alongside the code that caused it. If the failure was not
intentional, the tape just caught a regression: fix the code, not the tape.

If a re-record aborts with `Tape::CoverageError`, the declared scenario no
longer happens under that seed and key script (the coverage was lost, not
just reshaped). Re-derive the key script for the new behaviour, or record a
new tape, rather than weakening `covers`.
