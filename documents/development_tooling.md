# Vanilla Roguelike: Development Tooling

## Overview

This document outlines the development tools, utilities, and best practices for working on the Vanilla roguelike game. It provides guidance on debugging, testing, and ensuring smooth development workflows.

## Table of Contents

1. [Development Environment](#development-environment)
2. [Debugging Tools](#debugging-tools)
3. [Testing Framework](#testing-framework)
4. [Performance Profiling](#performance-profiling)
5. [Development Workflows](#development-workflows)
6. [Tooling Implementation](#tooling-implementation)

## Development Environment

### Ruby Environment

The Vanilla roguelike game is developed in Ruby. Recommended setup:

- Ruby 3.0+ (the game is compatible with Ruby 3.x)
- Bundler for dependency management
- RVM or rbenv for Ruby version management

Environment setup:

```bash
# Install rbenv (macOS)
brew install rbenv ruby-build
rbenv init

# Install Ruby
rbenv install 3.1.2
rbenv global 3.1.2

# Project setup
git clone https://github.com/your-repo/vanilla.git
cd vanilla
bundle install
```

### Editor Integration

Recommended editor configurations:

- **VS Code**: Install Ruby extension and configure:
  ```json
  {
    "ruby.lint": {
      "rubocop": true
    },
    "ruby.format": "rubocop",
    "editor.formatOnSave": true
  }
  ```

- **Vim/Neovim**: Install Ruby plugins:
  ```vim
  Plug 'vim-ruby/vim-ruby'
  Plug 'tpope/vim-endwise'
  Plug 'ngmy/vim-rubocop'
  ```

## Debugging Tools

### Interactive Debug Console

The `DebugConsole` is a tool that allows for runtime inspection and modification of the game state:

```ruby
module Vanilla
  module Debug
    class Console
      def initialize(game)
        @game = game
        @commands = register_commands
      end

      def register_commands
        {
          "help" => method(:cmd_help),
          "inspect" => method(:cmd_inspect),
          "spawn" => method(:cmd_spawn),
          "teleport" => method(:cmd_teleport),
          "god_mode" => method(:cmd_god_mode),
          "reveal_map" => method(:cmd_reveal_map)
        }
      end

      def run(input)
        cmd, *args = input.split
        if @commands.key?(cmd)
          @commands[cmd].call(*args)
        else
          "Unknown command: #{cmd}. Type 'help' for available commands."
        end
      end

      private

      def cmd_help(*args)
        # Return list of commands with descriptions
      end

      def cmd_inspect(*args)
        # Return info about entity or game state
      end

      def cmd_spawn(*args)
        # Spawn entity at position
      end

      def cmd_teleport(*args)
        # Move player to position
      end

      def cmd_god_mode(*args)
        # Toggle invincibility
      end

      def cmd_reveal_map(*args)
        # Reveal entire map
      end
    end
  end
end
```

**Implementation**:

Add a debug key binding (e.g., `) to access the console. In `input_handler.rb`:

```ruby
def handle_input
  # ... existing code ...
  when '`'
    toggle_debug_console
  # ... existing code ...
end

def toggle_debug_console
  @debug_console = Vanilla::Debug::Console.new(@game) unless @debug_console
  # Render console input UI
end
```

### Visual Debugging

Implement visual debugging aids for development:

```ruby
module Vanilla
  module Debug
    class VisualDebugger
      def initialize(renderer)
        @renderer = renderer
        @enabled_layers = {
          pathfinding: false,
          collision: false,
          entity_ids: false,
          performance: false
        }
      end

      def toggle_layer(layer_name)
        @enabled_layers[layer_name] = !@enabled_layers[layer_name] if @enabled_layers.key?(layer_name)
      end

      def render(game_state)
        return unless any_layer_enabled?

        render_pathfinding(game_state) if @enabled_layers[:pathfinding]
        render_collision(game_state) if @enabled_layers[:collision]
        render_entity_ids(game_state) if @enabled_layers[:entity_ids]
        render_performance(game_state) if @enabled_layers[:performance]
      end

      private

      def any_layer_enabled?
        @enabled_layers.values.any?
      end

      def render_pathfinding(game_state)
        # Render pathfinding visualization
      end

      def render_collision(game_state)
        # Render collision boxes
      end

      def render_entity_ids(game_state)
        # Render entity IDs above entities
      end

      def render_performance(game_state)
        # Render performance metrics
      end
    end
  end
end
```

### Logging Enhancement

Improve the existing logger with different log levels and filtering:

```ruby
module Vanilla
  class EnhancedLogger < Logger
    LOG_LEVELS = {
      debug: 0,
      info: 1,
      warn: 2,
      error: 3,
      fatal: 4
    }

    def initialize(log_file = nil, min_level = :info)
      super(log_file)
      @min_level = min_level
      @category_filters = []
    end

    def log(level, message, category = nil)
      return unless should_log?(level, category)

      formatted_message = format_message(level, message, category)
      write(formatted_message)
    end

    def debug(message, category = nil)
      log(:debug, message, category)
    end

    def info(message, category = nil)
      log(:info, message, category)
    end

    def warn(message, category = nil)
      log(:warn, message, category)
    end

    def error(message, category = nil)
      log(:error, message, category)
    end

    def fatal(message, category = nil)
      log(:fatal, message, category)
    end

    def filter_category(category, enabled = true)
      if enabled
        @category_filters.delete(category)
      else
        @category_filters << category unless @category_filters.include?(category)
      end
    end

    def set_min_level(level)
      @min_level = level if LOG_LEVELS.key?(level)
    end

    private

    def should_log?(level, category)
      level_value = LOG_LEVELS[level] || 0
      min_level_value = LOG_LEVELS[@min_level] || 0

      return false if level_value < min_level_value
      return false if category && @category_filters.include?(category)

      true
    end

    def format_message(level, message, category)
      timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S.%L")
      category_str = category ? " [#{category}]" : ""
      "[#{timestamp}] [#{level.to_s.upcase}]#{category_str} #{message}"
    end
  end
end
```

### Event Debugging

Create a tool to monitor and debug events:

```ruby
module Vanilla
  module Debug
    class EventMonitor
      def initialize(event_manager)
        @event_manager = event_manager
        @monitored_events = []
        @event_history = []
        @max_history = 100

        # Subscribe to all events
        @event_manager.subscribe("*", self)
      end

      def handle_event(event)
        return unless monitoring_event?(event.type)

        @event_history << {
          timestamp: Time.now,
          type: event.type,
          source: event.source,
          payload: event.payload
        }

        # Trim history if needed
        @event_history.shift if @event_history.size > @max_history
      end

      def monitor_event(event_type)
        @monitored_events << event_type unless @monitored_events.include?(event_type)
      end

      def stop_monitoring(event_type)
        @monitored_events.delete(event_type)
      end

      def clear_history
        @event_history.clear
      end

      def get_history(event_type = nil)
        return @event_history unless event_type
        @event_history.select { |e| e[:type] == event_type }
      end

      private

      def monitoring_event?(event_type)
        @monitored_events.empty? || @monitored_events.include?(event_type)
      end
    end
  end
end
```

## Testing Framework

### Unit Testing

The project uses RSpec for testing. Best practices for testing Vanilla components:

```ruby
# Example spec for an entity component
RSpec.describe Vanilla::Components::HealthComponent do
  let(:entity) { Vanilla::Entity.new }
  let(:event_manager) { instance_double(Vanilla::Events::EventManager, publish: nil) }
  subject { described_class.new(maximum: 10) }

  before do
    allow(subject).to receive(:event_manager).and_return(event_manager)
    allow(subject).to receive(:entity).and_return(entity)
  end

  describe "#take_damage" do
    it "reduces health by the damage amount" do
      subject.take_damage(3)
      expect(subject.current).to eq(7)
    end

    it "doesn't reduce health below zero" do
      subject.take_damage(15)
      expect(subject.current).to eq(0)
    end

    it "publishes an entity.damaged event" do
      subject.take_damage(3)
      expect(event_manager).to have_received(:publish).with(
        'entity.damaged',
        hash_including(entity: entity, amount: 3)
      )
    end

    it "sets status to dead when health reaches zero" do
      subject.take_damage(10)
      expect(subject.status).to eq(:dead)
    end
  end
end
```

### Integration Testing

Test game systems working together:

```ruby
RSpec.describe "Movement and Combat Integration" do
  let(:grid) { Vanilla::Grid.new(10, 10) }
  let(:event_manager) { Vanilla::Events::EventManager.new }
  let(:player) { create_player_entity }
  let(:monster) { create_monster_entity }
  let(:movement_system) { Vanilla::Systems::MovementSystem.new(grid, event_manager) }
  let(:combat_system) { Vanilla::Systems::CombatSystem.new(grid, event_manager) }

  before do
    # Set up the test environment
    place_entity(player, 5, 5)
    place_entity(monster, 6, 5)

    # Initialize systems
    event_manager.subscribe('entity.move', combat_system)
    event_manager.subscribe('entity.attack', combat_system)
  end

  it "triggers combat when player moves into monster" do
    # Attempt to move player right (into monster)
    movement_system.move(player, :right)

    # Verify player position hasn't changed (blocked by monster)
    expect(player.get_component(Vanilla::Components::PositionComponent).x).to eq(5)

    # Verify combat was triggered
    player_health = player.get_component(Vanilla::Components::HealthComponent)
    monster_health = monster.get_component(Vanilla::Components::HealthComponent)

    # Check health values based on expected combat outcome
    expect(player_health.current).to be < 10  # Player took damage
    expect(monster_health.current).to be < 10  # Monster took damage
  end

  # Helper methods
  def create_player_entity
    # Create and configure player entity
  end

  def create_monster_entity
    # Create and configure monster entity
  end

  def place_entity(entity, x, y)
    # Position entity on the grid
  end
end
```

### Automated Test Suite

Set up a comprehensive test suite in the `spec/` directory:

```
spec/
├── lib/
│   ├── vanilla/
│   │   ├── algorithms/
│   │   ├── components/
│   │   ├── entities/
│   │   ├── events/
│   │   ├── systems/
│   │   ├── game_spec.rb
│   │   └── level_spec.rb
│   └── spec_helper.rb
├── integration/
│   ├── game_loop_spec.rb
│   ├── monster_player_spec.rb
│   └── level_generation_spec.rb
└── performance/
    ├── rendering_performance_spec.rb
    └── entity_update_spec.rb
```

Run the suite with:

```bash
bundle exec rspec                # Run all tests
bundle exec rspec spec/lib       # Run unit tests
bundle exec rspec spec/integration # Run integration tests
```

## Performance Profiling

### Runtime Profiling

Implement a simple in-game profiler:

```ruby
module Vanilla
  module Debug
    class Profiler
      def initialize
        @sections = {}
        @current_section = nil
        @enabled = false
      end

      def enable
        @enabled = true
        reset
      end

      def disable
        @enabled = false
      end

      def start_section(name)
        return unless @enabled

        @current_section = name
        @sections[name] ||= { count: 0, total_time: 0, last_start: nil }
        @sections[name][:last_start] = Time.now
        @sections[name][:count] += 1
      end

      def end_section
        return unless @enabled
        return unless @current_section

        section = @sections[@current_section]
        return unless section && section[:last_start]

        elapsed = Time.now - section[:last_start]
        section[:total_time] += elapsed
        @current_section = nil
      end

      def reset
        @sections.clear
        @current_section = nil
      end

      def report
        return {} unless @enabled

        result = {}
        @sections.each do |name, data|
          avg_time = data[:count] > 0 ? data[:total_time] / data[:count] : 0
          result[name] = {
            calls: data[:count],
            total_time: data[:total_time],
            average_time: avg_time
          }
        end

        result
      end
    end
  end
end
```

Usage in game loop:

```ruby
def game_loop
  profiler = Vanilla::Debug::Profiler.new
  profiler.enable if @debug_mode

  loop do
    profiler.start_section(:input)
    # Handle input
    profiler.end_section

    profiler.start_section(:update)
    # Update game state
    profiler.end_section

    profiler.start_section(:render)
    # Render game
    profiler.end_section

    if @debug_mode && @show_profiler
      render_profiler_data(profiler.report)
    end

    break if @game_over
  end
end
```

### Memory Analysis

For memory debugging, implement a simple memory tracker:

```ruby
module Vanilla
  module Debug
    class MemoryTracker
      def initialize
        @snapshots = {}
      end

      def take_snapshot(name)
        GC.start # Force garbage collection
        @snapshots[name] = {
          time: Time.now,
          object_counts: count_objects,
          memory_usage: get_memory_usage
        }
      end

      def compare_snapshots(first, second)
        return nil unless @snapshots[first] && @snapshots[second]

        first_snap = @snapshots[first]
        second_snap = @snapshots[second]

        diff = {
          elapsed_time: second_snap[:time] - first_snap[:time],
          object_diff: {},
          memory_diff: second_snap[:memory_usage] - first_snap[:memory_usage]
        }

        second_snap[:object_counts].each do |klass, count|
          first_count = first_snap[:object_counts][klass] || 0
          diff[:object_diff][klass] = count - first_count
        end

        diff
      end

      private

      def count_objects
        counts = {}
        ObjectSpace.each_object do |obj|
          klass = obj.class.to_s
          counts[klass] ||= 0
          counts[klass] += 1
        end
        counts
      end

      def get_memory_usage
        # Platform-specific memory usage retrieval
        # This is a simplified version
        GC.stat[:total_allocated_objects]
      end
    end
  end
end
```

## Development Workflows

### Feature Development Process

1. **Planning**:
   - Define the feature in a design document
   - Create UML diagrams if needed
   - Define acceptance criteria

2. **Implementation**:
   - Write tests first (TDD approach)
   - Implement the feature
   - Add debug tools if needed

3. **Testing**:
   - Run automatic tests
   - Perform manual testing with debug tools
   - Profile performance impact

4. **Documentation**:
   - Update code documentation
   - Update gameplay documentation if needed

### Code Review Checklist

- Does the code follow Ruby style conventions?
- Are there tests for the new functionality?
- Is the code performant and efficient?
- Are there potential memory leaks?
- Is the code maintainable and well-documented?
- Does it integrate well with existing systems?

### Git Workflow

Recommended Git branching strategy:

```
main                  # Stable release branch
└── develop           # Integration branch
    ├── feature/x     # Feature branches
    ├── bugfix/y      # Bug fix branches
    └── refactor/z    # Refactoring branches
```

Commit message format:

```
<type>: <summary>

<description>

<footer>
```

Where `<type>` is one of:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation change
- `style`: Formatting, missing semicolons, etc.
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `perf`: Code change that improves performance
- `test`: Adding or modifying tests

## Tooling Implementation

### Debug Tool Integration

To integrate all debugging tools, create a debug manager:

```ruby
module Vanilla
  module Debug
    class DebugManager
      attr_reader :console, :visual_debugger, :profiler, :event_monitor, :memory_tracker

      def initialize(game)
        @game = game
        @enabled = false
        @console = Console.new(game)
        @visual_debugger = VisualDebugger.new(game.renderer)
        @profiler = Profiler.new
        @event_monitor = EventMonitor.new(game.event_manager)
        @memory_tracker = MemoryTracker.new

        # Set up keyboard shortcuts
        setup_shortcuts
      end

      def toggle
        @enabled = !@enabled
        @profiler.enable if @enabled
        @profiler.disable unless @enabled
      end

      def enabled?
        @enabled
      end

      def update
        return unless @enabled
        # Update debug state
      end

      def render
        return unless @enabled

        @visual_debugger.render(@game)
        render_debug_overlay
      end

      private

      def setup_shortcuts
        # Register debug keyboard shortcuts
      end

      def render_debug_overlay
        # Render debug information
      end
    end
  end
end
```

### Usage Example

Integrate the debug manager into the game:

```ruby
module Vanilla
  class Game
    def initialize
      # ... existing initialization ...
      @debug_manager = Debug::DebugManager.new(self) if ENV['VANILLA_DEBUG']
    end

    def update
      # ... existing update logic ...
      @debug_manager.update if @debug_manager
    end

    def render
      # ... existing render logic ...
      @debug_manager.render if @debug_manager && @debug_manager.enabled?
    end

    def toggle_debug
      @debug_manager&.toggle
    end
  end
end
```

Enable debug mode when launching the game:

```bash
VANILLA_DEBUG=1 ruby bin/vanilla.rb
```

## Conclusion

The tooling outlined in this document provides a comprehensive set of utilities for efficient development of the Vanilla roguelike game. These tools not only aid in identifying and fixing issues but also provide insights into game performance and behavior. By following the recommended workflows and leveraging these tools, developers can ensure a smooth development process and high-quality game experience.