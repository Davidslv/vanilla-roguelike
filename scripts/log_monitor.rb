#!/usr/bin/env ruby

# USAGE:
# .scripts/log_monitor.rb

require 'json'
require 'time'
require 'fileutils'

class LogMonitor
  LOGS_DIR = File.join(Dir.pwd, 'logs', 'development')

  KNOWN_ISSUES = {
    level_transition_freeze: {
      pattern: /Player at stairs.*transition.*Found stairs leading to depth/,
      description: "Game freezes after level transition",
      solution: "The game isn't properly continuing after level transition. Fix the game_loop method to properly reset input handling after level transitions."
    },
    event_serialization_error: {
      pattern: /events\/event\.rb.*Symbol#inspect|to_json|events.*Interrupt/,
      description: "Event serialization error during level transition",
      solution: "Replace non-serializable objects in event data with simple serializable values."
    },
    input_handling_error: {
      pattern: /undefined method/,
      description: "Method error in input handling",
      solution: "Check method definitions in input handler or missing requires."
    },
    missing_translation: {
      pattern: /missing interpolation argument|translation missing/,
      description: "Translation missing or incorrect",
      solution: "Check locale files and message parameters."
    }
  }

  def initialize
    @current_log = nil
    @last_position = 0
    @issues_detected = []
    @fixed_issues = []
  end

  def run
    puts "🔍 Starting Vanilla Game Log Monitor..."
    puts "Watching logs in: #{LOGS_DIR}"
    puts "Press Ctrl+C to exit\n\n"

    loop do
      find_latest_log
      read_new_log_entries if @current_log
      display_status
      sleep 0.5
    end
  rescue Interrupt
    puts "\n\nLog monitoring stopped. Detected issues summary:"
    @issues_detected.each do |issue|
      puts "- #{issue[:time]}: #{issue[:type]} - #{issue[:message]}"
    end
  end

  private

  def find_latest_log
    log_files = Dir.glob(File.join(LOGS_DIR, 'vanilla_*.log')).sort_by { |f| File.mtime(f) }.reverse
    latest_log = log_files.first

    if latest_log != @current_log
      @current_log = latest_log
      @last_position = 0
      puts "\n📋 Monitoring new log file: #{File.basename(@current_log)}"
    end
  end

  def read_new_log_entries
    return unless File.exist?(@current_log)

    current_size = File.size(@current_log)
    if current_size > @last_position
      File.open(@current_log, 'r') do |file|
        file.seek(@last_position)
        new_content = file.read

        # Process the new content
        analyze_log_content(new_content)
      end
      @last_position = current_size
    end
  end

  def analyze_log_content(content)
    # Extract log entries
    log_entries = content.split("\n").select { |line| line.match(/^\[.*\]/) }

    # Also catch stack traces
    if content.include?('Error') || content.include?('Exception') || content.include?('Interrupt')
      check_for_stack_trace(content)
    end

    log_entries.each do |entry|
      timestamp_match = entry.match(/\[(.*?)\]/)
      next unless timestamp_match

      timestamp = timestamp_match[1]

      # Check for known issues
      KNOWN_ISSUES.each do |issue_type, issue_info|
        if entry.match(issue_info[:pattern])
          issue = {
            time: timestamp,
            type: issue_type,
            message: issue_info[:description],
            solution: issue_info[:solution],
            log_entry: entry
          }

          @issues_detected << issue
          puts "\n⚠️  ISSUE DETECTED: #{issue[:type]}"
          puts "   Time: #{issue[:time]}"
          puts "   Description: #{issue[:message]}"
          puts "   Log Entry: #{issue[:log_entry]}"
          puts "   Solution: #{issue[:solution]}"

          if issue[:type] == :event_serialization_error
            suggest_fix_for_event_serialization
          elsif issue[:type] == :level_transition_freeze
            suggest_fix_for_level_transition
          end
        end
      end

      # Track game state
      if entry.include?("Player at stairs")
        puts "👣 Player reached stairs"
      elsif entry.include?("transition")
        puts "🚪 Level transition in progress"
      elsif entry.include?("Level transition complete")
        puts "✅ Level transition completed"
      elsif entry.include?("Player collided with monster")
        puts "👹 Player collided with monster"
      elsif entry.include?("Player exiting game")
        puts "👋 Player exited game"
      else
        puts entry
      end
    end
  end

  def check_for_stack_trace(content)
    # Look for specific error patterns in stack traces
    KNOWN_ISSUES.each do |issue_type, issue_info|
      if content.match(issue_info[:pattern])
        issue = {
          time: Time.now.strftime("%Y-%m-%d %H:%M:%S"),
          type: issue_type,
          message: issue_info[:description],
          solution: issue_info[:solution],
          log_entry: "Stack trace detected with error pattern"
        }

        # Only add if not already detected
        unless @issues_detected.any? { |i| i[:type] == issue_type }
          @issues_detected << issue
          puts "\n🔥 CRITICAL ISSUE DETECTED: #{issue[:type]}"
          puts "   Description: #{issue[:message]}"
          puts "   Solution: #{issue[:solution]}"

          if issue[:type] == :event_serialization_error
            suggest_fix_for_event_serialization
          end
        end
      end
    end
  end

  def display_status
    # Show a simple status indicator
    print "." if rand < 0.5
    STDOUT.flush
  end

  def suggest_fix_for_event_serialization
    puts "\n🔧 Recommended fix for event serialization issue:"
    puts "In lib/vanilla.rb, modify the event data to only include serializable values:"
    puts "
    # Create event for level change - use only serializable data
    @event_manager.publish_event(Events::Types::LEVEL_CHANGED, {
      level_difficulty: current_difficulty,
      new_difficulty: new_difficulty,
      player_stats: {
        position: \"stairs\",
        movement_count: @turn
      }
    })"
  end

  def suggest_fix_for_level_transition
    puts "\n🔧 Recommended fix for level transition issue:"
    puts "In lib/vanilla.rb, modify game_loop method to ensure input handling is reset after level transition"
    puts "
    # After transitioning to a new level
    if level.player_at_stairs?
      @logger.info(\"Player at stairs - transitioning to new level\")
      level = handle_level_transition(level)

      # Re-render the new level
      monster_system = level.instance_variable_get(:@monster_system)
      all_entities = level.all_entities + monster_system.monsters
      @render_system.render(all_entities, level.grid)

      # Re-render message panel
      @message_manager.render(@render_system)

      # Important: Flush any pending input to avoid stuck input buffer
      while STDIN.ready?
        STDIN.read(1)
      end
    end"
  end
end

# Start monitoring if called directly
if __FILE__ == $0
  LogMonitor.new.run
end
