require 'fileutils'
require 'singleton'
require_relative 'fiber_event_bus'
require 'fiber'
require 'thread'

module Vanilla
  module FiberConcurrency
    # A fiber-based logger that doesn't block the main thread
    # This logger uses a Fiber to write to files asynchronously
    class FiberLogger
      include Singleton

      # Available log levels with their priority
      LOG_LEVELS = {
        debug: 0,
        info: 1,
        warn: 2,
        error: 3,
        fatal: 4
      }.freeze

      # Create a new fiber logger
      # @param scheduler [FiberScheduler] The scheduler to use (defaults to FiberScheduler.instance)
      # @param log_level [Symbol] Minimum level to log (default: :info)
      # @param log_dir [String] Directory to store logs (default: logs/env)
      # @return [FiberLogger] A new logger instance
      def initialize(scheduler = FiberScheduler.instance)
        @scheduler = scheduler
        @level = :info
        @log_env = ENV["RACK_ENV"] || "development"
        @log_dir = File.join(Dir.pwd, "logs", @log_env)

        FileUtils.mkdir_p(@log_dir) unless Dir.exist?(@log_dir)

        # Generate a unique log file name with timestamp
        timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
        @log_file = File.join(@log_dir, "vanilla_#{timestamp}.log")

        # Initialize message queue and mutex
        @message_queue = []
        @queue_mutex = Mutex.new
        @running = true

        # Initialize the log file
        begin
          @file = File.open(@log_file, "a")
          @file.puts "=== Vanilla Game Log Started at #{Time.now} ==="
          @file.puts "=== Environment: #{@log_env} ==="
          @file.flush
        rescue => e
          # If we can't open the log file, we'll log to standard error
          STDERR.puts "Error opening log file: #{e.message}"
          @file = nil
        end

        # Setup batch processing
        @max_batch_size = 10
        @flush_interval = 0.5
        @last_flush_time = Time.now

        # Register a fiber for processing log messages
        setup_logging_fiber if @scheduler
      end

      # Change the log level
      # @param level [Symbol] New log level
      # @return [Symbol] The new log level
      def level=(level)
        level = level.to_sym if level.is_a?(String)

        if LOG_LEVELS.key?(level)
          @level = level
        end
      end

      # Get the current log level
      # @return [Symbol] Current log level
      def level
        @level
      end

      # Log a debug message
      # @param message [String] Message to log
      # @return [void]
      def debug(message)
        enqueue_message(:debug, message, Time.now)
      end

      # Log an info message
      # @param message [String] Message to log
      # @return [void]
      def info(message)
        enqueue_message(:info, message, Time.now)
      end

      # Log a warning message
      # @param message [String] Message to log
      # @return [void]
      def warn(message)
        enqueue_message(:warn, message, Time.now)
      end

      # Log an error message
      # @param message [String] Message to log
      # @return [void]
      def error(message)
        enqueue_message(:error, message, Time.now, true)
      end

      # Log a fatal message
      # @param message [String] Message to log
      # @return [void]
      def fatal(message)
        enqueue_message(:fatal, message, Time.now, true)
      end

      # Close the log file
      # @return [void]
      def close
        return unless @running

        # Process any remaining messages
        process_message_queue(true) if @file

        @running = false

        # Close the file if open
        if @file
          # Write ending header
          @file.write("===== Log Closed at #{Time.now} =====\n")
          @file.flush
          @file.close
          @file = nil
        end
      end

      # Handle an event from the event bus
      # @param event [Object] the event to handle
      # @return [void]
      def handle_event(event)
        # Extract type - handle both hash-style and object-style events
        event_type = if event.is_a?(Hash)
                      event[:type]
                    elsif event.respond_to?(:type)
                      event.type
                    end

        # Return unless this is a log event
        return unless event_type && (event_type.to_s == "log" || event_type.to_sym == :log)

        # Extract level - handle both hash-style and object-style events
        level = if event.is_a?(Hash)
                  event[:level]
                elsif event.respond_to?(:level)
                  event.level
                end || :info # Default to info if level is nil

        # Extract message - handle both hash-style and object-style events
        message = nil
        if event.is_a?(Hash)
          message = event[:message] || (event[:data] && event[:data].to_s) || event.inspect
        else
          message = if event.respond_to?(:message) && event.message
                      event.message
                    elsif event.respond_to?(:data) && event.data
                      event.data.to_s
                    else
                      event.inspect
                    end
        end

        # Log the message
        enqueue_message(level.to_sym, message, Time.now)
      end

      # Flush log messages to disk
      # @return [void]
      def flush
        return unless @file && @running
        process_message_queue(true)
      end

      # Check if the log file is open
      # @return [Boolean] true if the file is open
      def open?
        !@file.nil? && !@file.closed?
      end

      private

      # Add a message to the queue for processing
      # @param level [Symbol] Log level
      # @param message [String] Message to log
      # @param timestamp [Time] Timestamp (default: current time)
      # @param immediate_flush [Boolean] Whether to flush immediately
      # @return [void]
      def enqueue_message(level, message, timestamp = Time.now, immediate_flush = false)
        # Skip if below minimum log level
        level_value = LOG_LEVELS[level.to_sym] || 0
        min_level_value = LOG_LEVELS[@level] || 0
        return if level_value < min_level_value

        log_entry = {
          level: level,
          message: message,
          timestamp: timestamp
        }

        # Set immediate flush for error and fatal messages
        log_entry[:immediate_flush] = true if [:error, :fatal].include?(level)

        @queue_mutex.synchronize do
          @message_queue << log_entry
        end

        # Process immediately for high-priority messages
        process_message_queue(immediate_flush) if immediate_flush || [:error, :fatal].include?(level)
      end

      # Process messages in the queue
      # @param force_flush [Boolean] whether to force flushing the file
      # @return [Integer] number of messages processed
      def process_message_queue(force_flush = false)
        return 0 unless @file && @running

        processed_count = 0
        needs_flush = force_flush

        messages_to_process = []

        @queue_mutex.synchronize do
          # Process up to max_batch_size messages
          batch_size = [@message_queue.size, @max_batch_size].min
          return 0 if batch_size == 0

          # Take exactly batch_size messages from the queue
          messages_to_process = @message_queue.slice!(0, batch_size)
        end

        # Process each message
        messages_to_process.each do |message|
          write_log(message[:level], message[:message], message[:timestamp])

          # Determine if we need to flush based on message properties
          needs_flush ||= message[:immediate_flush] if message.key?(:immediate_flush)
          processed_count += 1
        end

        # Check if we need to flush due to time interval
        time_since_flush = Time.now - @last_flush_time
        needs_flush ||= (time_since_flush >= @flush_interval)

        # Flush the file if needed
        if processed_count > 0 && needs_flush && @file
          @file.flush
          @last_flush_time = Time.now
        end

        processed_count
      end

      # Write a log message to the file
      # @param level [Symbol] log level
      # @param message [String] log message
      # @param timestamp [Time] timestamp
      # @return [void]
      def write_log(level, message, timestamp)
        return unless @file

        formatted_time = timestamp.strftime("%Y-%m-%d %H:%M:%S")
        formatted_level = level.to_s.upcase
        @file.write("[#{formatted_time} #{formatted_level}] #{message}\n")
      end

      # Setup a fiber for processing log messages
      # @return [void]
      def setup_logging_fiber
        fiber = Fiber.new do
          while @running
            process_message_queue
            Fiber.yield
          end
        end

        @scheduler.register(fiber, "fiber_logger")
      end
    end
  end
end

# Ensure compatibility with existing code
module Vanilla
  # Create a fiber-enabled logger when this file is required
  FiberLogger = FiberConcurrency::FiberLogger
end