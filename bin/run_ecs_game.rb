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

# Create and start the game with ECS architecture
game = Vanilla::Game.new(options)
game.start