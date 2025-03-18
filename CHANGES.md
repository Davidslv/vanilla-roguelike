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