#!/usr/bin/env ruby
# frozen_string_literal: true

# Launch the browser-playable version of Vanilla Roguelike.
#
#   ./bin/play_web.rb                       # default: port 4567, random seed
#   ./bin/play_web.rb --port=8080
#   ./bin/play_web.rb --seed=12345 --difficulty=2
#
# Then open http://127.0.0.1:4567 in a browser and play with hjkl / arrows.
#
# This reuses 100% of the game logic (ECS world, systems, combat, FOV). Only
# the input and render seams are swapped for the web. The terminal game
# (./bin/play.rb) is unaffected.

require 'optparse'
require_relative '../web/server'

options = { port: 4567, host: '127.0.0.1' }
OptionParser.new do |opts|
  opts.banner = 'Usage: bin/play_web.rb [options]'
  opts.on('--port=PORT', Integer, 'Port to listen on (default 4567)') { |v| options[:port] = v }
  opts.on('--host=HOST', 'Bind address (default 127.0.0.1)') { |v| options[:host] = v }
  opts.on('-h', '--help', 'Show help') do
    puts opts
    exit
  end
end.parse!

Vanilla::Web::Server.new(port: options[:port], host: options[:host]).start
