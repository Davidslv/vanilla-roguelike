# Event Visualization Guide

The Vanilla game includes a powerful event visualization tool that helps with debugging and understanding game event flow.

## Overview

The event visualization system takes event logs created by the `FileEventStore` and generates interactive HTML timelines. This allows developers to:

1. View all events in chronological order
2. Filter events by type
3. Search for specific data in events
4. Analyze timing and relationships between events
5. Debug complex gameplay sequences

## Using the Visualization Tool

### Basic Usage

```ruby
require_relative 'lib/vanilla/events/event_visualization'

# Create a visualization from the most recent session
event_store = Vanilla::Events::FileEventStore.new("event_logs")
visualizer = Vanilla::Events::EventVisualization.new(event_store)

# Generate HTML timeline for the latest session
output_path = visualizer.generate_timeline

puts "Timeline generated at: #{output_path}"
# Open the HTML file in your browser
```

### Visualizing a Specific Session

```ruby
# List available sessions
sessions = Dir.glob("event_logs/*.jsonl").map { |f| File.basename(f, '.jsonl') }
puts "Available sessions:"
puts sessions

# Generate timeline for a specific session
output_path = visualizer.generate_timeline("20250318_144611")
```

## Analyzing the Timeline

The generated HTML timeline provides several features:

### Navigation

- **Filter by Type**: Toggle event types on/off using checkboxes
- **Search**: Filter events by text content
- **Expand/Collapse**: Toggle detailed views of all events

### Timeline View

The timeline shows:
- Events grouped by type
- Chronological markers showing when each event occurred
- Time offsets from the start of the session
- Interactive event details on click

### Understanding Event Flow

The visualization is particularly useful for:

1. **Debugging Race Conditions**: Identify events happening in unexpected order
2. **Finding Anomalies**: Spot gaps or clusters in event timing
3. **Tracing Causality**: Follow the chain of events leading to a bug
4. **Performance Analysis**: Identify bottlenecks in game logic

## Creating a Debugging Script

Create a debugging script at `scripts/visualize_events.rb`:

```ruby
#!/usr/bin/env ruby

require_relative '../lib/vanilla/events/event_store'
require_relative '../lib/vanilla/events/event_visualization'

def list_sessions
  sessions = Dir.glob("event_logs/*.jsonl").map { |f| File.basename(f, '.jsonl') }.sort
  puts "Available sessions:"
  sessions.each_with_index { |s, i| puts "#{i+1}. #{s}" }
  return sessions
end

def visualize_session(session_id = nil)
  event_store = Vanilla::Events::FileEventStore.new("event_logs")
  visualizer = Vanilla::Events::EventVisualization.new(event_store)

  if session_id.nil?
    session_id = visualizer.latest_session_id
  end

  output_path = visualizer.generate_timeline(session_id)
  if output_path
    puts "Timeline generated at: #{output_path}"
    # Try to open the file with the default browser
    if RbConfig::CONFIG['host_os'] =~ /darwin/
      system "open #{output_path}"
    elsif RbConfig::CONFIG['host_os'] =~ /linux/
      system "xdg-open #{output_path}"
    elsif RbConfig::CONFIG['host_os'] =~ /mswin|mingw/
      system "start #{output_path}"
    else
      puts "Please open the file manually in your browser"
    end
  else
    puts "No events found for session #{session_id}"
  end
end

# Script execution starts here
if ARGV.empty?
  sessions = list_sessions
  if sessions.empty?
    puts "No session logs found in event_logs directory."
    exit 1
  end

  puts "Enter session number to visualize (or press Enter for latest):"
  input = gets.chomp

  if input.empty?
    visualize_session
  else
    index = input.to_i - 1
    if index >= 0 && index < sessions.length
      visualize_session(sessions[index])
    else
      puts "Invalid selection"
      exit 1
    end
  end
else
  # If session ID is provided as argument
  visualize_session(ARGV[0])
end
```

Make it executable:

```bash
chmod +x scripts/visualize_events.rb
```

## Best Practices

1. **Regular Snapshots**: Take timeline snapshots before and after making significant code changes
2. **Focus on Specific Events**: Use the filtering system to focus on relevant event types
3. **Compare Sessions**: Generate timelines for both working and buggy sessions to identify differences
4. **Bookmark Important Views**: Save browser bookmarks with specific search filters for recurring issues

## Troubleshooting

If you encounter issues:

1. **Empty Timeline**: Ensure the event store contains events for the selected session
2. **Missing Events**: Check that systems are correctly publishing all relevant events
3. **Browser Compatibility**: The visualization works best in Chrome, Firefox, or Edge
4. **Large Event Logs**: For very large logs, consider filtering events before visualization

## Extending the Visualization

The visualization system can be extended by modifying `lib/vanilla/events/event_visualization.rb`. Possible enhancements include:

- Adding time range selection
- Creating event relationship graphs
- Exporting event data in different formats
- Comparing multiple sessions side-by-side