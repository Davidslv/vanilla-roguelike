#!/usr/bin/env ruby
# bin/visualize_test.rb
#
# A script to visually test the Vanilla roguelike game rendering
# This provides a simple way to verify that the rendering system is working
# by showing the game on screen and demonstrating player movement

require 'optparse'
require_relative '../lib/vanilla'
require_relative '../lib/vanilla/simulation/game_simulator'

# Set a seed for consistent testing
DEFAULT_SEED = 676418890322387

# Parse command line options
options = {
  seed: DEFAULT_SEED,
  delay: 1.0,  # Delay between movements in seconds
  movements: 10 # Number of movements to perform
}

OptionParser.new do |opts|
  opts.banner = "Usage: visualize_test.rb [options]"

  opts.on("-s", "--seed SEED", Integer, "Random seed for deterministic testing") do |seed|
    options[:seed] = seed
  end

  opts.on("-d", "--delay SECONDS", Float, "Delay between movements in seconds (default: 1.0)") do |delay|
    options[:delay] = delay
  end

  opts.on("-m", "--movements COUNT", Integer, "Number of movements to perform (default: 10)") do |count|
    options[:movements] = count
  end

  opts.on("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

puts "Starting visual test with seed: #{options[:seed]}"
puts "Press Ctrl+C to exit at any time"
sleep 1

# Create a game simulator that doesn't capture output
simulator = Vanilla::Simulation::GameSimulator.new(
  seed: options[:seed],
  capture_output: false
)

# Set up the game (this initializes the level and rendering)
game = simulator.setup_game

# Force proper screen clearing at the beginning
system("clear")
puts "Initial Game State:"
puts "================="

# Get and display the initial screen
simulator.capture_screen

# Get initial player position
initial_position = simulator.player_position
puts "Initial player position: [#{initial_position[0]}, #{initial_position[1]}]"
puts "Movement delay: #{options[:delay]} seconds"
puts "Press Ctrl+C to exit at any time"
sleep options[:delay]

# Movement sequence - one in each direction
directions = [:up, :right, :down, :left]
movement_count = 0

begin
  while movement_count < options[:movements]
    # Pick next direction
    direction = directions[movement_count % directions.length]

    # Clear screen for better visibility
    system("clear")
    puts "Movement #{movement_count + 1}/#{options[:movements]}: #{direction.to_s.upcase}"

    # Perform the movement with rendering verification
    results = simulator.simulate_movement_with_render_check(direction)

    # Display movement success
    current_pos = simulator.player_position
    moved = results.first[:moved]
    puts "Moved #{direction}: #{moved ? 'SUCCESS' : 'FAILED'}"
    puts "Current position: [#{current_pos[0]}, #{current_pos[1]}]"

    movement_count += 1
    sleep options[:delay]
  end

  # Final clear and display
  system("clear")
  puts "Visual test completed successfully!"
  puts "Final player position: [#{simulator.player_position[0]}, #{simulator.player_position[1]}]"
  puts "Press Enter to exit..."
  simulator.capture_screen

  # Wait for user to press Enter
  gets

rescue Interrupt
  # Handle Ctrl+C gracefully
  puts "\nTest interrupted by user"
end

exit 0