#!/usr/bin/env ruby

# Add lib directory to load path
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'vanilla'
require 'vanilla/game'

# Parse command line arguments
options = {}
ARGV.each do |arg|
  if arg.start_with?('--seed=')
    options[:seed] = arg.split('=')[1].to_i
  elsif arg.start_with?('--difficulty=')
    options[:difficulty] = arg.split('=')[1].to_i
  end
end

# Set default seed if not provided
options[:seed] ||= rand(1_000_000_000_000_000)
options[:difficulty] ||= 1

# Configure logging level
if ENV['VANILLA_DEBUG'] == 'true'
  Vanilla::Logger.instance.level = :debug
  puts "Debug logging enabled - seed: #{options[:seed]}, difficulty: #{options[:difficulty]}"
else
  Vanilla::Logger.instance.level = :info
end

# Create and start the game with ECS architecture
begin
  game = Vanilla::Game.new(options)
  game.start
rescue => e
  puts "Error starting game: #{e.message}"
  puts e.backtrace
end