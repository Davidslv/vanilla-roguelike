# frozen_string_literal: true
# module Vanilla
#   class Logger
#     def self.instance
#       @instance ||= ::Logger.new(STDOUT).tap { |l| l.level = ::Logger::DEBUG }
#     end
#   end
# end

require 'fileutils'
require 'singleton'

module Vanilla
  class Logger
    include Singleton

    LOG_LEVELS = {
      debug: 0,
      info: 1,
      warn: 2,
      error: 3,
      fatal: 4
    }.freeze

    attr_accessor :level

    def initialize
      @level = ENV['VANILLA_LOG_LEVEL']&.downcase&.to_sym || :info
      @log_env = ENV['VANILLA_LOG_DIR'] || 'development'

      @log_dir = File.join(Dir.pwd, 'logs', @log_env)
      FileUtils.mkdir_p(@log_dir) unless Dir.exist?(@log_dir)

      @log_file = File.join(@log_dir, "vanilla_#{Time.now.strftime('%Y%m%d_%H%M%S')}.log")
      @file = File.open(@log_file, 'w')

      # Write header
      @file.puts "=== Vanilla Game Log Started at #{Time.now} ==="
      @file.flush
    end

    def debug(message)
      log(:debug, message)
    end

    def info(message)
      log(:info, message)
    end

    def warn(message)
      log(:warn, message)
    end

    def error(message)
      log(:error, message)
    end

    def fatal(message)
      log(:fatal, message)
    end

    def close
      return unless @file

      @file.puts "=== Vanilla Game Log Ended at #{Time.now} ==="
      @file.close
      @file = nil
    end

    private

    def log(level, message)
      timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S.%L')
      formatted_message = "[#{timestamp}] [#{level.to_s.upcase}] #{message}"

      @file.puts(formatted_message)
      @file.flush
    end
  end
end

# Ensure logs are closed properly when the program exits
at_exit { Vanilla::Logger.instance.close }
