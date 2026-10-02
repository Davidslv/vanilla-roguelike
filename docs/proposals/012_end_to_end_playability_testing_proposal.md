# End-to-End Playability Testing (Headless Certification) - Proposal 012

## Status

**Accepted.** Design agreed 2026-08-15 from a code exploration session. Not yet implemented.

**Created:** 2026-08-15
**Project:** vanilla-roguelike
**Author:** David Silva
**Epic:** https://github.com/Davidslv/vanilla-roguelike/issues/129
**Sub-issues:**
- https://github.com/Davidslv/vanilla-roguelike/issues/130 — Build the headless driver harness
- https://github.com/Davidslv/vanilla-roguelike/issues/131 — Add the determinism tripwire spec
- https://github.com/Davidslv/vanilla-roguelike/issues/132 — Build the stairs-seeking certifier bot (seeds 1 to 100)
- https://github.com/Davidslv/vanilla-roguelike/issues/133 — Add the random-walk fuzzer
- https://github.com/Davidslv/vanilla-roguelike/issues/134 — Add replay regression tapes

## Summary

Prove the game is playable, and not broken, without a human at the keyboard. A headless test harness drives the real game through the same door a player uses (a key press into `InputHandler`), and four layers of automated play sit on top of it: a determinism tripwire, a stairs-seeking bot that certifies dungeons are completable, a random-walk fuzzer that hunts crashes and stuck states, and replay regression tapes. All of it runs in CI on every pull request.

## Problem Statement

Today "the game works" is verified by playing it. The evidence trail for PRs #123 and #124 was: green unit and integration suites, then a human terminal session the same evening (see `event_logs/events_20260630_175533.jsonl` and `event_logs/events_20260704_132108.jsonl`). That is a claim renewed by hand, not a property the suite proves.

The existing integration specs (for example `spec/integration/combat_spec.rb`) drive systems by emitting events directly and by setting component state. They test the machinery, but they never enter through the input path, so a regression in the key-to-command-to-world pipeline, a stuck menu, or an uncompletable generated dungeon would pass the suite and only surface when someone plays.

## Why this codebase makes it possible

The seams already exist; this proposal adds no new architecture, only a harness on top of what shipped.

| Ingredient | Where it lives | Why it matters |
|---|---|---|
| Programmatic input seam | `InputHandler#handle_input(key)` (`lib/vanilla/input_handler.rb`) | Takes a plain key string, queues a real command into `World`. The blocking terminal read is quarantined in `InputSystem` / `KeyboardHandler` and can simply be omitted. |
| Headless loop, proven | Ruby2D PoC commit `049fa68` | Already ran `handle_input` then `world.update(nil)` with no terminal attached. |
| Seeded runs | `Game` (`srand(@seed)`), `--seed` flag | Same seed reproduces the same dungeon. |
| Event tape | `EventManager` + `FileEventStore`, JSONL in `event_logs/` | Every run already records `key_pressed`, `entity_moved`, `combat_*`, `level_transitioned`. This is both the assertion substrate and a replay format. |
| Pathfinding | `Vanilla::Algorithms::Dijkstra`, `Cell#distances` | The bot's brain already exists; it shipped for monster pursuit in Proposal 011. |

## Proposed Solution

Four tiers, each building on the one below.

### Tier 0: determinism tripwire

One spec that runs a fixed key script on a fixed seed twice and asserts the two event streams are identical. Everything above depends on this property.

Known wrinkle: `map.rb` re-seeds through a global (`$seed = seed || rand(...)` then `srand($seed)`), and combat accuracy rolls `rand`. This works today because all randomness flows through `Kernel#rand` after `srand(@seed)`. Any future code that creates its own `Random` instance silently breaks replayability; this spec is the tripwire that catches it.

### Tier 1: headless driver

A small spec-support harness that builds the world the way `Game#setup_world` does, but omits `InputSystem` and `RenderSystem` (or nulls the display) and configures the event store with `file: false` so specs never pollute `event_logs/`. It exposes `press(key)`, which calls `handle_input(key)` then `world.update(nil)`, and it must handle both branches of the game loop, including the Fight/Run selection mode (`MessageSystem#selection_mode?`). Roughly thirty lines, and every tier above uses it.

### Tier 2: the certifier (bot playthroughs)

A stairs-seeking bot: Dijkstra from the player to the stairs, emit the key for each step, answer the Fight/Run menu with Fight when it fires. The assertion: for seeds 1 to 100, the bot reaches level N within a turn budget, with no exception and no stall. This is the sentence we want the suite to be able to say: every generated dungeon is completable by an automated player.

### Tier 3: random-walk fuzzing

Feed thousands of random valid keys across many seeds. After every turn, assert invariants: no exception raised, the player sits on a walkable linked cell, HP within bounds, menu mode always exitable. This catches the "broken" class (crashes, stuck states, walking through walls) that the goal-directed bot walks straight past. On failure, print the seed and the key script so the run reproduces exactly.

### Tier 4: replay regression tapes

A fixture is a seed plus a key sequence; the spec replays it through the driver and asserts the resulting event stream matches the recorded one, bit for bit. Any PR that changes behaviour, intentionally or not, fails loudly, and an intentional change re-records the tape in the same PR. Fresh tapes are recorded through the driver with known seeds; the 30 June and 4 July session logs serve as format references (they record keys but not the seed, so they cannot be replayed as-is).

### CI

`bin/run_tests` already runs on every push and PR via `.github/workflows/test.yml`. The tiers land as ordinary specs, so they ride the existing workflow; the certifier and fuzzer get tagged so their depth can be tuned if CI time becomes a problem.

## Decisions

#### D1: Enter through the key-press door

**Decision:** All end-to-end specs drive the game via `InputHandler#handle_input`, never by emitting events or mutating components directly.

**Alternatives considered:** Extending the existing integration-spec style (emit `:entity_moved`, call `handle_event` on systems by hand).

**Why this one:** The existing style tests the machinery but skips the input pipeline, the command queue, and the loop's menu branch. Entering through the same door a player uses is what makes these tests end-to-end; anything else re-tests what the unit suite already covers.

**Date:** 2026-08-15

#### D2: Determinism by convention, guarded by a tripwire

**Decision:** Keep the current `srand` plus `Kernel#rand` scheme and guard it with a determinism spec, rather than refactoring to an injected `Random` instance first.

**Alternatives considered:** Threading a dedicated `Random` through `Game`, `Map`, and `CombatSystem` before building anything on top.

**Why this one:** The refactor touches every random call site and delays the payoff; the tripwire spec gives the same safety signal for a fraction of the cost. If the tripwire starts firing regularly, that is the evidence the injection refactor has become worth its price.

**Date:** 2026-08-15

#### D3: Fixed seed corpus in CI

**Decision:** The certifier runs a fixed corpus (seeds 1 to 100), not fresh random seeds per run.

**Alternatives considered:** Randomising seeds each CI run for broader coverage over time.

**Why this one:** A CI failure must reproduce on the next run and on a laptop. Random seeds make red builds flaky and unactionable; the corpus can grow deliberately when a new seed exposes a bug.

**Date:** 2026-08-15

## Open Questions

- Turn budget for the certifier (per level, per seed): needs an empirical pass once the bot exists; start generous and tighten.
- Fuzzer depth in CI (keys per run, seeds per run) versus wall-clock cost on the two-OS matrix in `test.yml`.
- Whether `ChangeLevelCommand` / stairs placement guarantees stairs exist on every generated level; if not, that is a real finding the certifier will surface on day one.
