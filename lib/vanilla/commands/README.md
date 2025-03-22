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

**Common Error**

If you pass the parameters in the wrong order (especially putting grid before direction), you'll encounter this error:

```
NoMethodError: undefined method 'to_sym' for #<Vanilla::MapUtils::Grid:...>
```

This happens because the command tries to call `to_sym` on what it expects to be a direction Symbol, but is actually the Grid object.

**Direction Translation**

The game simulator uses UI directions (:up, :down, :left, :right) which are translated to cardinal directions (:north, :south, :west, :east) for the MoveCommand.

### Testing

When testing with the game simulator, always ensure the direction parameter is a Symbol, not a Grid object. The `bin/test_game` script includes examples of correct usage.