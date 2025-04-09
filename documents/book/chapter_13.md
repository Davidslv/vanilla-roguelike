# Chapter 13: Logging and Debugging

Welcome back, game developers! By now, your roguelike is a bustling dungeon with twisting mazes, treasures to snatch, and monsters lurking in the shadows. But as your game grows, so does the chance for things to go awry. Did the player just clip through a wall? Why isn’t that potion showing up? In this chapter, we’re going to arm you with a powerful toolset to tackle these mysteries: a `Logger` singleton to record game events and a handy `log_monitor.rb` script to watch them unfold live. We’ll store logs in a `logs/` folder with timestamped filenames, preserving every session for later sleuthing. We won’t fill your code with log statements—that’s up to you to decide where they’re most useful. By the end, you’ll be ready to debug like a pro, turning bugs into victories. Let’s get logging!

## Implementing a Simple Logger Singleton for Game Events

First up, we need a way to capture what’s happening in your game. Enter the `Logger` singleton—a single, shared instance that writes messages to both the terminal and a file. It’ll live in `lib/logger.rb` and save logs in a `logs/` folder with filenames like `game_2025-04-09_14-30-00.log`. Each time you start the game, you’ll get a fresh log file, timestamped for posterity.

Here’s how to set it up:

```ruby
# lib/logger.rb
require "fileutils"

class Logger
  LEVELS = { debug: 0, info: 1, warn: 2, error: 3 }.freeze

  # Singleton setup: only one Logger exists
  private_class_method :new
  @@instance = nil

  def self.instance
    @@instance ||= new
  end

  def initialize
    # Create logs directory if it doesn’t exist
    logs_dir = "logs"
    FileUtils.mkdir_p(logs_dir) unless Dir.exist?(logs_dir)

    # Generate a timestamped filename
    timestamp = Time.now.strftime("%Y-%m-%d_%H-%M-%S")
    log_file = File.join(logs_dir, "game_#{timestamp}.log")
    @file = File.open(log_file, "a")  # Append mode
    @level = LEVELS[:info]  # Default to info level
  end

  def debug(message)
    log(:debug, message)
  end

  def info(message)
    log(:info, message)
  end

  def warn(message)
    log(:warn, message)
  end

  def error(message)
    log(:error, message)
  end

  def set_level(level)
    @level = LEVELS[level] || LEVELS[:info]
  end

  def close
    @file.close
  end

  private

  def log(level, message)
    return if LEVELS[level] < @level
    timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
    formatted = "[#{timestamp}] [#{level.upcase}] #{message}"
    puts formatted  # Show in terminal
    @file.puts formatted  # Write to file
    @file.flush  # Save it right away
  end
end
```

### How It Works

- **Singleton Magic**: The `private_class_method :new` and `@@instance` trick means there’s only one `Logger`. Call `Logger.instance` anywhere to use it—no passing objects around!
- **Timestamped Logs**: Each game run creates a new file like `logs/game_2025-04-09_14-30-00.log`. The `Time.now.strftime` format ensures uniqueness, and `File.join` keeps it cross-platform.
- **Log Levels**: Choose from `debug` (chatty details), `info` (key events), `warn` (heads-up issues), or `error` (big problems). Set the level with `Logger.instance.set_level(:debug)` to see everything, or `:warn` to quiet it down.
- **File and Terminal**: Logs hit both the screen (via `puts`) and the file (via `@file.puts`), with `flush` ensuring they’re saved instantly—no lost data if the game crashes.
- **Cleanup**: `close` shuts the file when you’re done, keeping things tidy.

To hook it into your game, add it to `game.rb`—it’s optional in `World`, but here’s a taste:

```ruby
# game.rb (partial)
require_relative "lib/logger"
# ... other requires ...

world = World.new(width: 10, height: 5)
Logger.instance.info("Game started!")  # Quick test log
# ... player setup and systems ...
world.run
Logger.instance.close  # Clean up
```

Run your game, and you’ll see a `logs/` folder appear with a new log file each time!

## Adding a Log Monitoring Script

Logging to a file is great for history, but what if you want to watch events as they happen without crowding your game’s terminal? Let’s create `log_monitor.rb` to tail the latest log file in real time, like a live debug feed.

Here’s the script:

```ruby
# log_monitor.rb
require "fileutils"

LOGS_DIR = "logs"

def latest_log_file
  return nil unless Dir.exist?(LOGS_DIR)
  Dir.entries(LOGS_DIR)
     .select { |f| f.start_with?("game_") && f.end_with?(".log") }
     .sort
     .last
end

def tail_file(file_path)
  unless file_path && File.exist?(file_path)
    puts "No log file found in #{LOGS_DIR}. Waiting for game to start..."
    sleep 1 until (file_path = latest_log_file) && File.exist?(file_path)
  end

  puts "Monitoring #{file_path}. Press Ctrl+C to stop."
  File.open(file_path, "r") do |file|
    file.seek(0, IO::SEEK_END)  # Jump to the end
    loop do
      line = file.gets
      if line
        puts line.chomp  # Print new lines
      else
        sleep 0.1  # Chill if nothing’s new
      end
    end
  end
rescue Interrupt
  puts "\nStopped monitoring logs."
end

if __FILE__ == $0
  tail_file(latest_log_file)
end
```

### How It Works

- **Finding the Latest Log**: `latest_log_file` scans `logs/` for files matching `game_*.log`, sorts them (timestamps make this chronological), and picks the last one—your current session.
- **Tailing**: Opens the latest file, jumps to the end, and waits for new lines with `gets`. If nothing’s there, it naps for 0.1 seconds to avoid hogging your CPU.
- **Waiting Game**: If no log exists yet (game hasn’t started), it waits patiently until one appears.
- **Exit Gracefully**: Hit Ctrl+C, and it stops cleanly with a farewell message.

To use it, open a second terminal, navigate to your project folder, and run:

```bash
ruby log_monitor.rb
```

Then start your game in the first terminal (`ruby game.rb`). Watch the monitor light up with logs as you play!

## Using Logs to Trace System Interactions

The `Logger` is ready, but where should you use it? That’s your call! We’re not hardcoding logs into every system—this is your debugging playground. Here’s how you can sprinkle logs across your ECS to track what’s happening:

- **Movement**: Drop `Logger.instance.debug("Player moved to (#{pos.x}, #{pos.y})")` in `MovementSystem` to see every step.
- **Item Pickups**: Add `Logger.instance.info("Picked up #{item.name}")` in `ItemInteractionSystem` to confirm loot grabs.
- **Combat**: Use `Logger.instance.warn("Player health low: #{health.current}")` in `BattleSystem` to flag danger zones.

### Try It Out

Here’s a quick example you might add to `MovementSystem`—but it’s not in the default code:

```ruby
# Example (not in codebase)
def process(entities, grid_width, grid_height)
  entities.each do |entity|
    if entity.has_component?(Components::Position)
      pos = entity.get_component(Components::Position)
      Logger.instance.debug("Entity #{entity.id} at (#{pos.x}, #{pos.y})")
    end
  end
end
```

- **Flexibility**: Start with `debug` for nitty-gritty details, bump to `info` for milestones, or save `error` for crashes.
- **Control**: Crank up verbosity with `Logger.instance.set_level(:debug)` in `game.rb` before `world.run`, or dial it back with `:info`.

Your log file might look like this after a short session:

```
[2025-04-09 14:30:00] [INFO] Game started!
[2025-04-09 14:30:02] [DEBUG] Player moved to (2, 1)
[2025-04-09 14:30:03] [INFO] Picked up Gold Coin
[2025-04-09 14:30:05] [INFO] Game ended
```

Check `logs/` after playing—you’ll have a permanent record to dissect later!

## Outcome

In this chapter, you’ve:
- Built a `Logger` singleton that writes timestamped logs to `logs/` (e.g., `game_2025-04-09_14-30-00.log`).
- Created `log_monitor.rb` to watch the latest log live in a separate terminal.
- Learned how to trace system interactions by adding `Logger.instance` calls where you need them.

You’re now equipped to debug like a detective! Drop `Logger.instance.debug` or `info` into your systems to see what’s ticking—or misfiring. Run your game and the monitor side by side, and keep every session’s story in `logs/` for future reference. If the player’s stuck or an enemy’s missing, your logs will spill the beans. Up next, maybe a win condition or a slicker UI? Add some logs, fire up `log_monitor.rb`, and take control of your game’s secrets!

---

### Notes for Readers

- **Where to Log**: Start small—log player movement or level changes. As bugs pop up, add more where you’re stumped.
- **File Growth**: Each run gets its own file, so your `logs/` folder will grow. Clean it out manually if it gets crowded—log rotation’s a future adventure!
- **Real-Time Power**: The monitor script is your live window—perfect for catching glitches as they happen.

This keeps the chapter focused on the tools, leaving the fun of applying them to the readers.