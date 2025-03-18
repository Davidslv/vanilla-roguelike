#!/usr/bin/env ruby

require_relative '../lib/vanilla/events/storage/event_store'
require_relative '../lib/vanilla/events/storage/file_event_store'
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
