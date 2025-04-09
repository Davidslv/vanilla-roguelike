# lib/logger.rb
require 'fileutils'

class Logger
  class << self
    def initialize
      # Create logs directory if it doesn't exist
      FileUtils.mkdir_p("logs")

      # Create a new log file with timestamp
      timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
      @log_file = File.open("logs/game_#{timestamp}.log", "w")
      @log_file.sync = true # Ensure immediate writes

      info("Logging started")
    end

    def debug(message)
      log("DEBUG", message)
    end

    def info(message)
      log("INFO", message)
    end

    def error(message)
      log("ERROR", message)
    end

    private

    def log(level, message)
      timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S.%L")
      log_entry = "[#{timestamp}] [#{level}] #{message}\n"

      # Write to file
      @log_file ||= File.open("logs/game_#{Time.now.strftime('%Y%m%d_%H%M%S')}.log", "w")
      @log_file.write(log_entry)

      # Also print to console for immediate feedback
      print log_entry
    end
  end
end

# Initialize the logger when the file is required
Logger.initialize
