# Event System Implementation Plan

This document outlines the plan for introducing an event-driven architecture to the Vanilla game, improving component decoupling, enhancing debuggability, and enabling better game state monitoring.

## 1. Overview and Rationale

### Current Architecture Limitations
- Systems are tightly coupled, complicating debugging of specific interactions
- Direct method calls between systems create complex dependency chains
- Tracking state changes across systems is difficult
- Testing isolated components requires extensive mocking

### Benefits of an Event System
- **Decoupling**: Systems communicate without direct dependencies
- **Observability**: Events can be logged, filtered, and replayed
- **Extensibility**: New functionality can be added without modifying existing code
- **Testability**: Components can be tested in isolation with event mocks
- **Debugging**: Events provide clear insight into game state changes

## 2. Core Event System Design

### Components

#### Event Class
The base class for all events in the system:

```ruby
module Vanilla
  module Events
    class Event
      attr_reader :timestamp, :source, :type, :data

      def initialize(type, source = nil, data = {})
        @type = type
        @source = source
        @data = data
        @timestamp = Time.now
      end

      def to_s
        "[#{@timestamp}] #{@type}: #{@data}"
      end
    end
  end
end
```

#### Event Types
Common event categories:

```ruby
module Vanilla
  module Events
    module Types
      # Entity events
      ENTITY_MOVED = "entity_moved"
      ENTITY_CREATED = "entity_created"
      ENTITY_DESTROYED = "entity_destroyed"

      # Combat events
      COMBAT_ATTACK = "combat_attack"
      COMBAT_DAMAGE = "combat_damage"
      COMBAT_DEATH = "combat_death"

      # Game state events
      LEVEL_CHANGED = "level_changed"
      GAME_STARTED = "game_started"
      GAME_ENDED = "game_ended"

      # Input events
      KEY_PRESSED = "key_pressed"
      COMMAND_EXECUTED = "command_executed"
    end
  end
end
```

#### Event Manager
Central hub for publishing and subscribing to events:

```ruby
module Vanilla
  module Events
    class EventManager
      def initialize(logger)
        @subscribers = Hash.new { |h, k| h[k] = [] }
        @logger = logger
      end

      def subscribe(event_type, subscriber)
        @subscribers[event_type] << subscriber
        @logger.debug("Subscribed #{subscriber.class} to #{event_type}")
      end

      def unsubscribe(event_type, subscriber)
        @subscribers[event_type].delete(subscriber)
        @logger.debug("Unsubscribed #{subscriber.class} from #{event_type}")
      end

      def publish(event)
        @logger.debug("Publishing event: #{event}")
        @subscribers[event.type].each do |subscriber|
          begin
            subscriber.handle_event(event)
          rescue => e
            @logger.error("Error in subscriber #{subscriber.class}: #{e.message}")
          end
        end
      end
    end
  end
end
```

#### Event Subscriber Interface
Interface for components that respond to events:

```ruby
module Vanilla
  module Events
    module EventSubscriber
      def handle_event(event)
        raise NotImplementedError, "Subclasses must implement handle_event"
      end
    end
  end
end
```

## 3. Implementation Plan

### Phase 1: Core Event Infrastructure (Week 1)
1. Implement `Event`, `EventManager`, and `EventSubscriber` classes
2. Create common event types
3. Add event manager to the game instance
4. Set up basic event logging

### Phase 2: System Integration (Week 2-3)
1. Modify the `InputHandler` to publish input events
2. Update the `MovementSystem` to subscribe to movement events
3. Convert direct method calls to event publications where appropriate
4. Implement event-based collision detection

### Phase 3: Monster System Refactoring (Week 4)
1. Refactor `MonsterSystem` to use events for:
   - Monster spawning
   - Monster movement
   - Monster-player interaction
2. Implement turn-based event processing
3. Add monster decision events for debugging

### Phase 4: Debugging Tools (Week 5)
1. Implement event history recording
2. Create event filtering and searching
3. Build event visualization system
4. Add event replay functionality

## 4. Example Integration - Monster Movement

### Current Implementation (Simplified)
```ruby
# Direct coupling between systems
def update
  @monsters.each do |monster|
    move_monster(monster)
    check_player_collision(monster, @player)
  end
end
```

### Event-Based Implementation
```ruby
# In MonsterSystem
def initialize(event_manager)
  @event_manager = event_manager
  @event_manager.subscribe(Events::Types::TURN_STARTED, self)
end

def handle_event(event)
  case event.type
  when Events::Types::TURN_STARTED
    process_monster_turns
  end
end

def process_monster_turns
  @monsters.each do |monster|
    # Calculate move
    if should_move?(monster)
      new_pos = calculate_new_position(monster)

      # Publish movement intent event
      intent_event = Events::Event.new(
        Events::Types::MOVEMENT_INTENT,
        monster,
        { from: current_pos, to: new_pos }
      )
      @event_manager.publish(intent_event)
    end
  end
end

# In MovementSystem
def handle_event(event)
  case event.type
  when Events::Types::MOVEMENT_INTENT
    entity = event.source
    to_pos = event.data[:to]

    if valid_move?(entity, to_pos)
      # Execute the move
      move_entity(entity, to_pos)

      # Publish successful movement event
      moved_event = Events::Event.new(
        Events::Types::ENTITY_MOVED,
        entity,
        { from: event.data[:from], to: to_pos }
      )
      @event_manager.publish(moved_event)
    else
      # Publish blocked movement event for debugging
      blocked_event = Events::Event.new(
        Events::Types::MOVEMENT_BLOCKED,
        entity,
        { from: event.data[:from], to: to_pos, reason: @last_block_reason }
      )
      @event_manager.publish(blocked_event)
    end
  end
end
```

## 5. Debug Event Monitoring

### Event Filter and Viewer
```ruby
module Vanilla
  module Debug
    class EventMonitor
      def initialize(event_manager)
        @event_manager = event_manager
        @event_history = []
        @filters = []

        # Subscribe to ALL events
        event_manager.subscribe(:all, self)
      end

      def handle_event(event)
        @event_history << event if passes_filters?(event)
      end

      def add_filter(filter_proc)
        @filters << filter_proc
      end

      def clear_filters
        @filters = []
      end

      def get_events(limit = 10)
        @event_history.last(limit)
      end

      def find_events(type, limit = 10)
        @event_history.select { |e| e.type == type }.last(limit)
      end

      private

      def passes_filters?(event)
        @filters.empty? || @filters.any? { |f| f.call(event) }
      end
    end
  end
end
```

### Integration with Step Execution Debugging
```ruby
module Vanilla
  module Debug
    class StepExecutor
      def initialize(event_manager, game)
        @event_manager = event_manager
        @game = game
        @paused = false
        @step_requested = false

        # Listen for debug commands
        @event_manager.subscribe(Events::Types::DEBUG_COMMAND, self)
      end

      def handle_event(event)
        case event.type
        when Events::Types::DEBUG_COMMAND
          handle_debug_command(event.data[:command])
        end
      end

      def handle_debug_command(command)
        case command
        when "pause"
          @paused = true
        when "resume"
          @paused = false
        when "step"
          @step_requested = true
        end
      end

      # Called before each game loop iteration
      def should_process_turn?
        return true unless @paused

        if @step_requested
          @step_requested = false
          return true
        end

        false
      end
    end
  end
end
```

## 6. Testing Strategy

### Unit Testing
```ruby
describe Vanilla::Events::EventManager do
  let(:logger) { double("logger").as_null_object }
  let(:event_manager) { described_class.new(logger) }
  let(:subscriber) { double("subscriber") }

  it "delivers events to subscribers" do
    event = Vanilla::Events::Event.new("test_event", nil, {value: 123})
    expect(subscriber).to receive(:handle_event).with(event)

    event_manager.subscribe("test_event", subscriber)
    event_manager.publish(event)
  end

  it "doesn't deliver events to unsubscribed handlers" do
    event = Vanilla::Events::Event.new("test_event", nil, {})
    expect(subscriber).not_to receive(:handle_event)

    event_manager.subscribe("test_event", subscriber)
    event_manager.unsubscribe("test_event", subscriber)
    event_manager.publish(event)
  end
end
```

### Integration Testing
```ruby
describe "Monster movement with events" do
  let(:event_manager) { Vanilla::Events::EventManager.new(logger) }
  let(:monster_system) { Vanilla::Systems::MonsterSystem.new(event_manager) }
  let(:movement_system) { Vanilla::Systems::MovementSystem.new(event_manager) }

  before do
    # Set up test systems
    monster_system.add_monster(monster)
    event_manager.publish(Vanilla::Events::Event.new(
      Vanilla::Events::Types::TURN_STARTED
    ))
  end

  it "publishes movement events when monsters move" do
    # Verify that appropriate events were published
    expect(event_manager).to have_received(:publish).with(
      an_instance_of(Vanilla::Events::Event).and having_attributes(
        type: Vanilla::Events::Types::MOVEMENT_INTENT
      )
    )
  end
end
```

## 7. Migration Strategy

### Risks and Mitigations
- **Risk**: Extensive refactoring could introduce new bugs
  - **Mitigation**: Phase in changes gradually, maintain high test coverage

- **Risk**: Event system overhead could impact performance
  - **Mitigation**: Profile and optimize critical paths, batch events when appropriate

- **Risk**: Event handlers could become complex and hard to follow
  - **Mitigation**: Establish clear event handling guidelines, keep handlers focused

### Adoption Approach
1. Start with less critical systems
2. Use bridging approach for core systems, supporting both direct calls and events
3. Gradually migrate code to event-only with deprecation warnings for direct methods
4. Update documentation as systems are converted

## Conclusion

Implementing an event system will significantly improve the architecture of the Vanilla game, particularly for complex interactions like monster movement. The decoupled nature of events will make debugging easier, enhance testability, and provide a solid foundation for future features.

The event system works in tandem with the debugging tools outlined in the debugging_monster_movement.md document, providing the infrastructure needed for effective monitoring and issue isolation.