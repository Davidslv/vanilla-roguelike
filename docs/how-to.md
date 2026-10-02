# How-To

Task recipes for working on Vanilla. For the why behind the structure, read [architecture.md](architecture.md) first.

## Add a component

Components are data. Logic goes in systems. The custom cop `ECS/ComponentBehavior` (in `rubocop/cop/ecs/`) flags components that grow behaviour.

1. Create `lib/vanilla/components/<name>_component.rb`. Use [`position_component.rb`](../lib/vanilla/components/position_component.rb) as the model:
   - subclass `Component` and call `super()` in `initialize`
   - return a symbol from `type`
   - implement `to_hash` and `self.from_hash`
   - call `Component.register(YourComponent)` after the class

   `register` only works if `YourComponent.new` succeeds with no arguments; otherwise it silently skips the class (as it does for `PositionComponent`). Give arguments defaults if you need the component to round-trip through `Component.from_hash`.
2. Add a `require_relative` line in [`lib/vanilla/components.rb`](../lib/vanilla/components.rb).
3. Add a spec in `spec/lib/vanilla/components/` that checks the `to_hash` / `from_hash` round trip.
4. Attach it to entities in [`lib/vanilla/entity_factory.rb`](../lib/vanilla/entity_factory.rb).

## Add a system

1. Create `lib/vanilla/systems/<name>_system.rb`, subclassing `Vanilla::Systems::System`.
2. Implement `update(_delta_time)`. Find entities with `entities_with(:component_a, :component_b)`.
3. Publish state changes with `emit_event(:event_name, { ... })`. Keep the system stateless: read and write components, not instance variables.
4. Add a `require_relative` line in [`lib/vanilla/systems.rb`](../lib/vanilla/systems.rb).
5. Register it in `Game#setup_world` in [`lib/vanilla/game.rb`](../lib/vanilla/game.rb) with a priority. The current order is in [architecture.md](architecture.md#systems). Give it a priority no other system uses if order matters: the order between equal priorities is not guaranteed.
6. Also register it in [`spec/support/headless_game.rb`](../spec/support/headless_game.rb), which mirrors `setup_world` for integration specs.
7. Add the system to the priority table in [AGENTS.md](../AGENTS.md#system-order). A spec checks that table against `game.rb`.

## Add a command

1. Create `lib/vanilla/commands/<name>_command.rb`, subclassing `Vanilla::Commands::Command`, with `execute(world)`.
2. Map a key to it in `InputHandler#process_command` ([`lib/vanilla/input_handler.rb`](../lib/vanilla/input_handler.rb)).
3. Update the key table in the [README](../README.md#playing).
4. Spec it in `spec/lib/vanilla/commands/`. Execute the command against a world and assert on components and events.

## Add an event type

1. Add an entry to `EVENTS` in [`lib/vanilla/events/types.rb`](../lib/vanilla/events/types.rb) with a name, description and data shape. A constant (`YOUR_EVENT`) is defined for it automatically.
2. Regenerate the event reference:

   ```bash
   bundle exec ruby scripts/generate_events_md.rb
   ```

   This rewrites [events.md](events.md). Commit it with the change.

## Re-record replay tapes

Tapes in `spec/fixtures/tapes/` pin the exact event stream of a recorded run. If you change behaviour on purpose, `replay_tapes_spec.rb` fails. Re-record in the same pull request:

```bash
bundle exec ruby scripts/record_tape.rb --all          # every tape
bundle exec ruby scripts/record_tape.rb <name>         # one tape
```

Review the `events.jsonl` diff. It should show only the change you meant. If recording aborts with `Tape::CoverageError`, the run no longer reaches the scenario the tape exists for; the key script needs re-deriving. Details: [spec/fixtures/tapes/README.md](../spec/fixtures/tapes/README.md).

## Reproduce a bug

Every run prints its seed. Rerun with it:

```bash
./bin/play.rb --seed=12345 --difficulty=1
```

`--dev-mode` disables field of view so you can see the whole map.

## Read the logs

Each run writes a log to `logs/development/` under the directory you started the game from (normally the repo root). Set the level with `VANILLA_LOG_LEVEL` (`debug`, `info`, `warn`, `error`, `fatal`; default `info`):

```bash
VANILLA_LOG_LEVEL=debug ./bin/play.rb
```

In a second terminal, follow the newest log:

```bash
./scripts/log_monitor.rb
```

## Inspect the event log

Each run also writes its events to `event_logs/<session>.jsonl`. To turn a session into an HTML timeline in `event_visualizations/`:

```bash
ruby scripts/visualize_events.rb
```

It lists the sessions and asks which one to render.

## Generate class diagrams

```bash
bundle exec ruby scripts/analyze_codebase_mermaid.rb
```

Writes `core.mmd`, `components.mmd`, `systems.mmd` and `full.mmd` to the current directory. Move them into `docs/diagrams/` to update the committed copies.

## Find unused code

```bash
bundle exec ruby scripts/code_analyzer.rb lib            # unused classes and methods
bundle exec ruby scripts/code_analyzer.rb lib --full     # full report
```

The analysis is static and partial: some files fail to parse and are skipped with an error line, and methods called dynamically (such as every command's `execute`) show as unused. Treat results as leads, not proof.
