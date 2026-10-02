# Vanilla Roguelike

[![Test Suite](https://github.com/Davidslv/vanilla-roguelike/actions/workflows/test.yml/badge.svg)](https://github.com/Davidslv/vanilla-roguelike/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Vanilla is a terminal roguelike written in plain Ruby, inspired by the 1980 [Rogue](https://en.wikipedia.org/wiki/Rogue_(video_game)). It has procedurally generated mazes, turn-based movement and combat, monsters, loot, field of view, and an Entity-Component-System architecture. Every run is seeded, so you can replay it exactly, and every game event is logged so you can inspect it.

![Vanilla Roguelike Demo](https://github.com/user-attachments/assets/4dc9e47d-a8e9-49b1-b852-802e15b9436d)

## The book

Vanilla is the companion code to **[Building Your Own Roguelike: A Practical Guide](https://www.amazon.com/Building-Your-Own-Roguelike-Hands-ebook/dp/B0G1RBWF6V)**. The book builds this game from scratch and explains the ECS pattern, the event system, and the maze algorithms step by step.

Also available as [paperback](https://www.amazon.com/dp/B0G1SGN181) and a [PDF](https://davidslv.gumroad.com/l/building-your-own-roguelike).

> [!TIP]
> You can read the whole book for free in the [web edition](https://davidslv.uk/books/vanilla-roguelike/).

## Quickstart

You need the Ruby version in [`.ruby-version`](.ruby-version) and Bundler.

```bash
git clone https://github.com/Davidslv/vanilla-roguelike.git
cd vanilla-roguelike
bundle install
./bin/play.rb
```

> [!TIP]
> On macOS, `./install.sh` sets everything up for you: Homebrew, rbenv, the right Ruby, and the gems.

Full steps, including Linux: [docs/getting-started.md](docs/getting-started.md).

## Playing

Find the stairs to go down a level. Each level is a new maze, with more monsters as you go down.

| On screen | Means |
|---|---|
| `@` | You |
| `M` | A monster. Walk into it to choose: attack or run away |
| `%` | Stairs to the next level |
| `+---+` and `\|` | Walls |
| blank | Somewhere you haven't seen yet |

| Key | Action |
|---|---|
| `h` `j` `k` `l` | Move west, south, north, east |
| `m` | Open or close the message menu |
| `1`, `2`, `i`, ... | Pick a menu option (the key is shown next to it) |
| `f` | Toggle field of view |
| `q` or `Ctrl+C` | Quit |

> [!NOTE]
> Arrow keys don't work. Use `h` `j` `k` `l`.

> [!WARNING]
> While a menu is open, `q` and `Ctrl+C` do nothing. Close the menu with `m` first. The first key after closing it is also ignored, so press `q` twice. Tracked in [#146](https://github.com/Davidslv/vanilla-roguelike/issues/146).

Options:

```bash
./bin/play.rb --seed=12345       # Play the same maze and monsters again
./bin/play.rb --difficulty=3     # Start at level 3 (1-5)
./bin/play.rb --dev-mode         # See the whole map (field of view off)
./bin/play.rb --help             # All options
```

> [!TIP]
> The seed is shown at the top of the screen. Put it in bug reports: it lets anyone replay your exact game.

## Development

```bash
bundle exec rspec       # 650+ examples, including replay tapes and a fuzzer
bundle exec rubocop     # Lint
```

> [!IMPORTANT]
> Both must pass before a pull request is merged; CI runs them on every push. If you change how the game behaves on purpose, the replay tapes will fail. Re-record them in the same pull request: see [docs/how-to.md](docs/how-to.md#re-record-replay-tapes).

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

The code is available under the [MIT License](LICENSE).

> [!NOTE]
> The MIT License covers the code only. The book is a separate work and is not included.
