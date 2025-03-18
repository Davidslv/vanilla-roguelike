# Changes - Architecture Streamlining

## Latest Changes (2023-XX-XX)

### Removal of Command Class

- Removed `lib/vanilla/command.rb` - Eliminated the redundant adapter layer
- Removed `spec/lib/vanilla/command_spec.rb` - Removed tests for the Command class
- Modified `lib/vanilla.rb` to directly use the InputHandler:
  - Added creation of InputHandler instance in the run method
  - Updated to call `input_handler.handle_input()` directly
  - Changed import to require `input_handler.rb` instead of `command.rb`

This change simplifies the architecture by removing an unnecessary layer of indirection. The game loop now communicates directly with the InputHandler, which creates and executes the appropriate commands.

## Current Architecture

```
┌───────────────┐      ┌───────────────┐       ┌───────────────┐
│  Game Loop    │      │ InputHandler  │       │   Commands    │
│ (vanilla.rb)  │──────▶ (creates      │───────▶ MoveCommand   │
└───────────────┘      │  commands)    │       │ ExitCommand   │
        │              └───────────────┘       │ NullCommand   │
        │                      │               └───────────────┘
        │                      │                      │
        ▼                      ▼                      ▼
┌───────────────┐      ┌───────────────┐       ┌───────────────┐
│     Level     │      │    Systems    │       │     Draw      │
│ (contains     │◀─────│ MovementSystem│◀──────│ (renders      │
│  grid/player) │      └───────────────┘       │  changes)     │
└───────────────┘              │               └───────────────┘
        │                      │                      │
        ▼                      ▼                      ▼
┌───────────────┐      ┌───────────────┐       ┌───────────────┐
│     Grid      │      │    Entity     │       │    Output     │
│ (maze cells,  │◀─────│ (components:  │───────▶ (terminal     │
│  algorithms)  │      │  position,etc)│       │  rendering)   │
└───────────────┘      └───────────────┘       └───────────────┘
```

## Class Responsibilities

- **Game Loop** (vanilla.rb): Entry point, manages game state and input handling
- **InputHandler**: Translates key inputs into appropriate command objects
- **Commands**: Encapsulate actions (movement, exit game, etc.) with the Command pattern
- **Level**: Contains and manages the current game level including grid and player
- **Entity**: Base class for game objects following Entity-Component-System pattern
- **Components**: Data containers (Position, Movement, Tile, Stairs) attached to entities
- **Systems**: Logic that operates on entities with specific components (e.g., MovementSystem)
- **Draw**: Rendering utilities for displaying game state
- **Grid/MapUtils**: Maze generation and management
- **Algorithms**: Various maze generation algorithms

## Suggestions for Further Improvements

1. **Complete ECS Implementation**:
   - Add a proper System Manager to systematically update all systems
   - Consider implementing a Component Manager for better performance

2. **Additional Systems**:
   - CollisionSystem - Dedicated collision detection and response
   - AISystem - For enemy movement and behavior
   - ItemSystem - For handling item interactions
   - CombatSystem - For implementing combat mechanics

3. **Performance Optimizations**:
   - Use spatial partitioning for collision detection if adding many entities
   - Consider caching rendered output for static parts of the grid

4. **UI Improvements**:
   - Add a proper UI layer for displaying stats, inventory, etc.
   - Consider implementing a menu system for game options

5. **Technical Debt**:
   - Improve test coverage for edge cases
   - Add documentation for each class and module
   - Consider extracting maze generation into a separate gem

# Changes - Legacy Code Removal

This document outlines the changes made to remove legacy code from the codebase, specifically the Unit and Characters::Player classes as part of the migration to the Entity-Component-System architecture.

## Files Removed

- `lib/vanilla/unit.rb` - Removed the deprecated Unit class
- `lib/vanilla/characters/player.rb` - Removed the deprecated legacy Player class
- `spec/lib/vanilla/unit_spec.rb` - Removed tests for the deprecated Unit class
- `spec/lib/vanilla/characters/player_spec.rb` - Removed tests for the deprecated legacy Player class

## Files Modified

### lib/vanilla.rb
- Removed the require for `vanilla/characters/player`
- Reordered imports to put entities before commands for logical flow

### lib/vanilla/command.rb
- Removed legacy Unit compatibility checks and deprecation warnings
- Simplified the command processing to only work with ECS entities

### lib/vanilla/draw.rb
- Removed conditional logic handling legacy Unit objects
- Simplified methods to only work with ECS entities
- Updated `system` call to use `Kernel.system` for better testability

### lib/vanilla/commands/move_command.rb
- Removed logic for handling legacy Unit objects
- Simplified the code to only handle Entity objects with components

### spec/lib/vanilla/command_spec.rb
- Removed tests for legacy Unit compatibility
- Updated tests to only test Entity objects with proper components

### spec/lib/vanilla/draw_spec.rb
- Removed tests for legacy Unit compatibility
- Updated tests to only test Entity objects with proper components
- Fixed test mocking for better stability

## Migration Notes

- The codebase now fully uses the Entity-Component-System architecture
- All legacy support for the old Unit-based system has been removed
- The game loop in `lib/vanilla.rb` now expects all objects to be ECS entities
- The `draw.rb` module has been simplified to only work with ECS entities
- All command processing now works exclusively with ECS entities

These changes complete the migration to the Entity-Component-System architecture, resulting in a cleaner, more modular codebase.