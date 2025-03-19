require 'fileutils'
require 'singleton'

module Vanilla
  # Logger provides a backward-compatible interface to the new fiber-based logger
  # This class delegates all logging operations to FiberLogger for better performance
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
      # Set the log level to match the ENV setting
      @level = ENV['VANILLA_LOG_LEVEL']&.downcase&.to_sym || :info

      # Wait for initialization until first use of a logging method
      # This avoids circular dependency with FiberConcurrency module
      @initialized = false
    end

    # Lazy initialization of the fiber logger
    def fiber_logger
      unless @initialized
        require_relative 'fiber_concurrency'
        # Initialize the fiber concurrency system if not already initialized
        if defined?(Vanilla::FiberConcurrency) &&
           Vanilla::FiberConcurrency.respond_to?(:initialize) &&
           !Vanilla::FiberConcurrency.instance_variable_get(:@initialized)
          Vanilla::FiberConcurrency.initialize
        end

        # Get a reference to the fiber logger
        if defined?(Vanilla::FiberConcurrency) && Vanilla::FiberConcurrency.respond_to?(:logger)
          @fiber_logger = Vanilla::FiberConcurrency.logger
          @fiber_logger.level = @level if @fiber_logger.respond_to?(:level=)
        else
          # Fallback to direct logging if FiberConcurrency is not available
          setup_fallback_logger
        end

        @initialized = true
      end

      @fiber_logger
    end

    def debug(message)
      fiber_logger.debug(message)
    end

    def info(message)
      fiber_logger.info(message)
    end

    def warn(message)
      fiber_logger.warn(message)
    end

    def error(message)
      fiber_logger.error(message)
    end

    def fatal(message)
      fiber_logger.fatal(message)
    end

    def close
      fiber_logger.close if fiber_logger.respond_to?(:close)
    end

    private

    def setup_fallback_logger
      # Create a simple logger that writes directly to a file
      @log_env = ENV['VANILLA_LOG_ENV'] || 'development'
      @log_dir = File.join(Dir.pwd, 'logs', @log_env)
      FileUtils.mkdir_p(@log_dir) unless Dir.exist?(@log_dir)

      @log_file = File.join(@log_dir, "vanilla_#{Time.now.strftime('%Y%m%d_%H%M%S')}.log")
      @file = File.open(@log_file, 'w')

      # Write header
      @file.puts "=== Vanilla Game Log Started at #{Time.now} ==="
      @file.flush

      # Create a simple logger object to use as fallback
      @fiber_logger = Object.new

      # Define logging methods
      [:debug, :info, :warn, :error, :fatal].each do |level|
        @fiber_logger.define_singleton_method(level) do |message|
          Logger.instance.send(:log, level, message)
        end
      end

      # Define close method
      @fiber_logger.define_singleton_method(:close) do
        return unless Logger.instance.instance_variable_get(:@file)
        Logger.instance.instance_variable_get(:@file).puts "=== Vanilla Game Log Ended at #{Time.now} ==="
        Logger.instance.instance_variable_get(:@file).close
        Logger.instance.instance_variable_set(:@file, nil)
      end
    end

    def log(level, message)
      return if LOG_LEVELS[level] < LOG_LEVELS[@level]

      timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S.%L')
      formatted_message = "[#{timestamp}] [#{level.to_s.upcase}] #{message}"

      @file.puts(formatted_message)
      @file.flush
    end
  end
end

# Ensure logs are closed properly when the program exits
at_exit { Vanilla::Logger.instance.close }