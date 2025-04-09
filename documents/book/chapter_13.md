# Chapter 13: Logging and Debugging

Welcome back, game developers! By now, your roguelike is a bustling dungeon with twisting mazes, treasures to snatch, and monsters lurking in the shadows. But as your game grows, so does the chance for things to go awry. Did the player just clip through a wall? Why isn't that potion showing up? In this chapter, we're going to arm you with a powerful toolset to tackle these mysteries: a robust `Logger` class to record game events and facilitate debugging. We'll implement proper file-based logging with timestamped files for each game session, making it easy to track what's happening in your game and diagnose issues effectively.

## Implementing a Robust Logger for Game Events

First up, we need a way to capture and record what's happening in your game. Our `Logger` class will write messages to a file with timestamps, saving each session in its own log file. This approach ensures you can always go back and analyze what happened during a particular play session.

Here's how to set up your logger:

```ruby
# lib/logger.rb
require 'fileutils'

class Logger
  class << self
    def initialize
      # Create logs directory if it doesn't exist
      FileUtils.mkdir_p("logs")

      # Create a new log file with timestamp
      timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
      @log_file = File.open("logs/game_#{timestamp}.log", "w")
      @log_file.sync = true  # Ensure immediate writes

      info("Logging started")
    end

    def debug(message)
      log("DEBUG", message)
    end

    def info(message)
      log("INFO", message)
    end

    def error(message)
      log("ERROR", message)
    end

    private

    def log(level, message)
      timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S.%L")
      log_entry = "[#{timestamp}] [#{level}] #{message}\n"

      # Write to file
      @log_file ||= File.open("logs/game_#{Time.now.strftime("%Y%m%d_%H%M%S")}.log", "w")
      @log_file.write(log_entry)

      # Also print to console for immediate feedback during development
      # Comment this line out for production
      # print log_entry
    end
  end
end

# Initialize the logger when the file is required
Logger.initialize
```

### How It Works

- **Class-level Implementation**: The Logger is implemented as class methods, making it easy to call from anywhere in your code without needing to pass around an instance.
- **Automatic Directory Creation**: The logger automatically creates a `logs` directory if it doesn't exist.
- **Timestamped Log Files**: Each game run creates a new log file with a format like `logs/game_20250409_143000.log`, ensuring each session has its own separate log.
- **Immediate Writes**: The `sync = true` flag ensures logs are written immediately, so you don't lose data if the game crashes.
- **Millisecond Precision**: The timestamps include milliseconds, which is helpful for identifying the exact sequence of rapidly occurring events.
- **Development Feedback**: You can uncomment the `print` line during development to see logs in real-time in the console.

## Adding Logger to .gitignore

Since log files can be numerous and aren't part of your core codebase, it's good practice to exclude them from version control. Add these lines to your `.gitignore` file:

```
# .gitignore
# Logs
/logs/
*.log
```

This ensures your repository stays clean and focused on code, not debug output.

## Integrating the Logger with Your Game Systems

Now let's update our game systems to use the logger. Here's how to integrate it with the `World` class:

```ruby
# lib/world.rb (partial)
require_relative "logger"

class World
  attr_reader :entities, :systems, :event_manager, :width, :height, :current_level

  def initialize(width: 10, height: 5)
    @entities = {}
    @systems = []
    @next_id = 0
    @width = width
    @height = height
    @running = true
    @event_manager = EventManager.new
    @current_level = 1
    @keyboard = KeyboardHandler.new
    Logger.info("World initialized: width=#{width}, height=#{height}")
  end

  def create_entity
    entity = Entity.new(@next_id)
    @entities[@next_id] = entity
    @next_id += 1
    Logger.debug("Entity created: id=#{entity.id}")
    entity
  end

  def add_system(system)
    @systems << system
    Logger.debug("System added: #{system.class.name}")
    self
  end

  def run
    setup_level
    Logger.info("Game started")

    while @running
      # Handle input first - this is critical for responsive gameplay
      handle_input

      # Process all systems in order
      @systems.each do |system|
        Logger.debug("Processing system: #{system.class.name}")
        case system
        when Systems::MazeSystem
          system.process(@entities.values)
        when Systems::InputSystem
          system.process(@entities.values)
        when Systems::MovementSystem
          system.process(@entities.values, @width, @height)
          # Check for level completion immediately after movement
          check_level_completion
        when Systems::RenderSystem
          system.process(@entities.values)
        end
      end

      # Clear events after the turn
      @event_manager.clear
    end

    Logger.info("Game ended")
    puts "Goodbye!"
  end

  # ... rest of the class ...
end
```

### Logging Movement in the MovementSystem

Here's how you can add logging to your `MovementSystem`:

```ruby
# lib/systems/movement_system.rb (partial)
require_relative "../logger"

module Systems
  class MovementSystem
    def initialize(world)
      @world = world # Access to all entities for collision checks
    end

    def process(entities, grid_width, grid_height)
      Logger.debug("MovementSystem processing #{entities.size} entities")

      entities.each do |entity|
        next unless entity.has_component?(Components::Position) &&
                    entity.has_component?(Components::Movement)

        pos = entity.get_component(Components::Position)
        mov = entity.get_component(Components::Movement)

        # Skip if no movement
        if mov.dx == 0 && mov.dy == 0
          Logger.debug("No movement for entity #{entity.id}")
          next
        end

        Logger.debug("Processing movement for entity #{entity.id}: dx=#{mov.dx}, dy=#{mov.dy}")
        Logger.debug("Current position: x=#{pos.x}, y=#{pos.y}")

        # Calculate proposed new position
        new_x = pos.x + mov.dx
        new_y = pos.y + mov.dy
        Logger.debug("Proposed new position: x=#{new_x}, y=#{new_y}")

        # Check grid boundaries
        unless new_x.between?(0, grid_width - 1) && new_y.between?(0, grid_height - 1)
          Logger.debug("Out of bounds: x=#{new_x}, y=#{new_y}, width=#{grid_width}, height=#{grid_height}")
          mov.dx = 0
          mov.dy = 0
          next
        end

        # Check for wall collision
        if wall_at?(new_x, new_y)
          Logger.debug("Wall collision at x=#{new_x}, y=#{new_y}")
          # Reset movement if blocked
          mov.dx = 0
          mov.dy = 0
          next
        end

        # If clear, update position
        pos.x = new_x
        pos.y = new_y
        Logger.debug("Position updated: x=#{pos.x}, y=#{pos.y}")

        # Reset movement after applying
        mov.dx = 0
        mov.dy = 0
      end
    end

    # ... rest of the class ...
  end
end
```

### Logging Input Handling

Add logging to the input handling to track key presses:

```ruby
# lib/systems/input_system.rb (partial)
require_relative "../event"
require_relative "../logger"

module Systems
  class InputSystem
    def initialize(event_manager)
      @event_manager = event_manager
    end

    def process(entities)
      @event_manager.process do |event|
        next unless event.type == :key_pressed

        key = event.data[:key]
        Logger.debug("Key pressed: #{key}")

        player = entities.find { |e| e.has_component?(Components::Input) }
        if player
          Logger.debug("Player found, processing movement")
          case key
          when "w" then issue_move_command(player, 0, -1)   # Up
          when "s" then issue_move_command(player, 0, 1)    # Down
          when "a" then issue_move_command(player, -1, 0)   # Left
          when "d" then issue_move_command(player, 1, 0)    # Right
          end
        else
          Logger.error("Player not found!")
        end
      end
    end

    private

    def issue_move_command(entity, dx, dy)
      return unless entity.has_component?(Components::Movement)

      movement = entity.get_component(Components::Movement)
      movement.dx = dx
      movement.dy = dy
      Logger.debug("Movement command issued: dx=#{dx}, dy=#{dy}")
    end
  end
end
```

## Handling Input and Critical Game Loop Order

One of the most important lessons from our game development is the critical importance of the game loop order. The logger helps us see and verify that the input is processed before systems are run. This ensures responsive gameplay, especially in turn-based games.

Here's the key part in our `World` class:

```ruby
def run
  setup_level
  Logger.info("Game started")

  while @running
    # Handle input first - this is critical for responsive gameplay
    handle_input

    # Process all systems in order
    @systems.each do |system|
      # ... system processing ...
    end

    # Clear events after the turn
    @event_manager.clear
  end

  Logger.info("Game ended")
  puts "Goodbye!"
end
```

The logger provides visual confirmation that events are flowing through the game in the correct order:

```
[2025-04-09 14:30:45.123] [DEBUG] Waiting for input
[2025-04-09 14:30:46.234] [DEBUG] Input received: w
[2025-04-09 14:30:46.235] [DEBUG] Queueing key_pressed event: w
[2025-04-09 14:30:46.236] [DEBUG] Processing system: Systems::InputSystem
[2025-04-09 14:30:46.237] [DEBUG] Key pressed: w
[2025-04-09 14:30:46.238] [DEBUG] Player found, processing movement
[2025-04-09 14:30:46.239] [DEBUG] Movement command issued: dx=0, dy=-1
```

## Analyzing Game Logs

After playing your game, you'll have a set of log files in the `logs` directory. Each file contains a detailed record of a game session. Here's how to get the most out of them:

1. **Find the Right Log**: Logs are named with timestamps, so you can identify the session you want to analyze.
2. **Look for Patterns**: Search for repeated errors or warnings that might indicate a systematic issue.
3. **Track Entity Lifecycle**: Follow how entities are created, modified, and removed throughout the game.
4. **Examine Movement**: Look at how the player and other entities move around the grid.
5. **Verify System Processing**: Ensure all systems are being processed in the correct order.

For example, if the player isn't moving as expected, you might find log lines like:

```
[2025-04-09 14:35:12.456] [DEBUG] Key pressed: w
[2025-04-09 14:35:12.457] [DEBUG] Player found, processing movement
[2025-04-09 14:35:12.458] [DEBUG] Movement command issued: dx=0, dy=-1
[2025-04-09 14:35:12.459] [DEBUG] Processing movement for entity 0: dx=0, dy=-1
[2025-04-09 14:35:12.460] [DEBUG] Current position: x=5, y=5
[2025-04-09 14:35:12.461] [DEBUG] Proposed new position: x=5, y=4
[2025-04-09 14:35:12.462] [DEBUG] Wall collision at x=5, y=4
```

This tells you the player tried to move up but encountered a wall - exactly the kind of insight that helps solve gameplay issues!

## Outcome

In this chapter, you've:
- Implemented a robust Logger class that writes to timestamped files
- Added logging throughout your game systems to track events
- Set up your gitignore to exclude log files from version control
- Learned how to analyze logs to diagnose gameplay issues
- Reinforced the importance of correct game loop order

With this logging system in place, you now have a powerful tool for understanding and debugging your roguelike game. The detailed log files provide a window into your game's inner workings, making it easier to identify and fix issues.

In the next chapter, we'll build on this foundation to enhance the user interface and player experience!

---

### Notes for Readers

- **Strategic Logging**: Don't just log everything - think about what information would be most useful when debugging.
- **Performance Consideration**: In a production game, you might want to disable some of the more verbose debug logs to improve performance.
- **Log Rotation**: For a long-running game, consider implementing log rotation to prevent files from getting too large.
- **Game Loop Order**: Remember that the order of operations in the game loop is critical - always handle input first!

This logging system is designed to be a practical tool that helps you understand and improve your game, not just a theoretical exercise.