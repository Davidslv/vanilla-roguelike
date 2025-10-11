# Vanilla Roguelike

Vanilla is a roguelike game written in Ruby, inspired by the original 1980's [Rogue game](https://en.wikipedia.org/wiki/Rogue_(video_game)). It features procedurally generated mazes, player movement, and a flexible architecture based on the Entity-Component-System pattern with an event-driven system for logging and debugging.

<!--
![Vanilla Game Screenshot](https://user-images.githubusercontent.com/136777/124296344-c3dff380-db51-11eb-9490-21968571608d.mov)
-->

![Vanilla Roguelike Demo](https://github.com/user-attachments/assets/4dc9e47d-a8e9-49b1-b852-802e15b9436d)



## Game Objective

Navigate your character (`@`) through the maze to find the stairs (`%`) that lead to the next level. As you progress, the mazes become more complex and dangerous!

## Getting Started

### Prerequisites

- Ruby (version specified in `.ruby-version`, currently 3.4.1)
- [rbenv](https://github.com/rbenv/rbenv) (recommended for Ruby version management)
- [Homebrew](https://brew.sh/) (for macOS users)

### Installation

#### Quick Install (Recommended)

```bash
./install.sh
```

#### Manual Installation

1. Install dependencies:
```bash
brew bundle
```

2. Install the required Ruby version:
```bash
rbenv install
```

3. Install bundler and dependencies:
```bash
gem install bundler
bundle install
```

## Running the Game

### Standard Play

The simplest way to play the game is to use the executable:

```bash
./bin/play.rb
```

## Game Controls

Use either Vim-style keys or arrow keys to navigate your character:

- **H** or **←** - Move left
- **J** or **↓** - Move down
- **K** or **↑** - Move up
- **L** or **→** - Move right
- **q** - Quit the game (may require multiple presses if you've been using arrow keys)

## Testing

Vanilla uses RSpec for unit testing. To run the test suite:

```bash
bundle exec rspec
```

To run specific tests:

```bash
# Run tests for a specific component
bundle exec rspec spec/lib/vanilla/components/

# Run a specific test file
bundle exec rspec spec/lib/vanilla/systems/movement_system_spec.rb
```

## Architecture Overview

Vanilla is built using a combination of design patterns that provide flexibility, modularity, and debuggability:

### Core Architecture

- **Game Class**: Implements the Game Loop pattern, managing the game lifecycle from initialization to cleanup
- **Level Management**: Manages the maze/dungeon structure and player position
- **Entity-Component-System**: Organizes game objects and behaviors in a modular fashion
- **Event System**: Provides event-driven architecture for logging, debugging, and game state tracking
- **Maze Generation**: Various algorithms for procedural maze creation
- **Rendering System**: Handles the visual representation of the game state


```text

bin/play.rb (Entry Point)
   |
   +--> Vanilla::Game (Game Logic)
          |
          +--> @world = Vanilla::World (ECS Coordinator)
          |       |
          |       +--> @entities (Hash of Entity objects)
          |       +--> @systems (Array of [System, Priority] pairs)
          |       +--> @event_queue, @command_queue, @display, etc.
          |
          +--> @player (Entity created via EntityFactory)
          +--> @maze_system (and other systems, added to @world)
          +--> Game Loop (calls @world.update)
```


### Key Design Patterns

#### Entity-Component-System (ECS)

The core of Vanilla's architecture is built on the ECS pattern:

- **Entities**: Game objects with a unique ID (e.g., Player, Monsters)
- **Components**: Data containers that define aspects of entities (e.g., Position, Tile)
- **Systems**: Logic that operates on entities with specific components (e.g., MovementSystem)

This pattern allows for flexible composition of game objects and clear separation between data and behavior.

#### Command Pattern

Input handling uses the Command pattern:

- `InputHandler` translates key inputs into command objects
- `MoveCommand`, `ExitCommand`, and other commands encapsulate actions
- `NullCommand` implements the Null Object pattern for handling unknown inputs

#### Event System

The event system provides several benefits:

- **Debugging**: Capture and analyze game events for troubleshooting
- **Decoupling**: Components communicate without direct dependencies
- **Game State Recording**: Record event logs for replay and analysis
- **Visualization**: Tools for visualizing event sequences and timing

## Maze Generation Algorithms

Vanilla implements several maze generation algorithms to create different types of labyrinths:

### Binary Tree

For each cell in the grid, it randomly creates a passage either north or east. This is the default algorithm.

### Aldous-Broder

A random walk algorithm that creates completely unbiased mazes.

### Recursive Backtracker

Creates mazes with long corridors and fewer dead ends.

### Recursive Division

Divides the space recursively, creating more boxy and rectangular mazes.

## Debugging and Logging

Vanilla includes a comprehensive logging system. Logs are stored in the `logs/` directory with timestamped filenames.

You can set the log level using the `VANILLA_LOG_LEVEL` environment variable:

```bash
VANILLA_LOG_LEVEL=debug ./bin/play.rb
```

Available log levels: `debug`, `info`, `warn`, `error`, `fatal`

### Log Monitoring

While running the game you can see the logs in real time to help debugging issues:

```bash
./scripts/log_monitor.rb
```


### Event Visualization

The event system includes visualization tools to help understand game behavior:

```bash
ruby scripts/visualize_events.rb
```

This will display the available sessions and allow you to select one to visualize.

## Project Structure

```
vanilla/
├── bin/                    # Executable scripts
├── docs/                   # Architecture documentation
├── event_logs/             # Stored event logs
├── event_visualizations/   # Generated event visualizations
├── examples/               # Example code and demos
├── lib/                    # Main source code
│   └── vanilla/
│       ├── algorithms/     # Maze generation algorithms
│       ├── components/     # ECS components
│       ├── entities/       # Game entities (Player, Monster)
│       ├── events/         # Event system implementation
│       │   └── storage/    # Event storage mechanisms
│       ├── map_utils/      # Grid and cell implementations
│       ├── systems/        # ECS systems (Movement, Monster)
│       └── support/        # Utility classes
├── logs/                   # Game logs
├── scripts/                # Utility scripts
├── spec/                   # Test files
└── coverage/               # Test coverage reports
```

## Contributing

Contributions are welcome! The project is still a work in progress with several areas for improvement:

1. **Complete ECS Implementation**: Adding more systems and components
2. **Event System Enhancements**: Additional event types and visualization options
3. **Game Features**: Combat system, inventory management, more monster types
4. **UI Improvements**: Better visualization, game stats display
5. **Performance Optimizations**: Spatial partitioning, rendering optimizations

## License

Vanilla is available under the MIT License.
