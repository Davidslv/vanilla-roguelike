# Event & Logging Architecture Separation for Vanilla Game Engine

## 1. Executive Summary

This proposal outlines an architecture to decouple logging and event handling from the main Vanilla game loop, improving performance and maintainability. We recommend implementing an Event Bus pattern with selective asynchronous processing for non-critical components like logging, while maintaining synchronous processing for gameplay-critical events.

## 2. Current Architecture Analysis

### 2.1 Current Implementation

The Vanilla game engine currently implements:

- A singleton `Logger` class with direct file I/O operations
- An event system with tightly coupled components
- Synchronous processing of all events and logs within the main thread

### 2.2 Current Limitations

- Logging operations block the main thread during I/O
- Event handling for non-critical events unnecessarily impacts gameplay performance
- Limited scalability as the number of events/logs increases
- No prioritization between critical and non-critical operations

## 3. Proposed Architecture

### 3.1 Core Components

```mermaid
classDiagram
    class EventBus {
        -Map~EventType, List~Subscriber~~ subscribers
        -Map~Subscriber, ProcessingMode~ processingModes
        -Map~Subscriber, Queue~ asyncQueues
        -Map~Subscriber, Thread~ workerThreads
        +subscribe(eventType, subscriber)
        +unsubscribe(eventType, subscriber)
        +publish(event)
        +setProcessingMode(subscriber, mode)
        -processAsync(subscriber)
    }

    class Event {
        +EventType type
        +Map~String, Object~ data
        +timestamp
    }

    class EventSubscriber {
        +handleEvent(event)
    }

    class Logger {
        -LogLevel level
        -Queue logQueue
        -Thread workerThread
        -File logFile
        -boolean flushImmediate
        +debug(message)
        +info(message)
        +warn(message)
        +error(message)
        +fatal(message)
        +setFlushMode(immediate)
        -processLogQueue()
    }

    class GameLoop {
        -EventBus eventBus
        -List~System~ systems
        +initialize()
        +update(deltaTime)
        +render()
    }

    class ProcessingMode {
        <<enumeration>>
        SYNCHRONOUS
        ASYNCHRONOUS
        BATCH
    }

    EventBus --o Event : publishes
    EventSubscriber --|> EventBus : subscribes to
    Logger --|> EventSubscriber : implements
    GameLoop --o EventBus : uses
    EventBus --o ProcessingMode : configures
```

### 3.2 Event Flow

```mermaid
sequenceDiagram
    participant GL as GameLoop
    participant EB as EventBus
    participant CS as CriticalSubscriber
    participant NC as NonCriticalSubscriber
    participant LG as Logger

    GL->>EB: publish(GameEvent)

    alt Critical Event (Synchronous)
        EB->>CS: handleEvent(event)
        CS-->>EB: return
    else Non-Critical Event (Asynchronous)
        EB->>EB: queue event for NC
        Note over EB: Worker thread processes
        EB->>NC: handleEvent(event)
    else Log Event (Asynchronous+Batched)
        EB->>EB: queue event for LG
        Note over EB: Logger thread processes
        EB->>LG: handleEvent(event)
        LG->>LG: buffer log message

        alt Flush interval reached
            LG->>LG: write all buffered logs
        end
    end

    GL->>GL: continue game loop
```

### 3.3 Configuration Options

The system allows flexible configuration:

1. **Processing Modes**:
   - `SYNCHRONOUS`: Immediate processing on main thread
   - `ASYNCHRONOUS`: Background thread processing
   - `BATCH`: Collect and process periodically

2. **Subscriber Categories**:
   - **Critical**: Always synchronous (movement, collisions)
   - **Important**: Synchronous or batch (scoring, achievements)
   - **Non-critical**: Asynchronous (logging, analytics)

## 4. Implementation Plan

### 4.1 Core EventBus Implementation

```ruby
module Vanilla
  class EventBus
    include Singleton

    PROCESSING_MODES = [:synchronous, :asynchronous, :batch]

    def initialize
      @subscribers = Hash.new { |h, k| h[k] = [] }
      @processing_modes = {}
      @async_queues = {}
      @batch_queues = {}
      @worker_threads = {}
      @running = true
      @batch_interval = 0.5 # seconds
    end

    def subscribe(event_type, subscriber)
      @subscribers[event_type] << subscriber
      # Default to synchronous mode unless specified
      @processing_modes[subscriber] ||= :synchronous
    end

    def unsubscribe(event_type, subscriber)
      @subscribers[event_type].delete(subscriber)
    end

    def set_processing_mode(subscriber, mode)
      raise ArgumentError, "Invalid mode: #{mode}" unless PROCESSING_MODES.include?(mode)

      old_mode = @processing_modes[subscriber]
      @processing_modes[subscriber] = mode

      # Setup appropriate processing mechanism if changed
      if mode == :asynchronous && old_mode != :asynchronous
        setup_async_processing(subscriber)
      elsif mode == :batch && old_mode != :batch
        setup_batch_processing(subscriber)
      end
    end

    def publish(event)
      @subscribers[event.type].each do |subscriber|
        case @processing_modes[subscriber]
        when :synchronous
          subscriber.handle_event(event)
        when :asynchronous
          @async_queues[subscriber] << event
        when :batch
          @batch_queues[subscriber] << event
        end
      end
    end

    def shutdown
      @running = false
      @worker_threads.each_value(&:join)
    end

    private

    def setup_async_processing(subscriber)
      @async_queues[subscriber] = Queue.new

      @worker_threads[subscriber] = Thread.new do
        while @running || !@async_queues[subscriber].empty?
          begin
            event = @async_queues[subscriber].pop(true)
            subscriber.handle_event(event)
          rescue ThreadError
            sleep 0.01
          end
        end
      end
    end

    def setup_batch_processing(subscriber)
      @batch_queues[subscriber] = []

      @worker_threads[subscriber] = Thread.new do
        last_process_time = Time.now

        while @running
          if Time.now - last_process_time >= @batch_interval
            # Process all events in batch
            events = nil

            # Thread-safe extraction of current batch
            synchronized do
              events = @batch_queues[subscriber].dup
              @batch_queues[subscriber].clear
            end

            # Process the batch
            events.each { |event| subscriber.handle_event(event) }
            last_process_time = Time.now
          end

          sleep 0.01
        end
      end
    end

    def synchronized
      mutex = @mutex ||= Mutex.new
      mutex.synchronize { yield }
    end
  end
end
```

### 4.2 Logger Implementation

```ruby
module Vanilla
  class Logger
    include Singleton
    include EventSubscriber

    LOG_LEVELS = {
      debug: 0,
      info: 1,
      warn: 2,
      error: 3,
      fatal: 4
    }.freeze

    def initialize
      @level = ENV['VANILLA_LOG_LEVEL']&.downcase&.to_sym || :info
      @log_env = ENV['VANILLA_LOG_DIR'] || 'development'
      @log_dir = File.join(Dir.pwd, 'logs', @log_env)

      FileUtils.mkdir_p(@log_dir) unless Dir.exist?(@log_dir)
      @log_file = File.join(@log_dir, "vanilla_#{Time.now.strftime('%Y%m%d_%H%M%S')}.log")
      @file = File.open(@log_file, 'w')

      # Write header
      @file.puts "=== Vanilla Game Log Started at #{Time.now} ==="
      @file.flush

      # Subscribe to log events
      EventBus.instance.subscribe(:log, self)
      EventBus.instance.set_processing_mode(self, :asynchronous)

      # Message buffer for batch writes
      @message_buffer = []
      @buffer_mutex = Mutex.new
      @max_buffer_size = 100
    end

    def debug(message)
      log_event(:debug, message)
    end

    def info(message)
      log_event(:info, message)
    end

    def warn(message)
      log_event(:warn, message)
    end

    def error(message)
      log_event(:error, message)
    end

    def fatal(message)
      log_event(:fatal, message)
    end

    def handle_event(event)
      return unless event.type == :log

      level = event.data[:level]
      message = event.data[:message]
      timestamp = event.data[:timestamp] || Time.now

      @buffer_mutex.synchronize do
        @message_buffer << [level, message, timestamp]
        flush_buffer if @message_buffer.size >= @max_buffer_size
      end
    end

    def close
      flush_buffer
      @file.puts "=== Vanilla Game Log Ended at #{Time.now} ==="
      @file.close
      @file = nil
    end

    private

    def log_event(level, message)
      return if LOG_LEVELS[level] < LOG_LEVELS[@level]

      event = Event.new(
        type: :log,
        data: {
          level: level,
          message: message,
          timestamp: Time.now
        }
      )

      EventBus.instance.publish(event)
    end

    def flush_buffer
      return if @message_buffer.empty?

      @message_buffer.each do |level, message, timestamp|
        write_log(level, message, timestamp)
      end
      @message_buffer.clear
    end

    def write_log(level, message, timestamp)
      formatted_time = timestamp.strftime('%Y-%m-%d %H:%M:%S.%L')
      formatted_message = "[#{formatted_time}] [#{level.to_s.upcase}] #{message}"
      @file.puts(formatted_message)
      @file.flush
    end
  end
end
```

### 4.3 Event System Implementation

```ruby
module Vanilla
  class Event
    attr_reader :type, :data, :timestamp

    def initialize(type:, data: {})
      @type = type
      @data = data
      @timestamp = Time.now
    end
  end

  module EventSubscriber
    def handle_event(event)
      raise NotImplementedError, "Subscribers must implement #handle_event"
    end
  end

  class EventManager
    def initialize(event_bus = EventBus.instance)
      @event_bus = event_bus

      # Configure subscribers
      setup_subscribers
    end

    private

    def setup_subscribers
      # Register game-critical subscribers as synchronous
      critical_subscribers.each do |event_type, subscriber|
        @event_bus.subscribe(event_type, subscriber)
        @event_bus.set_processing_mode(subscriber, :synchronous)
      end

      # Register important but non-blocking subscribers
      important_subscribers.each do |event_type, subscriber|
        @event_bus.subscribe(event_type, subscriber)
        @event_bus.set_processing_mode(subscriber, :batch)
      end

      # Register non-critical subscribers as async
      non_critical_subscribers.each do |event_type, subscriber|
        @event_bus.subscribe(event_type, subscriber)
        @event_bus.set_processing_mode(subscriber, :asynchronous)
      end
    end

    def critical_subscribers
      # Return mapping of event type to subscriber for critical game events
      # Example: { player_move: MovementSystem, collision: CollisionSystem }
    end

    def important_subscribers
      # Return mapping for important but not time-critical events
      # Example: { score_change: ScoreSystem, achievement: AchievementSystem }
    end

    def non_critical_subscribers
      # Return mapping for non-critical events
      # Example: { log: Logger.instance, analytics: AnalyticsSystem }
    end
  end
end
```

## 5. Benefits and Trade-offs

### 5.1 Benefits

1. **Performance Improvements**:
   - Main game loop no longer blocked by I/O operations
   - Critical systems receive immediate processing
   - Non-critical systems processed asynchronously

2. **Scalability**:
   - Event load distributed across multiple threads
   - Batched processing reduces overhead for frequent events
   - Clear separation of concerns between systems

3. **Flexibility**:
   - Processing modes configurable at runtime
   - New subscribers can be added without architectural changes
   - Prioritization based on gameplay significance

### 5.2 Trade-offs

1. **Complexity**:
   - More complex architecture to understand and maintain
   - Potential for threading issues if not carefully implemented
   - Debugging may be more challenging

2. **Resource Usage**:
   - Additional memory for event queues
   - Thread overhead for worker threads
   - Potential for race conditions

3. **Implementation Challenges**:
   - Thread safety requirements
   - Proper shutdown handling
   - Error handling across threads

## 6. Testing Strategy

### 6.1 Unit Testing

```ruby
RSpec.describe Vanilla::EventBus do
  # Test synchronous event handling
  it "processes synchronous events immediately" do
    bus = Vanilla::EventBus.instance
    subscriber = double("Subscriber")

    allow(subscriber).to receive(:handle_event)
    bus.subscribe(:test_event, subscriber)

    event = Vanilla::Event.new(type: :test_event)
    bus.publish(event)

    expect(subscriber).to have_received(:handle_event).with(event)
  end

  # Test asynchronous event handling
  it "processes asynchronous events in background" do
    bus = Vanilla::EventBus.instance
    subscriber = double("Subscriber")

    allow(subscriber).to receive(:handle_event)
    bus.subscribe(:test_event, subscriber)
    bus.set_processing_mode(subscriber, :asynchronous)

    event = Vanilla::Event.new(type: :test_event)
    bus.publish(event)

    # Give the worker thread time to process
    sleep 0.1

    expect(subscriber).to have_received(:handle_event).with(event)
  end

  # Additional tests for batch processing, thread safety, etc.
end
```

### 6.2 Performance Testing

Create benchmark tests to measure:
- Main thread framerate with/without separation
- Processing latency for critical events
- Log throughput under high volume

## 7. Implementation Timeline

1. **Phase 1: Core Infrastructure (1-2 weeks)**
   - Implement EventBus with processing modes
   - Create Event and EventSubscriber base classes
   - Add thread-safety mechanisms

2. **Phase 2: Logger Migration (1 week)**
   - Refactor Logger to use the EventBus
   - Implement asynchronous/batch logging
   - Test performance improvements

3. **Phase 3: Event System Migration (1-2 weeks)**
   - Categorize existing event handlers
   - Migrate to new EventBus architecture
   - Configure processing modes

4. **Phase 4: Testing & Optimization (1 week)**
   - Performance testing
   - Thread safety verification
   - Memory optimization

## 8. Recommendations

1. **Begin with Logger Migration**: Simplest component to move to asynchronous processing
2. **Use Thread Pool**: Consider a thread pool for worker threads to limit resource usage
3. **Monitor Performance**: Add metrics to track event processing times
4. **Gradual Implementation**: Start with simple events before migrating critical systems

## 9. Conclusion

The proposed architecture provides a flexible, performant solution for separating logging and event handling from the main game loop. The Event Bus pattern with configurable processing modes offers the best balance between performance gains and implementation complexity.

By implementing this architecture, the Vanilla game engine will gain significant performance improvements for I/O-intensive operations while maintaining responsive gameplay for time-critical events.

## 10. Alternative Implementation: Ruby Fibers

Ruby Fibers provide another approach to concurrency that can be better suited for games. This section explores how to implement the event system and logging using Fibers instead of threads.

### 10.1 Fiber-Based Architecture

```mermaid
classDiagram
    class FiberEventBus {
        -Map~EventType, List~Subscriber~~ subscribers
        -Map~Subscriber, ProcessingMode~ processingModes
        -Map~Subscriber, Queue~ fiberQueues
        -Map~Subscriber, Fiber~ fibers
        -FiberScheduler scheduler
        +subscribe(eventType, subscriber)
        +unsubscribe(eventType, subscriber)
        +publish(event)
        +setProcessingMode(subscriber, mode)
        +tick()
    }

    class FiberScheduler {
        -List~Fiber~ activeFibers
        -Int yieldInterval
        +register(fiber)
        +resume_all()
        +run_nonblocking()
    }

    class Event {
        +EventType type
        +Map~String, Object~ data
        +timestamp
    }

    class FiberLogger {
        -LogLevel level
        -Queue logQueue
        -Fiber logFiber
        -File logFile
        +debug(message)
        +info(message)
        +warn(message)
        +error(message)
        +fatal(message)
        -process_logs()
    }

    class GameLoop {
        -FiberEventBus eventBus
        -FiberScheduler scheduler
        -List~System~ systems
        +initialize()
        +update(deltaTime)
        +render()
        +tick_fibers()
    }

    class ProcessingMode {
        <<enumeration>>
        IMMEDIATE
        DEFERRED
        SCHEDULED
    }

    FiberEventBus --o Event : publishes
    FiberEventBus --o FiberScheduler : uses
    GameLoop --o FiberEventBus : uses
    FiberLogger --|> FiberEventBus : subscribes to
    FiberEventBus --o ProcessingMode : configures
```

### 10.2 Fiber-Based Event Flow

```mermaid
sequenceDiagram
    participant GL as GameLoop
    participant EB as FiberEventBus
    participant FS as FiberScheduler
    participant CS as CriticalSubscriber
    participant LG as FiberLogger

    GL->>EB: publish(GameEvent)

    alt Critical Event (Immediate)
        EB->>CS: handleEvent(event)
        CS-->>EB: return
    else Non-Critical Event (Deferred)
        EB->>EB: queue event for deferred handling
    end

    GL->>GL: continue game update
    GL->>GL: finish rendering

    GL->>FS: tick()
    FS->>FS: resume all registered fibers

    FS->>LG: resume log fiber
    Note over LG: Process queued logs
    LG-->>FS: yield control

    FS-->>GL: return control
    GL->>GL: begin next frame
```

### 10.3 Core FiberEventBus Implementation

```ruby
require 'fiber'

module Vanilla
  class FiberEventBus
    include Singleton

    PROCESSING_MODES = [:immediate, :deferred, :scheduled]

    def initialize
      @subscribers = Hash.new { |h, k| h[k] = [] }
      @processing_modes = {}
      @event_queues = {}
      @fibers = {}
      @running = true

      # Setup scheduler for Ruby 3.0+
      @scheduler = FiberScheduler.new
    end

    def subscribe(event_type, subscriber)
      @subscribers[event_type] << subscriber
      # Default to immediate mode unless specified
      @processing_modes[subscriber] ||= :immediate

      # Setup queue and fiber for deferred and scheduled subscribers
      if @processing_modes[subscriber] != :immediate
        setup_fiber_processing(subscriber)
      end
    end

    def publish(event)
      @subscribers[event.type].each do |subscriber|
        case @processing_modes[subscriber]
        when :immediate
          subscriber.handle_event(event)
        when :deferred, :scheduled
          @event_queues[subscriber] << event
        end
      end
    end

    # Call this at the end of each game loop update
    def tick
      @scheduler.resume_all
    end

    def shutdown
      @running = false
      # Allow fibers to complete their work
      tick
    end

    def set_processing_mode(subscriber, mode)
      raise ArgumentError, "Invalid mode: #{mode}" unless PROCESSING_MODES.include?(mode)

      old_mode = @processing_modes[subscriber]
      @processing_modes[subscriber] = mode

      if (mode == :deferred || mode == :scheduled) && old_mode == :immediate
        setup_fiber_processing(subscriber)
      end
    end

    private

    def setup_fiber_processing(subscriber)
      @event_queues[subscriber] ||= Queue.new

      @fibers[subscriber] = Fiber.new do
        while @running
          # Process available events
          while !@event_queues[subscriber].empty?
            begin
              event = @event_queues[subscriber].pop(true)
              subscriber.handle_event(event)

              # For deferred mode, yield after each event
              # For scheduled mode, only yield at end of batch
              Fiber.yield if @processing_modes[subscriber] == :deferred
            rescue ThreadError
              # Queue is empty
              break
            end
          end

          # Yield control back to scheduler
          Fiber.yield
        end
      end

      # Register with scheduler
      @scheduler.register(@fibers[subscriber])
    end
  end

  class FiberScheduler
    def initialize
      @fibers = []
    end

    def register(fiber)
      @fibers << fiber
    end

    def resume_all
      @fibers.each do |fiber|
        fiber.resume if fiber.alive?
      end
    end
  end
end
```

### 10.4 Fiber-Based Logger Implementation

```ruby
module Vanilla
  class FiberLogger
    include Singleton

    LOG_LEVELS = {
      debug: 0,
      info: 1,
      warn: 2,
      error: 3,
      fatal: 4
    }.freeze

    def initialize
      @level = ENV['VANILLA_LOG_LEVEL']&.downcase&.to_sym || :info
      @log_env = ENV['VANILLA_LOG_DIR'] || 'development'
      @log_dir = File.join(Dir.pwd, 'logs', @log_env)

      FileUtils.mkdir_p(@log_dir) unless Dir.exist?(@log_dir)
      @log_file = File.join(@log_dir, "vanilla_#{Time.now.strftime('%Y%m%d_%H%M%S')}.log")
      @file = File.open(@log_file, 'w')

      # Write header
      @file.puts "=== Vanilla Game Log Started at #{Time.now} ==="
      @file.flush

      # Message queue
      @message_queue = Queue.new

      # Create fiber for processing logs
      @logging_fiber = Fiber.new do
        loop do
          # Process all queued logs
          process_logs

          # Yield back to game loop
          Fiber.yield
        end
      end

      # Register with event bus
      event_bus = FiberEventBus.instance
      event_bus.subscribe(:log, self)
      event_bus.set_processing_mode(self, :scheduled)

      # Register fiber with scheduler
      FiberEventBus.instance.scheduler.register(@logging_fiber)
    end

    def debug(message)
      log_message(:debug, message)
    end

    def info(message)
      log_message(:info, message)
    end

    def warn(message)
      log_message(:warn, message)
    end

    def error(message)
      log_message(:error, message)
    end

    def fatal(message)
      log_message(:fatal, message)
    end

    def handle_event(event)
      return unless event.type == :log

      level = event.data[:level]
      message = event.data[:message]
      timestamp = event.data[:timestamp] || Time.now

      @message_queue << [level, message, timestamp]
    end

    def close
      # Process any remaining logs
      process_logs

      @file.puts "=== Vanilla Game Log Ended at #{Time.now} ==="
      @file.close
      @file = nil
    end

    private

    def log_message(level, message)
      return if LOG_LEVELS[level] < LOG_LEVELS[@level]

      event = Event.new(
        type: :log,
        data: {
          level: level,
          message: message,
          timestamp: Time.now
        }
      )

      FiberEventBus.instance.publish(event)
    end

    def process_logs
      while !@message_queue.empty?
        begin
          level, message, timestamp = @message_queue.pop(true)
          write_log(level, message, timestamp)
        rescue ThreadError
          break
        end
      end
    end

    def write_log(level, message, timestamp)
      formatted_time = timestamp.strftime('%Y-%m-%d %H:%M:%S.%L')
      formatted_message = "[#{formatted_time}] [#{level.to_s.upcase}] #{message}"
      @file.puts(formatted_message)
      @file.flush
    end
  end
end
```

### 10.5 Game Loop Integration with Fibers

```ruby
module Vanilla
  class Game
    def initialize
      # Initialize systems
      @event_bus = FiberEventBus.instance
      @logger = FiberLogger.instance

      # Other game initialization
      # ...
    end

    def update(delta_time)
      # Update game state
      # ...

      # Process immediate events directly
      # Deferred and scheduled events will be processed when tick_fibers is called
    end

    def render
      # Render game state
      # ...
    end

    def run
      last_time = Time.now

      loop do
        current_time = Time.now
        delta_time = current_time - last_time
        last_time = current_time

        update(delta_time)
        render

        # Tick fibers at the end of the frame
        # This gives fibers a chance to run without blocking the game loop
        tick_fibers

        # Cap frame rate if needed
        # ...
      end
    end

    private

    def tick_fibers
      @event_bus.tick
    end
  end
end
```

### 10.6 Benefits of Fiber-Based Approach

1. **Resource Efficiency**:
   - Fibers are lightweight (approximately 4KB per fiber vs ~1MB per thread)
   - No OS-level context switching overhead
   - Lower memory footprint for large numbers of concurrent tasks

2. **Cooperative Multitasking**:
   - Explicit yield points give precise control over when fibers run
   - No preemption means fewer race conditions
   - Simpler synchronization (often no mutexes needed)

3. **Deterministic Behavior**:
   - Game loop maintains control over when fibers run
   - Easier to debug since execution order is more predictable
   - Better for game development where determinism is important

4. **Improved in Ruby 3.0+**:
   - Fiber scheduler API (`Fiber.scheduler`) for auto-scheduling
   - Non-blocking I/O integration with Fibers
   - Better support for asynchronous programming

### 10.7 Drawbacks of Fiber-Based Approach

1. **Limited Parallelism**:
   - Fibers in Ruby are not parallel (only one runs at a time)
   - Cannot utilize multiple CPU cores directly
   - CPU-bound tasks will block other fibers

2. **Explicit Yield Requirement**:
   - Fibers must explicitly yield control
   - Long-running operations need to be broken into smaller steps
   - Third-party libraries may not be fiber-aware

3. **Development Complexity**:
   - Less familiar to many developers than thread-based concurrency
   - Requires careful consideration of where to yield
   - Error handling is more complex in fiber-based code

4. **Ruby Version Requirements**:
   - Best features require Ruby 3.0+ for scheduler support
   - Older Ruby versions have less efficient fiber implementations
   - Non-blocking I/O integration is limited in older Ruby versions

### 10.8 Background Jobs Alternative

For operations that need true parallelism or should run outside the game process:

```ruby
# Using a simple background job system (Sidekiq-like)
module Vanilla
  class BackgroundJob
    def self.enqueue(job_class, *args)
      Thread.new do
        job = job_class.new
        job.perform(*args)
      end
    end
  end

  class AnalyticsJob
    def perform(event_data)
      # Connect to external service
      # Send analytics data
      # This runs in a separate thread
    end
  end

  # Usage:
  BackgroundJob.enqueue(AnalyticsJob, { level: 5, score: 10000 })
```

### 10.9 Recommended Hybrid Approach

We recommend a hybrid approach that combines the best aspects of threads, fibers, and background jobs:

1. **Use Fibers for:**
   - In-game event handling (logging, achievements, etc.)
   - Processing game state updates that can be deferred
   - Any I/O that can be made non-blocking

2. **Use Threads for:**
   - I/O operations that cannot be made non-blocking
   - CPU-intensive tasks that would block the game loop
   - Tasks that need true parallelism

3. **Use Background Jobs for:**
   - Analytics and telemetry
   - Cloud saves and synchronization
   - Content downloads and updates
   - Any task that can be completely separated from the game

### 10.10 Implementation Recommendation

For the Vanilla game engine, we recommend:

1. **Start with Fiber-based architecture** for the event system and logger
2. **Use Ruby 3.0+ features** like `Fiber.scheduler` when available
3. **Fall back to threads** for operations that need parallelism
4. **Consider a simple background job system** for completely separate operations

This hybrid approach provides the best balance of:
- Performance (faster game loop, less resource usage)
- Simplicity (easier to reason about than complex thread synchronization)
- Scalability (can use multiple cores when needed)
- Flexibility (different processing approaches for different needs)

By implementing this architecture, Vanilla will achieve the goal of separating logging and event handling from the main game loop while gaining additional performance and maintainability benefits.