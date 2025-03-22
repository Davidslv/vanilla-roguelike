# Vanilla Game Commands

This directory contains command classes that implement the Command pattern. These classes encapsulate actions that can be executed in the game.

## Available Commands

- `MoveCommand`: Handles entity movement in a specific direction
- Other commands...

## Usage Notes

### MoveCommand

The `MoveCommand` is used for moving entities (player, NPCs) around the grid.

**IMPORTANT: Parameter Order**

The constructor for `MoveCommand` requires parameters in this specific order:

```ruby
MoveCommand.new(entity, direction, grid, render_system = nil)
```

* `entity`: The entity to move (player, monster)
* `direction`: A Symbol representing the direction (:north, :south, :east, :west)
* `grid`: The game grid on which the entity should move

**Direction Translation**

The game simulator uses UI directions (:up, :down, :left, :right) which are translated to cardinal directions (:north, :south, :west, :east) for the MoveCommand.

### Testing

When testing with the game simulator, always ensure the direction parameter is a Symbol, not a Grid object. For more details about testing, including troubleshooting common issues, please see the [Testing Guide](../../doc/testing.md).