# Getting Started

This page takes you from a fresh clone to a running game and a passing test suite. No prior knowledge of the codebase is assumed.

## 1. Install Ruby

Vanilla needs the Ruby version pinned in [`.ruby-version`](../.ruby-version). CI tests that version and the others listed in [`.github/workflows/test.yml`](../.github/workflows/test.yml), on Ubuntu and macOS.

Any version manager works. With rbenv:

```bash
rbenv install        # reads .ruby-version
gem install bundler
```

On macOS you can let the install script do this for you. It installs Homebrew (after asking), then rbenv and ruby-build from the [`Brewfile`](../Brewfile), then Ruby and the gems:

```bash
./install.sh
```

## 2. Install the gems

```bash
bundle install
```

The game itself only needs `i18n` and `logger`. The rest are test, lint and editor tools.

## 3. Play

```bash
./bin/play.rb
```

You are the `@`. Move with `h` `j` `k` `l`. Walk onto `%` to go down a level. Press `q` to quit. The full key list is in the [README](../README.md#playing).

Every run prints its seed at the top of the screen. Pass it back to get the same run:

```bash
./bin/play.rb --seed=12345
```

## 4. Run the checks

```bash
bundle exec rspec
bundle exec rubocop
```

Both must pass before a pull request is merged. The suite includes:

- unit specs under `spec/lib/`, mirroring `lib/`
- integration specs under `spec/integration/` that drive the real game headlessly
- replay tapes (`spec/fixtures/tapes/`) that fail if behaviour changes
- a random-walk fuzzer and a level certifier

## 5. Find your way around

```
bin/play.rb            Entry point and command-line options
bin/prototype.rb       A single-file prototype from the book, runs on its own
lib/vanilla/game.rb    Builds the world, registers systems, runs the loop
lib/vanilla/world.rb   ECS coordinator: entities, systems, command and event queues
lib/vanilla/components/  Pure data (position, health, render, ...)
lib/vanilla/systems/     Logic that runs each turn, in priority order
lib/vanilla/commands/    One object per player action
lib/vanilla/events/      Event types, manager, file storage
lib/vanilla/algorithms/  Maze generators
config/locales/en.yml    Message text
spec/                    Tests, same layout as lib/
scripts/                 Developer tools (log monitor, event visualizer, tape recorder)
docs/                    Architecture, how-to, events, proposals
```

## 6. Make a first change

A safe first change is a new message. Messages live in [`config/locales/en.yml`](../config/locales/en.yml) and are shown by `MessageSystem`. Change one, run the game, and run `bundle exec rspec`.

If the suite fails in `replay_tapes_spec.rb`, your change altered the game's event stream. See [Re-record replay tapes](how-to.md#re-record-replay-tapes).

## Where next

- [architecture.md](architecture.md) explains the ECS, the game loop, and the known limits of the design.
- [how-to.md](how-to.md) has recipes for adding components, systems and commands.
- [CONTRIBUTING.md](../CONTRIBUTING.md) explains how changes are proposed and reviewed.
