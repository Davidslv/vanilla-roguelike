# The Game Loop: Turn-Based Architecture in Action

The game loop is the heartbeat of any game. It coordinates everything: input, updates, rendering. For a turn-based roguelike, the loop is simpler than real-time games, but it still needs careful design. This article shares what we learned about building a turn-based game loop that coordinates systems, commands, and events.

## Understanding Turn-Based vs. Real-Time

In real-time games, the loop runs continuously:
- Update game state
- Render frame
- Repeat (60+ times per second)

In turn-based games, the loop waits for player input:
- Wait for input
- Process input
- Update game state (one turn)
- Render
- Repeat

This fundamental difference affects how we structure the loop.

## Our Game Loop

Here's the game loop we ended up with:

```ruby
def game_loop
  @turn = 0
  message_system = Vanilla::ServiceRegistry.get(:message_system)
  input_system = @world.systems.find { |s, _| s.is_a?(InputSystem) }[0]

  until @world.quit?
    if message_system&.selection_mode?
      # Menu mode: wait for input, process immediately
      input_system.update(nil)
      @world.send(:process_events) if @world.respond_to?(:process_events, true)
      message_system.update(nil)
      render
      @world.update(nil)  # Process commands
    else
      # Game mode: normal turn-based loop
      @world.update(nil)  # Update all systems
      @turn += 1
      render
    end
  end
end
```

The loop has two modes: game mode and menu mode.

## Game Mode: Normal Turn-Based Flow

In game mode, the loop follows this sequence:

```mermaid
sequenceDiagram
    participant Loop
    participant World
    participant Systems
    participant Commands
    participant Events
    participant Render

    Loop->>World: update()
    World->>Systems: Update in priority order
    Systems->>World: Queue commands/events
    World->>Commands: process_commands()
    World->>Events: process_events()
    World->>Loop: Update complete
    Loop->>Render: render()
    Render->>Loop: Frame complete
    Loop->>Loop: Wait for next input
```

1. **Update World**: Run all systems in priority order
2. **Process Commands**: Execute queued commands
3. **Process Events**: Handle queued events
4. **Render**: Draw the current state
5. **Wait**: Loop pauses, waiting for next input

### System Update Order

Systems run in priority order:

```ruby
def update(_unused)
  # Update all systems in priority order
  @systems.each do |system, _|
    system.update(nil)
  end

  # Process commands before events
  process_commands
  process_events
end
```

Priority order matters:
1. **MazeSystem (0)**: Generate maze first
2. **InputSystem (1)**: Process input early
3. **MovementSystem (2)**: Move entities
4. **CollisionSystem (3)**: Check collisions
5. **MonsterSystem (4)**: Update monsters
6. **RenderSystem (10)**: Render last

This order ensures systems run in the correct sequence.

## Menu Mode: Immediate Response

When the player is in a menu (like inventory or messages), we need immediate feedback:

```ruby
if message_system&.selection_mode?
  input_system.update(nil)  # Wait for input
  @world.send(:process_events)  # Process events immediately
  message_system.update(nil)  # Update menu state
  render  # Show updated menu
  @world.update(nil)  # Process commands
end
```

Menu mode processes input and renders immediately, without waiting for a full turn cycle. This makes menus feel responsive.

## Command and Event Processing

The loop processes commands and events after systems update:

### Command Processing

Commands are queued during system updates, then executed:

```ruby
def process_commands
  until @command_queue.empty?
    command, params = @command_queue.shift
    if command.is_a?(Vanilla::Commands::Command)
      command.execute(self)
    else
      handle_command(command, params)
    end
  end
end
```

Commands execute actions like moving entities or changing levels.

### Event Processing

Events are processed after commands:

```ruby
def process_events
  until @event_queue.empty?
    event_type, data = @event_queue.shift
    event_manager.publish_event(event_type, self, data)
    @event_subscribers[event_type].each do |subscriber|
      subscriber.handle_event(event_type, data)
    end
  end
end
```

Events notify subscribers about state changes.

## Why This Structure Works

### Turn-Based Simplicity

The loop is simple:
- Wait for input
- Process one turn
- Render
- Repeat

No complex timing or frame rate management needed.

### Clear Separation

Each phase has a clear purpose:
- **Update**: Change game state
- **Commands**: Execute actions
- **Events**: Notify systems
- **Render**: Display state

### Menu Responsiveness

Menu mode provides immediate feedback without full turn processing.

## What We Learned

1. **Turn-based is simpler**: No need for delta time or frame rate management. Just process one turn at a time.

2. **Order matters**: Systems must run in the correct order. Input before movement, movement before collision, collision before rendering.

3. **Two modes help**: Having separate game and menu modes makes each feel right. Menus need immediate feedback; gameplay needs turn structure.

4. **Commands and events after updates**: Processing commands and events after system updates ensures state is consistent.

5. **Rendering is separate**: Rendering happens after all updates, ensuring we always render a consistent state.

## Common Pitfalls

### Processing Commands During Updates

Don't process commands while systems are updating:

```ruby
# Bad: Commands processed during update
def update
  @systems.each { |s| s.update }
  process_commands  # Might queue more commands
end

# Good: Commands processed after all updates
def update
  @systems.each { |s| s.update }
end

def game_loop
  @world.update
  process_commands  # All systems done updating
end
```

### Rendering During Updates

Don't render while state is changing:

```ruby
# Bad: Rendering during update
def update
  move_entity
  render  # State might be inconsistent
end

# Good: Render after update
def game_loop
  @world.update
  render  # State is consistent
end
```

### Forgetting Menu Mode

Menus need different handling:

```ruby
# Bad: Menus feel sluggish
def game_loop
  @world.update  # Full turn processing
  render
end

# Good: Menus feel responsive
def game_loop
  if menu_mode?
    process_menu_input
    render  # Immediate feedback
  else
    @world.update
    render
  end
end
```

## Further Reading

- [System Priority: Why Order Matters in ECS](./14-system-priority.md) - Why systems run in a specific order
- [The World Coordinator: Managing ECS Complexity](./15-world-coordinator.md) - How World coordinates the loop
- [The Rendering Pipeline: From Game State to Terminal](./12-rendering-pipeline.md) - How rendering fits into the loop

## Conclusion

The game loop is the foundation of the game. For turn-based roguelikes, it's simpler than real-time games, but it still needs careful design. The key is coordinating systems, commands, and events in the right order, and handling different modes (game vs. menu) appropriately.

By keeping the loop simple and clear, we've found it easier to add new features and debug issues. The structure has held up well as the game has grown.

