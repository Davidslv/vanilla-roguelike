#!/usr/bin/env ruby

begin
  require './lib/vanilla'

  # Initialize logger
  logger = Vanilla::Logger.instance
  logger.info("Starting Vanilla game")

  # Run the game inside a rescue block to catch any errors
  begin
    Vanilla.run
  rescue => e
    logger.fatal("Game crashed: #{e.message}")
    logger.fatal(e.backtrace.join("\n"))
    puts "Game crashed. Check logs for details."
    exit(1)
  end
rescue LoadError => e
  puts "Failed to load the Vanilla game: #{e.message}"
  exit(1)
rescue => e
  puts "Unexpected error: #{e.message}"
  puts e.backtrace
  exit(1)
end
