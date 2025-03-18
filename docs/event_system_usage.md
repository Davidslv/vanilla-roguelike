# Event System Usage Guide

The Vanilla game includes a robust event system for decoupled communication between game components. This guide explains how to use it effectively in your code.

## Basic Concepts

The event system follows a publisher/subscriber pattern:

1. **Publishers** emit events when something happens (e.g., player moves, monster attacks)
2. **Subscribers** register interest in specific event types and handle them
3. **Events** contain data about what happened (type, source, timestamp, additional data)
4. **Event Store** persists events for debugging and replay

## Accessing the Event Manager

The event manager is initialized in the main `Vanilla` class and can be accessed throughout the codebase:

```ruby
# In systems and components that take a logger in their constructor
def initialize(logger:, event_manager: nil)
  @logger = logger
  @event_manager = event_manager
end
```

## Publishing Events

You can publish events in two ways:

### Method 1: Using publish_event

```ruby
# Create and publish an event in one step
@event_manager.publish_event(
  Vanilla::Events::Types::ENTITY_MOVED,
  self,
  {
    entity_id: entity.id,
    from: [old_row, old_col],
    to: [new_row, new_col]
  }
)
```

### Method 2: Creating and publishing separately

```ruby
# Create an event
event = Vanilla::Events::Event.new(
  Vanilla::Events::Types::COMBAT_ATTACK,
  attacker,
  {
    target_id: target.id,
    damage: 5
  }
)

# Publish the event
@event_manager.publish(event)
```

## Subscribing to Events

To receive events, implement the `EventSubscriber` interface and subscribe:

```ruby
class CombatSystem
  include Vanilla::Events::EventSubscriber

  def initialize(event_manager)
    @event_manager = event_manager
    # Subscribe to combat-related events
    @event_manager.subscribe(Vanilla::Events::Types::COMBAT_ATTACK, self)
    @event_manager.subscribe(Vanilla::Events::Types::COMBAT_DAMAGE, self)
  end

  # Handle received events
  def handle_event(event)
    case event.type
    when Vanilla::Events::Types::COMBAT_ATTACK
      process_attack(event)
    when Vanilla::Events::Types::COMBAT_DAMAGE
      apply_damage(event)
    end
  end

  private

  def process_attack(event)
    # Implementation
  end

  def apply_damage(event)
    # Implementation
  end
end
```

Remember to unsubscribe when your system is no longer active:

```ruby
def cleanup
  @event_manager.unsubscribe(Vanilla::Events::Types::COMBAT_ATTACK, self)
  @event_manager.unsubscribe(Vanilla::Events::Types::COMBAT_DAMAGE, self)
end
```

## Common Event Types

Use the predefined event types in `Vanilla::Events::Types`:

- **Entity Events**: `ENTITY_CREATED`, `ENTITY_DESTROYED`, `ENTITY_MOVED`
- **Game State**: `GAME_STARTED`, `GAME_ENDED`, `LEVEL_CHANGED`
- **Input Events**: `KEY_PRESSED`, `COMMAND_ISSUED`
- **Movement**: `MOVEMENT_INTENT`, `MOVEMENT_SUCCEEDED`, `MOVEMENT_BLOCKED`
- **Combat**: `COMBAT_ATTACK`, `COMBAT_DAMAGE`, `COMBAT_DEATH`
- **Monsters**: `MONSTER_SPAWNED`, `MONSTER_DETECTED_PLAYER`

## Event Storage and Replay

Events are automatically stored in JSON Line format in the `event_logs` directory. Each gameplay session creates a new log file with a timestamp-based name.

### Accessing Past Events

```ruby
# Get the current session ID
session_id = @event_manager.current_session

# Load events from a specific session
events = @event_manager.event_store.load_session(session_id)

# Query events with filters
movement_events = @event_manager.query_events(
  type: Vanilla::Events::Types::ENTITY_MOVED,
  limit: 10
)
```

## Debugging with Events

The event system can be powerful for debugging:

1. Run the game and reproduce the issue
2. Locate the session log file in `event_logs/`
3. Analyze the events to trace the sequence of actions
4. Implement an `EventReplaySystem` to replay the problematic sequence

## Best Practices

1. **Keep events focused**: Include only relevant data in each event
2. **Use established types**: Prefer existing event types from `Vanilla::Events::Types`
3. **Handle errors gracefully**: Event subscribers should never crash; use try/catch in handlers
4. **Clean up subscriptions**: Always unsubscribe when systems are destroyed
5. **Be mindful of performance**: Don't spam high-frequency events with large data payloads

## Example: Tracking Player Movement

Here's a complete example of tracking player movement:

```ruby
# In MovementSystem
def move_entity(entity, direction)
  # Get current position
  position = entity.get_component(:position)
  old_row, old_col = position.row, position.column

  # Calculate new position
  new_row, new_col = calculate_new_position(position, direction)

  # Check if move is valid
  if valid_move?(entity, new_row, new_col)
    # Update position
    position.row = new_row
    position.column = new_col

    # Publish event
    @event_manager.publish_event(
      Vanilla::Events::Types::ENTITY_MOVED,
      entity,
      {
        entity_id: entity.id,
        from: [old_row, old_col],
        to: [new_row, new_col],
        direction: direction
      }
    )

    return true
  else
    # Publish blocked event
    @event_manager.publish_event(
      Vanilla::Events::Types::MOVEMENT_BLOCKED,
      entity,
      {
        entity_id: entity.id,
        position: [old_row, old_col],
        attempted_direction: direction
      }
    )

    return false
  end
end
```