# Vanilla Roguelike

[![Test Suite](https://github.com/Davidslv/vanilla-roguelike/actions/workflows/test.yml/badge.svg)](https://github.com/Davidslv/vanilla-roguelike/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Vanilla is a terminal roguelike written in plain Ruby, inspired by the 1980 [Rogue](https://en.wikipedia.org/wiki/Rogue_(video_game)). It has procedurally generated mazes, turn-based movement and combat, monsters, loot, field of view, and an Entity-Component-System architecture with an event log you can replay.

![Vanilla Roguelike Demo](https://github.com/user-attachments/assets/4dc9e47d-a8e9-49b1-b852-802e15b9436d)

## The book

Vanilla is the companion code to **[Building Your Own Roguelike: A Practical Guide](https://www.amazon.com/Building-Your-Own-Roguelike-Hands-ebook/dp/B0G1RBWF6V)**. The book builds this game from scratch and explains the ECS pattern, the event system, and the maze algorithms step by step.

Also available as [paperback](https://www.amazon.com/dp/B0G1SGN181), a [PDF](https://davidslv.gumroad.com/l/building-your-own-roguelike), and a [free web edition](https://davidslv.uk/books/vanilla-roguelike/).

## Quickstart

You need the Ruby version in [`.ruby-version`](.ruby-version) and Bundler.

```bash
git clone https://github.com/Davidslv/vanilla-roguelike.git
cd vanilla-roguelike
bundle install
./bin/play.rb
```

On macOS, `./install.sh` installs rbenv and the right Ruby through Homebrew first. Full steps: [docs/getting-started.md](docs/getting-started.md).

## Playing

Find the stairs (`%`) to go down a level. Each level is a new maze.

| Key | Action |
|---|---|
| `h` `j` `k` `l` | Move west, south, north, east |
| `m` | Open or close the message menu |
| `1`, `2`, `i`, ... | Pick a menu option (the key is shown next to it) |
| `f` | Toggle field of view |
| `q` or `Ctrl+C` | Quit |

Arrow keys are not supported. While a menu is open, `q` and `Ctrl+C` are ignored: close it with `m` first. The first key after closing a menu is also swallowed, so press `q` twice to quit straight after.

```bash
./bin/play.rb --seed=12345       # Replay the same maze and monsters
./bin/play.rb --difficulty=3     # Start at level 3 (1-5)
./bin/play.rb --help             # All options
```

## Development

```bash
bundle exec rspec       # 600+ examples, including replay tapes and a fuzzer
bundle exec rubocop     # Lint (CI gate)
```

Both run in CI on every push and pull request.

## Documentation

| Doc | For |
|---|---|
| [docs/getting-started.md](docs/getting-started.md) | Install, run, first change |
| [docs/architecture.md](docs/architecture.md) | How the ECS, events and game loop fit together, why, and where the design strains |
| [docs/how-to.md](docs/how-to.md) | Recipes: add a component, system or command; debug with logs; re-record tapes |
| [docs/events.md](docs/events.md) | Every event type the game emits |
| [docs/coding-practices.md](docs/coding-practices.md) | Method ordering and Ruby conventions |
| [docs/proposals/](docs/proposals/) | Design proposals for larger features |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to propose and submit changes |
| [AGENTS.md](AGENTS.md) | Instructions for AI coding agents |

## Contributing

Bug fixes and small improvements are welcome as pull requests. Larger features start as an issue or a proposal. See [CONTRIBUTING.md](CONTRIBUTING.md), [SUPPORT.md](SUPPORT.md) and [GOVERNANCE.md](GOVERNANCE.md).

## License

The code is available under the [MIT License](LICENSE). The book is a separate work and is not covered by this license.
