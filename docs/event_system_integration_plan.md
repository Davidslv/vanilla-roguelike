# Event System Integration Plan with File-Based Storage

This document outlines the step-by-step plan for implementing the event system in the Vanilla game, focusing on file-based storage as the primary persistence mechanism.

## 1. Implementation Phases

### Phase 1: Core Infrastructure (Week 1)

#### 1.1 Create Directory Structure
```
lib/
  vanilla/
    events/
      event.rb
      event_manager.rb
      event_subscriber.rb
      types.rb
      storage/
        event_store.rb
        file_event_store.rb
```

#### 1.2 Implement Core Classes

1. **Event Base Class** (`lib/vanilla/events/event.rb`)
   - Implement the `Event` class as specified in the design document
   - Add serialization/deserialization methods for storage

2. **Event Types** (`lib/vanilla/events/types.rb`)
   - Define constants for all event types
   - Group them by category (entity, combat, input, game state)

3. **Event Store Interface** (`lib/vanilla/events/storage/event_store.rb`)
   - Define the interface that all storage implementations must support
   - Include store, query, and session management methods

4. **File Event Store** (`lib/vanilla/events/storage/file_event_store.rb`)
   - Implement the file-based storage with JSONL format
   - Add configuration options for storage directory and file rotation

5. **Event Manager** (`lib/vanilla/events/event_manager.rb`)
   - Implement the central event bus with subscription management
   - Add integration with the file event store

6. **Event Subscriber Interface** (`lib/vanilla/events/event_subscriber.rb`)
   - Define the interface that all event handlers must implement

#### 1.3 Add Logger Integration

1. Create a specialized logger for event system
2. Add event-specific log levels and formatting
3. Ensure events are logged with appropriate detail

#### 1.4 Integration with Main Application

1. Modify `lib/vanilla.rb` to initialize the event system
2. Add configuration options for event storage

### Phase 2: Input System Integration (Week 2)

#### 2.1 Modify Input Handler

1. Update `lib/vanilla/input_handler.rb` to inject event manager
2. Publish key press events through the event system
3. Maintain backward compatibility during transition

#### 2.2 Create Command Events

1. Define event types for each command:
   - `MOVE_COMMAND_ISSUED`
   - `EXIT_COMMAND_ISSUED`
   - etc.

2. Modify command classes to subscribe to relevant events

#### 2.3 Convert Direct Calls to Events

1. Start with the `MoveCommand` implementation
2. Publish movement intent events instead of direct method calls
3. Subscribe to movement result events to handle outcomes

### Phase 3: Movement System Integration (Week 3)

#### 3.1 Update Movement System

1. Modify `lib/vanilla/systems/movement_system.rb` to implement `EventSubscriber`
2. Subscribe to movement intent events
3. Publish movement result events (success/failure)

#### 3.2 Collision Detection Events

1. Extract collision detection logic to respond to events
2. Publish collision events when detected
3. Create subscribers for collision resolution

#### 3.3 Update Player Movement

1. Convert player movement methods to use the event system
2. Ensure smooth integration with existing UI feedback

### Phase 4: Debugging Tools (Week 4)

#### 4.1 Implement Event Viewer

1. Create a basic event viewer in `lib/vanilla/debug/event_viewer.rb`
2. Add methods to view recent events by type
3. Implement filtering and searching capabilities

#### 4.2 Add Debug Trigger Points

1. Create special debug events that can be triggered in-game
2. Add support for conditional event logging

#### 4.3 Session Replay Functionality

1. Implement `EventReplaySystem` to load past sessions
2. Add commands to replay events at different speeds
3. Create a step-by-step replay mode

## 2. Test Strategy

### 2.1 Unit Tests

Create comprehensive unit tests for each component:

#### Event Classes
```ruby
# spec/lib/vanilla/events/event_spec.rb
RSpec.describe Vanilla::Events::Event do
  it "initializes with required attributes" do
    event = described_class.new("test_event", "source", {data: "value"})
    expect(event.type).to eq("test_event")
    expect(event.source).to eq("source")
    expect(event.data).to eq({data: "value"})
    expect(event.timestamp).to be_a(Time)
  end

  it "serializes to JSON format" do
    event = described_class.new("test_event", "source", {data: "value"})
    json = event.to_json
    expect(json).to include("test_event")
    expect(json).to include("source")
    expect(json).to include("value")
  end

  it "can be recreated from serialized format" do
    original = described_class.new("test_event", "source", {data: "value"})
    json = original.to_json
    recreated = described_class.from_json(json)
    expect(recreated.type).to eq(original.type)
    expect(recreated.data).to eq(original.data)
  end
end
```

#### File Event Store
```ruby
# spec/lib/vanilla/events/storage/file_event_store_spec.rb
RSpec.describe Vanilla::Events::Storage::FileEventStore do
  let(:test_dir) { "tmp/event_test" }
  let(:store) { described_class.new(test_dir) }
  let(:event) { Vanilla::Events::Event.new("test_event", "source", {data: "value"}) }

  before do
    FileUtils.rm_rf(test_dir)
    FileUtils.mkdir_p(test_dir)
  end

  after do
    FileUtils.rm_rf(test_dir)
  end

  it "stores events to the file system" do
    store.store(event)
    expect(Dir.glob("#{test_dir}/events_*.jsonl").size).to eq(1)
  end

  it "loads events from a session" do
    store.store(event)
    session_id = store.current_session
    loaded_events = store.load_session(session_id)
    expect(loaded_events.size).to eq(1)
    expect(loaded_events.first.type).to eq("test_event")
  end

  it "lists available sessions" do
    store.store(event)
    sessions = store.list_sessions
    expect(sessions.size).to eq(1)
  end
end
```

#### Event Manager
```ruby
# spec/lib/vanilla/events/event_manager_spec.rb
RSpec.describe Vanilla::Events::EventManager do
  let(:logger) { double("Logger").as_null_object }
  let(:manager) { described_class.new(logger, in_memory: false, file: true) }
  let(:subscriber) { double("Subscriber") }
  let(:event) { Vanilla::Events::Event.new("test_event", "source", {}) }

  before do
    allow(subscriber).to receive(:handle_event)
  end

  it "delivers events to subscribers" do
    manager.subscribe("test_event", subscriber)
    expect(subscriber).to receive(:handle_event).with(event)
    manager.publish(event)
  end

  it "stores events using the configured store" do
    test_file = manager.instance_variable_get(:@event_store)
    expect(test_file).to receive(:store).with(event)
    manager.publish(event)
  end
end
```

### 2.2 Integration Tests

Test the interactions between components:

```ruby
# spec/integration/event_system_spec.rb
RSpec.describe "Event System Integration" do
  let(:logger) { Vanilla::Logger.new("test") }
  let(:event_manager) { Vanilla::Events::EventManager.new(logger, file: true) }
  let(:input_handler) { Vanilla::InputHandler.new(logger: logger, event_manager: event_manager) }
  let(:movement_system) { Vanilla::Systems::MovementSystem.new(event_manager) }
  let(:player) { Vanilla::Entities::Player.new }

  before do
    # Set up test environment
    movement_system.add_entity(player)
  end

  it "handles input events throughout the system" do
    # Create a spy to monitor events
    event_spy = spy("EventSpy")
    event_manager.subscribe(Vanilla::Events::Types::ENTITY_MOVED, event_spy)

    # Simulate keyboard input
    input_handler.handle_input("up")

    # Verify the event chain completed
    expect(event_spy).to have_received(:handle_event).with(
      an_object_having_attributes(
        type: Vanilla::Events::Types::ENTITY_MOVED,
        source: player
      )
    )
  end
end
```

### 2.3 System Tests

Test the event system in a full game context:

```ruby
# spec/system/event_logging_spec.rb
RSpec.describe "Event Logging System", type: :system do
  let(:log_dir) { "tmp/system_event_test" }

  before do
    FileUtils.rm_rf(log_dir)
    FileUtils.mkdir_p(log_dir)
    ENV["VANILLA_EVENT_DIR"] = log_dir
  end

  after do
    FileUtils.rm_rf(log_dir)
  end

  it "logs a complete game session" do
    # Run a simple game scenario with events
    game = Vanilla::Game.new
    game.setup
    game.process_turn
    game.cleanup

    # Check if events were logged
    event_files = Dir.glob("#{log_dir}/events_*.jsonl")
    expect(event_files.size).to eq(1)

    # Verify content of event log
    content = File.read(event_files.first)
    expect(content).to include("game_started")
    expect(content).to include("game_ended")
  end
end
```

## 3. Integration Path

### 3.1 Gradual Integration Strategy

To minimize disruption, follow this pattern for each subsystem:

1. **Add Parallel Event Publication**
   - Keep existing method calls
   - Add event publications alongside them
   - Use "bridge" subscribers that translate events back to method calls

2. **Switch Subscribers to Event-Based**
   - Update one component at a time to listen for events
   - Test thoroughly after each component update

3. **Remove Direct Method Calls**
   - Once all subscribers use events, remove the original direct method calls
   - Add deprecation warnings before removal

### 3.2 System-by-System Approach

Integrate in this order of increasing complexity:

1. Input Handling (key press → command)
2. Movement System (coordinates, collision)
3. Combat System (attacks, damage)
4. Level Generation and Progression
5. Monster Movement and AI

### 3.3 Deployment Strategy

For each step:

1. Create a feature branch (e.g., `event-system-input`)
2. Implement changes for one subsystem
3. Run full test suite
4. Merge when passing
5. Deploy and monitor

## 4. Code Examples

### 4.1 File Event Store Implementation

```ruby
module Vanilla
  module Events
    module Storage
      class FileEventStore
        attr_reader :current_session

        def initialize(directory = "event_logs")
          require 'fileutils'
          require 'json'

          @directory = directory
          FileUtils.mkdir_p(@directory) unless Dir.exist?(@directory)
          @current_session = Time.now.strftime("%Y%m%d_%H%M%S")
          @current_file = nil
        end

        def store(event)
          ensure_file_open

          # Convert event to JSON and write to file
          event_json = {
            type: event.type,
            timestamp: event.timestamp,
            source: event.source.to_s,
            data: event.data
          }.to_json

          @current_file.puts(event_json)
          @current_file.flush  # Ensure data is written immediately
        end

        def load_session(session_id = nil)
          session_id ||= @current_session
          events = []

          filename = File.join(@directory, "events_#{session_id}.jsonl")
          return [] unless File.exist?(filename)

          File.open(filename, "r") do |file|
            file.each_line do |line|
              event_data = JSON.parse(line)
              events << Event.new(
                event_data["type"],
                event_data["source"],
                event_data["data"]
              )
            end
          end

          events
        end

        def list_sessions
          Dir.glob(File.join(@directory, "events_*.jsonl")).map do |file|
            File.basename(file).gsub(/^events_/, "").gsub(/\.jsonl$/, "")
          end
        end

        def close
          @current_file&.close
          @current_file = nil
        end

        private

        def ensure_file_open
          return if @current_file && !@current_file.closed?

          filename = File.join(@directory, "events_#{@current_session}.jsonl")
          @current_file = File.open(filename, "a")
        end
      end
    end
  end
end
```

### 4.2 Event Manager with File Storage

```ruby
module Vanilla
  module Events
    class EventManager
      def initialize(logger, store_config = {file: true})
        @subscribers = Hash.new { |h, k| h[k] = [] }
        @logger = logger

        # Set up file storage
        if store_config[:file]
          require_relative 'storage/file_event_store'
          directory = store_config[:file_directory] || "event_logs"
          @event_store = Storage::FileEventStore.new(directory)
        end
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

        # Store the event if storage is configured
        @event_store&.store(event)

        # Deliver to subscribers
        @subscribers[event.type].each do |subscriber|
          begin
            subscriber.handle_event(event)
          rescue => e
            @logger.error("Error in subscriber #{subscriber.class}: #{e.message}")
          end
        end
      end

      def query_events(options = {})
        @event_store&.query(options) || []
      end
    end
  end
end
```

### 4.3 InputHandler Integration Example

```ruby
module Vanilla
  class InputHandler
    def initialize(logger:, event_manager: nil)
      @logger = logger
      @event_manager = event_manager
    end

    def handle_input(key)
      @logger.info("Player pressed key: #{key}")

      # Publish key press event if event manager is available
      if @event_manager
        @event_manager.publish(
          Events::Event.new(
            Events::Types::KEY_PRESSED,
            self,
            { key: key }
          )
        )
      end

      # Create and execute appropriate command (legacy approach)
      command = create_command(key)
      command.execute if command
    end

    private

    def create_command(key)
      # Command creation logic
    end
  end
end
```

## 5. Timeline and Milestones

### Week 1: Core Infrastructure
- Day 1-2: Set up directory structure and implement Event, EventTypes
- Day 3-4: Implement FileEventStore and tests
- Day 5: Implement EventManager and integrate with main application

### Week 2: Input System
- Day 1-2: Modify InputHandler to use events
- Day 3-4: Create command events and subscribers
- Day 5: Integration testing and refinements

### Week 3: Movement System
- Day 1-2: Update MovementSystem to subscribe to events
- Day 3-4: Implement collision detection events
- Day 5: Update player movement to use event system

### Week 4: Debugging Tools
- Day 1-2: Implement EventViewer
- Day 3-4: Add session replay functionality
- Day 5: System testing and documentation

## 6. Success Criteria

The implementation is complete when:

1. All specified events are correctly published, stored, and processed
2. The FileEventStore reliably persists events to disk
3. Event logs can be loaded and replayed for debugging
4. Test coverage is at least 90% for all event-related code
5. Game functionality works identically to the pre-event system version
6. Documentation is updated to reflect the new architecture

## 7. Bonus Enhancements (If Time Permits)

1. **Event Visualization**: Create a simple web UI to view event logs
2. **Event Statistics**: Add metrics collection to analyze event patterns
3. **Conditional Events**: Add support for events that only fire when conditions are met
4. **Performance Tuning**: Optimize file writing to minimize impact on gameplay