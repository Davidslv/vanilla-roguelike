# AGENTS.md

Instructions for AI coding agents working in this repository. Humans: see [CONTRIBUTING.md](CONTRIBUTING.md).

## What this is

Vanilla is a turn-based terminal roguelike in plain Ruby, built on an Entity-Component-System (ECS) with an event system. It is the companion code to a book, so readability matters as much as features.

## Gates

Both must pass before you report work as done. CI runs both.

```bash
bundle exec rspec        # all specs, including replay tapes and fuzzer
bundle exec rubocop      # lint, includes the custom ECS/ComponentBehavior cop
```

- Never add entries to `.rubocop_todo.yml` to make lint pass.
- Never edit `spec/fixtures/tapes/**/events.jsonl` by hand. If a behaviour change is intended, re-record with `bundle exec ruby scripts/record_tape.rb --all` and check the diff shows only the intended change. If the change was not intended, the tape caught a regression: fix the code.
- The game reads the terminal in raw mode. Do not run `./bin/play.rb` from an agent shell; it blocks waiting for keys. Use the headless harness (`spec/support/headless_game.rb`) to drive the real game in specs.

## Commands

```bash
bundle exec rspec spec/lib/vanilla/systems/movement_system_spec.rb   # one file
bundle exec rspec spec/integration/                                  # whole-game specs
bundle exec ruby scripts/generate_events_md.rb                       # after changing events/types.rb
bundle exec ruby scripts/record_tape.rb --all                        # after intended behaviour changes
```

## Layout

| Path | Contents |
|---|---|
| `bin/play.rb` | Entry point and CLI options (`--seed`, `--difficulty`, `--dev-mode`) |
| `lib/vanilla/game.rb` | Builds the world, registers systems, runs the loop |
| `lib/vanilla/world.rb` | ECS coordinator: entities, systems, command and event queues |
| `lib/vanilla/components/` | Data only. Each implements `type`, `to_hash`, `self.from_hash` and calls `Component.register` |
| `lib/vanilla/systems/` | Logic. Subclass `System`, query with `entities_with(...)`, publish with `emit_event` |
| `lib/vanilla/commands/` | One class per player action, `execute(world)` |
| `lib/vanilla/events/types.rb` | Every event type. `docs/events.md` is generated from it |
| `lib/vanilla/algorithms/` | Maze generators. Default is Recursive Backtracker |
| `config/locales/en.yml` | Message text (i18n) |
| `spec/lib/` | Unit specs mirroring `lib/` |
| `spec/integration/` | Whole-game specs via the headless harness |
| `spec/support/` | Headless harness, tape replayer, fuzzer, stairs bot |
| `docs/` | Architecture, how-to, events, proposals |

## System order

Systems run each turn in priority order, as registered in `Game#setup_world` (`lib/vanilla/game.rb`). `spec/support/headless_game.rb` mirrors the same list. A spec checks this table against `game.rb`.

| Priority | System |
|---|---|
| 0 | MazeSystem |
| 1 | InputSystem |
| 2 | MovementSystem |
| 2.5 | FOVSystem |
| 2.6 | MonsterAISystem |
| 3 | CombatSystem |
| 3 | CollisionSystem |
| 3 | LootSystem |
| 4 | MonsterSystem |
| 5 | MessageSystem |
| 10 | RenderSystem |

## Rules of the codebase

- Components hold data. Put logic in systems. Faction hostility lives in `Vanilla::Factions`, not in `FactionComponent`.
- Systems should not keep game state in instance variables. Read and write components.
- Emit an event for every state change another system or the log might care about.
- All randomness comes from the global seed (`srand` in `Game#start`). Any new `rand` call shifts later rolls and changes the tapes. That is fine if intended; re-record.
- Method order inside classes: `initialize`, lifecycle (`update`, `render`), state queries, event handlers, helpers, private. See `docs/coding-practices.md`.
- Keep methods short. Use guard clauses. Name magic numbers as constants.

## Tests

- Write the failing spec first. A bug fix needs a spec that fails without it.
- Prefer real collaborators over doubles at the terminal boundary; a plain stand-in hid a production bug before (PR #143). Use `instance_double` when you do double.
- New systems must also be registered in `spec/support/headless_game.rb`.

## Commits and PRs

- Branch from `main`. Short imperative commit subjects: `Fix NoMethodError on quit`.
- PR description: what changed, why, how it was tested, `Closes #N`. PRs are squash-merged.
- Larger features need a proposal in `docs/proposals/` first.

## Where to read more

- [docs/architecture.md](docs/architecture.md): design, rationale, and where the design strains
- [docs/how-to.md](docs/how-to.md): recipes for components, systems, commands, events, tapes
- [docs/events.md](docs/events.md): event reference
- [spec/fixtures/tapes/README.md](spec/fixtures/tapes/README.md): how replay tapes work
