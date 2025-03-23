#!/usr/bin/env ruby

# Add lib directory to load path
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'vanilla'
require 'vanilla/game'

# Parse command line arguments

require 'optparse'

# Parse command line arguments
options = {
  seed: Random.new_seed,
  difficulty: 1
}

OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename($0)} [options]"

  opts.on("--seed=SEED", Integer, "Set random seed") do |seed|
    options[:seed] = seed
  end

  # TODO: revisit difficulty system
  opts.on("--difficulty=LEVEL", Integer, "Set difficulty level (1-5)") do |level|
    if level.between?(1, 5)
      options[:difficulty] = level
    else
      puts "Difficulty must be between 1 and 5, defaulting to 1"
      options[:difficulty] = 1
    end
  end

  opts.on("-h", "--help", "Show this help message") do
    puts opts
    exit
  end
end.parse!

# Create and start the game with ECS architecture
game = Vanilla::Game.new(options)
game.start
