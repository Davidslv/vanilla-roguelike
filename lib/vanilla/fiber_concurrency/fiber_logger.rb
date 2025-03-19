require 'fileutils'
require 'singleton'
require_relative 'fiber_event_bus'

module Vanilla
  module FiberConcurrency
    # Asynchronous logger implementation using Ruby fibers
    # This logger improves performance by writing log messages in a fiber
    # that doesn't block the main game loop
    class FiberLogger
      include Singleton

      # Define log levels and their corresponding priorities
      LOG_LEVELS = {
        debug: 0,
        info: 1,
        warn: 2,
        error: 3,
        fatal: 4
      }.freeze

      # Get the current log level
      # @return [Symbol] The current log level
      attr_reader :level

      # Initialize a new fiber logger
      # @param level [Symbol] The minimum log level (debug, info, warn, error, fatal)
      # @param log_dir [String] The directory to store log files
      def initialize(level = nil, log_dir = nil)
        @level = (level || ENV['VANILLA_LOG_LEVEL'] || :info).to_sym
        @message_queue = []
        @max_batch_size = 10
        @flush_interval = 0.5
        @last_flush_time = Time.now

        # Set up log file
        log_dir ||= ENV['VANILLA_LOG_DIR'] || File.join(Dir.pwd, 'logs')
        setup_log_file(log_dir)

        # Set up logging fiber if not in test mode
        setup_logging_fiber unless $TESTING
      end

      # Log a debug message
      # @param message [String] The message to log
      # @return [void]
      def debug(message)
        enqueue_message(:debug, message, Time.now)
      end

      # Log an info message
      # @param message [String] The message to log
      # @return [void]
      def info(message)
        enqueue_message(:info, message, Time.now)
      end

      # Log a warning message
      # @param message [String] The message to log
      # @return [void]
      def warn(message)
        enqueue_message(:warn, message, Time.now)
      end

      # Log an error message
      # @param message [String] The message to log
      # @return [void]
      def error(message)
        enqueue_message(:error, message, Time.now, true)
      end

      # Log a fatal message
      # @param message [String] The message to log
      # @return [void]
      def fatal(message)
        enqueue_message(:fatal, message, Time.now, true)
      end

      # Handle an event (for event bus integration)
      # @param event [Object, Hash] The event to log
      # @return [void]
      def handle_event(event)
        # Support both object style events and hash style events
        event_type = event.respond_to?(:type) ? event.type : event[:type]
        return unless event_type.to_s == 'log'

        # Extract data from either object or hash
        if event.respond_to?(:data)
          data = event.data
        else
          data = event
        end

        level = data[:level] || :info
        message = data[:message] || data.inspect
        enqueue_message(level.to_sym, message, Time.now)
      end

      # Close the log file and clean up resources
      # @return [void]
      def close
        return unless @file

        # Flush any remaining messages
        process_messages(true)

        # Write end marker
        @file.write("===== Log Closed at #{Time.now} =====\n")
        @file.close
        @file = nil
      end

      # Flush log messages to disk
      # @return [void]
      def flush
        process_messages(true) if @file
      end

      # Check if the log file is open
      # @return [Boolean] Whether the log file is open
      def open?
        !@file.nil?
      end

      private

      # Enqueue a message to be written to the log
      # @param level [Symbol] The log level
      # @param message [String] The message to log
      # @param timestamp [Time] The timestamp of the message
      # @param immediate_flush [Boolean] Whether to flush immediately
      # @return [void]
      def enqueue_message(level, message, timestamp, immediate_flush = false)
        # Skip if message is below current log level
        return if LOG_LEVELS[level] < LOG_LEVELS[@level]

        # Create message data
        message_data = {
          level: level,
          message: message,
          timestamp: timestamp
        }

        # Add immediate_flush flag only if it's true
        message_data[:immediate_flush] = true if immediate_flush

        # Add to queue
        @message_queue << message_data

        # Process immediately if needed
        process_messages(true) if immediate_flush && @file
      end

      # Process messages from the queue
      # @param force_flush [Boolean] Whether to force a flush
      # @return [void]
      def process_messages(force_flush = false)
        return unless @file

        # Calculate how many messages to process
        message_count = [@message_queue.size, @max_batch_size].min
        return if message_count == 0

        flush_needed = force_flush

        # Process batch of messages
        message_count.times do
          message = @message_queue.shift
          write_log(message[:level], message[:message], message[:timestamp])
          flush_needed ||= message[:immediate_flush]
        end

        # Flush if necessary
        if flush_needed || (Time.now - @last_flush_time >= @flush_interval)
          @file.flush
          @last_flush_time = Time.now
        end
      end

      # Write a message to the log file
      # @param level [Symbol] The log level
      # @param message [String] The message
      # @param timestamp [Time] The timestamp
      # @return [void]
      def write_log(level, message, timestamp)
        return unless @file

        formatted_time = timestamp.strftime('%Y-%m-%d %H:%M:%S')
        @file.write("[#{formatted_time} #{level.to_s.upcase}] #{message}\n")
      end

      # Set up the log file
      # @param log_dir [String] The directory to store logs
      # @return [void]
      def setup_log_file(log_dir)
        # Create log directory if it doesn't exist
        FileUtils.mkdir_p(log_dir) unless File.directory?(log_dir)

        # Create log file
        timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
        log_file = File.join(log_dir, "vanilla_#{timestamp}.log")
        @file = File.open(log_file, 'w')

        # Write header
        @file.write("===== Vanilla Log Started at #{Time.now} =====\n")
        @file.write("Log level: #{@level}\n")
        @file.flush
      end

      # Set up the fiber for asynchronous logging
      # @return [void]
      def setup_logging_fiber
        # Avoid circular dependency by lazily getting the scheduler
        # rather than directly calling instance method during initialization
        @logging_fiber = Fiber.new do
          # Only get the scheduler once the fiber is running
          scheduler = nil

          begin
            scheduler = Vanilla::FiberConcurrency::FiberScheduler.instance
            scheduler.register(@logging_fiber, "logging_fiber") if scheduler
          rescue
            # If we can't get the scheduler, we'll just run without it
            # This might happen during startup due to circular dependencies
            puts "[FiberLogger] Warning: Could not register with scheduler, will run in standalone mode"
          end

          while @file
            # Process messages
            process_messages

            # Yield control back to the scheduler
            Fiber.yield
          end
        end

        # Start the fiber but don't register it with the scheduler yet
        # to avoid circular dependency during initialization
        @logging_fiber.resume
      end
    end
  end
end

# Ensure compatibility with existing code
module Vanilla
  # Create a fiber-enabled logger when this file is required
  FiberLogger = FiberConcurrency::FiberLogger
end