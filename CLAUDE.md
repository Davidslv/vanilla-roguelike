# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Vanilla is a roguelike game written in Ruby using Entity-Component-System (ECS) architecture with an event-driven system. The game features procedurally generated mazes, turn-based gameplay, and a modular design pattern inspired by the 1980s Rogue game.

## Commands

### Running the Game

```bash
./bin/play.rb                    # Start game with default settings
./bin/play.rb --seed=12345      # Start with specific random seed
./bin/play.rb --difficulty=3    # Set difficulty level (1-5)
./bin/play.rb --help            # Show all options
```

### Testing

```bash
bundle exec rspec                                        # Run all tests
bundle exec rspec spec/lib/vanilla/components/          # Run tests for a specific directory
bundle exec rspec spec/lib/vanilla/systems/movement_system_spec.rb  # Run a specific test file
```

### Code Quality

```bash
bundle exec rubocop              # Run linter
bundle exec rubocop -a           # Auto-fix safe violations
```

### Debugging and Logs

```bash
VANILLA_LOG_LEVEL=debug ./bin/play.rb  # Run with debug logging
./scripts/log_monitor.rb                # Monitor logs in real-time
ruby scripts/visualize_events.rb        # Visualize event logs
```

### Setup

```bash
./install.sh                     # Quick install (recommended)
# OR manual:
brew bundle                      # Install dependencies via Homebrew
rbenv install                    # Install Ruby version from .ruby-version
gem install bundler              # Install bundler
bundle install                   # Install gem dependencies
```

## Architecture

### ECS Pattern

The codebase is built around three core pillars:

1. **Entities** (`lib/vanilla/entities/`): Simple containers with unique IDs. The player, monsters, items, and stairs are all entities.

2. **Components** (`lib/vanilla/components/`): Pure data containers representing a single aspect of an entity. Examples:
   - `PositionComponent`: Location in grid (row, column)
   - `RenderComponent`: Visual representation (character, color)
   - `HealthComponent`: Health and damage state
   - `MovementComponent`: Movement capabilities
   - `InputComponent`: Player input state
   - `InventoryComponent`: Item storage
   - `CombatComponent`: Combat stats

3. **Systems** (`lib/vanilla/systems/`): Logic that operates on entities with specific component combinations. Systems run in priority order:
   - **MazeSystem (0)**: Generates procedural mazes
   - **InputSystem (1)**: Processes keyboard input
   - **MovementSystem (2)**: Moves entities
   - **CollisionSystem (3)**: Handles collisions
   - **MonsterSystem (4)**: Monster AI and pathfinding
   - **RenderSystem (10)**: Terminal rendering

### World Coordinator

The `World` class (`lib/vanilla/world.rb`) is the ECS coordinator that:
- Manages all entities in a hash by ID
- Maintains system registry with priorities
- Provides `query_entities(component_types)` to find entities with specific components
- Manages command and event queues
- Orchestrates the game loop via `update(delta_time)`

### Command Pattern

Input handling uses the Command pattern (`lib/vanilla/commands/`):
- `InputHandler` converts keystrokes to command objects
- Commands encapsulate actions: `MoveCommand`, `AttackCommand`, `ExitCommand`, etc.
- Commands are queued and executed by the `World`
- `NullCommand` handles unknown inputs (Null Object pattern)

### Event System

The event-driven architecture (`lib/vanilla/events/`) provides:
- Decoupled communication between systems
- Comprehensive logging stored in `event_logs/*.jsonl`
- Event replay and visualization tools
- Systems emit events like `entity_moved`, `collision_detected`, `combat_attack`
- `EventManager` publishes events to subscribers and stores them via `FileEventStore`

### Game Loop Flow

```
User Input → InputHandler → Command Queue → World.update()
  → Systems (priority order) → Emit Events → Process Commands
  → Render → Repeat
```

Each frame:
1. Systems update in priority order
2. Events are queued during system execution
3. After all systems run, events are processed and stored
4. Commands in queue are executed
5. Frame is rendered

## Key Files

- `lib/vanilla/game.rb`: Main game class with game loop implementation
- `lib/vanilla/world.rb`: ECS coordinator managing entities and systems
- `lib/vanilla/entity_factory.rb`: Factory for creating entities (player, monsters, items, stairs)
- `lib/vanilla/algorithms/`: Maze generation algorithms (Binary Tree, Aldous-Broder, Recursive Backtracker, Recursive Division)
- `lib/vanilla/map_utils/`: Grid and Cell implementations for maze structure
- `lib/vanilla/level.rb`: Level/dungeon management
- `lib/vanilla/display_handler.rb`: Terminal display management
- `lib/vanilla/keyboard_handler.rb`: Raw keyboard input handling

## Coding Practices

### Method Ordering in Classes

Follow this order for consistency (from `documents/coding_practices.md`):

1. Initialization (`initialize`)
2. Core lifecycle methods (`update`, `render`)
3. Interaction/state methods (e.g., `selection_mode?`)
4. Event handlers (`handle_event`)
5. Helper methods (grouped by purpose)
6. Private methods

### Ruby Conventions

- Use `snake_case` for methods and variables
- Use descriptive names that reveal intent
- Use `?` for predicate methods, `!` for mutating methods
- Keep methods under 10-15 lines
- Use early returns for guard clauses
- Define magic numbers as constants

### ECS Guidelines

**Components:**
- Should be pure data containers with minimal logic
- Single responsibility (one aspect of an entity)
- Must implement `type`, `to_hash`, and `self.from_hash` for serialization
- Register new components with `Component.register(YourComponent)`

**Systems:**
- Operate on entities by querying for component combinations
- Use `entities_with(:component1, :component2)` to query
- Should be stateless (read state from components)
- Emit events for important state changes
- Follow single responsibility principle

**Entities:**
- Created via `EntityFactory` for consistency
- Composed of components (composition over inheritance)
- Use tags (symbols) for classification (`:player`, `:monster`, `:item`)

### Custom RuboCop Cop

The codebase includes a custom cop `ECS/ComponentBehavior` (in `rubocop/cop/ecs/component_behavior`) to enforce that components remain data-focused and don't contain complex behavior.

## Testing

Tests use RSpec and follow the mirror structure of `lib/`:
- Component tests verify serialization and data integrity
- System tests use mocked components and entities
- Integration tests in `spec/integration/` test full feature flows
- Coverage reports are generated in `coverage/` directory

When writing tests:
- Mock external dependencies (event managers, loggers)
- Test component serialization round-trips (`to_hash` → `from_hash`)
- Verify systems query entities correctly
- Test edge cases (nil values, missing components, invalid states)

## Extending the Codebase

To add a new feature:

1. **Create Components**: Define data structures
   ```ruby
   class MyComponent < Component
     def type; :my_component; end
     def to_hash; {...}; end
     def self.from_hash(hash); ...; end
   end
   Component.register(MyComponent)
   ```

2. **Create System**: Implement processing logic
   ```ruby
   class MySystem < System
     def update(delta_time)
       entities = entities_with(:my_component, :position)
       entities.each { |e| process(e) }
     end
   end
   ```

3. **Register System**: Add to World with priority in `Game#initialize`
   ```ruby
   @world.add_system(MySystem.new(@world), priority: 5)
   ```

4. **Create Commands** (if needed): For user interactions
   ```ruby
   class MyCommand < Command
     def execute(world); ...; end
   end
   ```

5. **Emit Events**: For logging and system communication
   ```ruby
   world.emit_event(:my_event, { data: value })
   ```

## Maze Generation

Four algorithms available (in `lib/vanilla/algorithms/`):
- **Binary Tree** (default): Creates passages north or east
- **Aldous-Broder**: Completely unbiased, random walk
- **Recursive Backtracker**: Long corridors, fewer dead ends
- **Recursive Division**: Boxy, rectangular mazes

Grid structure uses linked cells where passages are explicitly stored as bidirectional links between adjacent cells.

## Event Visualization

Events are stored as JSONL in `event_logs/` with session IDs. Use visualization tools to debug:
- `scripts/visualize_events.rb`: Generate visualizations in `event_visualizations/`
- Events include timestamps, types, and arbitrary data payloads
- Query events by type, entity, or time range via `EventManager#query`

## Service Registry

The `ServiceRegistry` provides global access to core services:
- `:game` - Main game instance
- `:event_manager` - Event system
- `:logger` - Logging instance

Access via `Vanilla::ServiceRegistry.get(:service_name)`
