# Command Architecture Improvement Proposal

## Current Implementation Analysis

The existing `command.rb` implements a simplified input handling system that directly maps keyboard inputs to game actions. While functional, it has several limitations:

- Direct coupling between input keys and actions
- Lack of command encapsulation
- Limited extensibility for new command types
- No support for command history, undo/redo, or macros
- Mixed responsibilities (input handling, logging, and execution)

## Proposed Architecture: Command Pattern

I propose implementing a proper Command Pattern, which encapsulates actions as objects, providing greater flexibility, extensibility, and features like undo/redo.

### Architectural Diagram

```
┌──────────────┐     ┌───────────────┐     ┌───────────────────┐
│  Input       │     │  Command      │     │ Command Executor  │
│  Handler     ├────►│  Factory      ├────►│                   │
└──────────────┘     └───────────────┘     └─────────┬─────────┘
                                                     │
                                                     ▼
┌──────────────┐                            ┌───────────────────┐
│  Command     │◄───────────────────────────┤ Command History   │
│  Objects     │                            │                   │
└──────┬───────┘                            └───────────────────┘
       │
       │
       ▼
┌──────────────┐     ┌───────────────┐
│  Game        │     │  Systems      │
│  State       │◄────┤  (Movement,   │
│              │     │   Combat etc) │
└──────────────┘     └───────────────┘
```

### Game Flow Diagram

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Player      │     │ Input       │     │ Command     │
│ presses 'k' ├────►│ Handler     ├────►│ Factory     │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                               │
                                               │ Creates
                                               ▼
┌────────────────┐     ┌──────────────┐     ┌─────────────┐
│ Draw/Render    │◄────┤ Game State   │◄────┤ MoveCommand │
│ Updates        │     │ Updates      │     │ (direction: │
└────────────────┘     └──────────────┘     │  :up)       │
                                            └─────────────┘
                                                   │
                                                   │ Stored in
                                                   ▼
                                            ┌─────────────┐
                                            │ Command     │
                                            │ History     │
                                            └─────────────┘
```

## Implementation Details

### 1. Command Interface and Concrete Commands

```ruby
# Abstract command interface
class Command
  def execute
    raise NotImplementedError
  end

  def undo
    raise NotImplementedError
  end
end

# Concrete movement command
class MoveCommand < Command
  def initialize(entity, direction, movement_system)
    @entity = entity
    @direction = direction
    @movement_system = movement_system
    @previous_position = nil
  end

  def execute
    # Store previous position for undo
    position = @entity.get_component(:position)
    @previous_position = { row: position.row, column: position.column }

    # Execute movement
    @movement_system.move(@entity, @direction)
  end

  def undo
    return unless @previous_position

    position = @entity.get_component(:position)
    position.row = @previous_position[:row]
    position.column = @previous_position[:column]
  end
end
```

### 2. Command Factory

```ruby
class CommandFactory
  def self.create_command(key, entity, grid)
    movement_system = Vanilla::Systems::MovementSystem.new(grid)

    case key
    when "k", "K", :KEY_UP
      MoveCommand.new(entity, :up, movement_system)
    when "j", "J", :KEY_DOWN
      MoveCommand.new(entity, :down, movement_system)
    when "l", "L", :KEY_RIGHT
      MoveCommand.new(entity, :right, movement_system)
    when "h", "H", :KEY_LEFT
      MoveCommand.new(entity, :left, movement_system)
    # Add more commands here
    else
      NullCommand.new # Do-nothing command for unknown inputs
    end
  end
end
```

### 3. Command Invoker/Executor

```ruby
class CommandInvoker
  def initialize(max_history = 20)
    @history = []
    @max_history = max_history
  end

  def execute_command(command)
    command.execute
    @history << command
    @history.shift if @history.size > @max_history
  end

  def undo_last_command
    return if @history.empty?
    command = @history.pop
    command.undo
  end
end
```

### 4. Input Handler

```ruby
class InputHandler
  def initialize(grid, entity)
    @grid = grid
    @entity = entity
    @command_invoker = CommandInvoker.new
    @logger = Vanilla::Logger.instance
  end

  def handle_input(key)
    if key == "\C-c" || key == "q"
      @logger.info("Player exiting game")
      exit
    elsif key == "z" && (key_modifiers & [:CTRL]) == [:CTRL]
      @logger.info("Undoing last action")
      @command_invoker.undo_last_command
    else
      command = CommandFactory.create_command(key, @entity, @grid)
      @command_invoker.execute_command(command)
    end
  end
end
```

### 5. Integration with Main Game Loop

```ruby
# In the main game loop
input_handler = InputHandler.new(grid, player)

loop do
  key = get_input_from_player()
  input_handler.handle_input(key)
  render_game_state()
end
```

## Benefits

1. **Decoupling** - Separates input handling, command creation, and command execution
2. **Extensibility** - Easily add new commands without modifying input handling
3. **Undo/Redo** - Built-in support for undoing and redoing actions
4. **Command History** - Can track player actions for replay or analytics
5. **Testability** - Commands can be tested in isolation
6. **Composability** - Supports macro commands (combinations of commands)

## Migration Plan

1. **Phase 1: Command Infrastructure**
   - Implement the core Command classes and interfaces
   - Keep the existing command.rb as a fallback

2. **Phase 2: Dual Implementation**
   - Add a feature flag to switch between old and new command systems
   - Implement parallel paths in the code

3. **Phase 3: Complete Migration**
   - Switch default to new command system
   - Add deprecation warnings to old code paths

4. **Phase 4: Cleanup**
   - Remove old command implementation
   - Complete refactoring of dependent code

This phased approach ensures the game remains playable throughout the migration while moving toward a more robust architecture.