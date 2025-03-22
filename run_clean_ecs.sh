#!/bin/bash

# Reset terminal state
echo "Resetting terminal state..."
stty sane

# Make sure logs directory exists
mkdir -p logs/development

# Set up environment
export VANILLA_DEBUG=true

# Run the game with proper terminal mode
echo "Starting clean ECS game..."
ruby -e '
  begin
    # Configure terminal
    system("stty raw -echo")

    # Run the game
    puts "Loading ECS game..."
    load "bin/run_clean_ecs.rb"
  rescue => e
    # Print error information
    system("stty sane")
    puts "\n\nERROR: #{e.class}: #{e.message}"
    puts e.backtrace
  ensure
    # Always restore terminal
    system("stty sane")
    puts "\nGame session ended."
  end
'

# Reset terminal state after exit
stty sane

echo "Game exited. Terminal state restored."