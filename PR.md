# Add Event System to Vanilla Game

## Overview

This PR introduces a new event system to the Vanilla roguelike game. The event system provides decoupled communication between components, event logging for debugging, and a visualization tool for analyzing game events. Additionally, several core game architecture improvements have been made to improve code organization and maintainability.

## Key Changes

### 1. Event System Core

- **Event Manager**: Central hub that coordinates event publishing and subscribing
- **Event Storage**: File-based persistence of game events in JSON format
- **Event Types**: Standard event types for game state changes, player actions, etc.
- **Event Subscribers**: Interface for components to receive and handle events

### 2. Debugging & Visualization

- **Event Timeline**: Interactive HTML visualization of game events
- **Event Query System**: Ability to filter and analyze past events
- **Command-line Tool**: Script for generating event visualizations

### 3. Game Architecture Improvements

- **Game Loop Pattern**: Refactored main game class to properly implement the Game Loop pattern
- **Improved Structure**: Better separation of concerns with specialized methods
- **Comprehensive Documentation**: Added detailed documentation explaining architectural patterns

### 4. Bug Fixes

- Fixed game initialization issues with proper class structure
- Added missing monster collision detection
- Fixed input handler compatibility with tests
- Resolved module dependency issues

## Implementation Details

### Event System

The event system is implemented with these core components:

1. `Vanilla::Events::EventManager`: Central handler for events
2. `Vanilla::Events::Event`: Data class representing individual events
3. `Vanilla::Events::EventSubscriber`: Interface for components to receive events
4. `Vanilla::Events::Storage::FileEventStore`: Persistent storage for events
5. `Vanilla::Events::EventVisualization`: Timeline visualization generator

Events follow this lifecycle:
1. Components create and publish events via the EventManager
2. EventManager delivers events to all interested subscribers
3. Events are persisted to disk in the background
4. Events can be visualized or queried after the fact for debugging

### Game Architecture Changes

The main game loop has been restructured following the Game Loop pattern:

```
1. START FRAME (mark turn start)
2. PROCESS INPUT (handle player commands)
3. UPDATE GAME STATE (update monsters, handle collisions)
4. RENDER (display the updated state)
5. HANDLE LEVEL TRANSITIONS (if needed)
6. END FRAME (mark turn end)
```

### Event Visualization

The event visualization tool generates an interactive HTML timeline that:
- Groups events by type
- Shows timing relationships between events
- Allows filtering and searching event data
- Provides detailed inspection of event properties

## Test Coverage

The event system has been fully tested with:
- Unit tests for all event system components
- Integration tests for event flow
- File storage tests

All tests pass with the current implementation.

## Documentation

- `docs/event_system_usage.md`: Developer guide for using the event system
- `docs/event_system_visualization.md`: Guide for the visualization tools
- Code documentation: Comprehensive documentation for all classes and methods

## Breaking Changes

- InputHandler constructor signature changed from keyword to positional args
- Vanilla startup flow now uses a proper Game class

## Future Work

- Combat system integration with events
- Additional event visualizers for specific gameplay aspects
- Event replay system for reproducing bugs
- Real-time event monitoring during gameplay