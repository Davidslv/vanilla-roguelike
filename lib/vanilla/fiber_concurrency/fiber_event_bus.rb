require 'singleton'
require 'fiber'
require_relative 'fiber_scheduler'

module Vanilla
  module FiberConcurrency
    # Central event management class that uses fibers for cooperative concurrency
    # This allows non-critical event handling to be deferred without blocking the main game loop
    class FiberEventBus
      include Singleton

      # Processing modes for event subscribers
      PROCESSING_MODES = [:immediate, :deferred, :scheduled].freeze

      # Initialize a new fiber event bus
      # @param logger [Logger] Optional logger for debugging
      def initialize(logger = nil)
        @subscribers = Hash.new { |h, k| h[k] = [] }
        @processing_modes = {}
        @event_queues = Hash.new { |h, k| h[k] = [] }
        @fibers = {}
        @batch_intervals = Hash.new(0.5)
        @last_batch_time = {}
        @logger = logger
        @running = true

        # Log initialization but don't force logger initialization during startup
        logger&.info("FiberEventBus initialized")
      end

      # Get the logger, lazy-loaded if not provided in constructor
      def logger
        @logger ||= begin
          # Get the logger, but check for circular dependency
          if Vanilla.const_defined?(:FiberConcurrency) &&
             Vanilla::FiberConcurrency.const_defined?(:FiberLogger) &&
             !Vanilla::FiberConcurrency::FiberLogger.instance.equal?(self)
            Vanilla::FiberConcurrency::FiberLogger.instance
          else
            # Fallback to a simple logger if there's a circular dependency
            logger = Object.new
            def logger.method_missing(method, *args)
              puts "[FiberEventBus] #{method}: #{args.join(' ')}" if [:debug, :info, :warn, :error, :fatal].include?(method)
            end
            logger
          end
        end
      end

      # Get the scheduler, lazy-loaded to avoid circular dependency
      def scheduler
        @scheduler ||= begin
          # Get the scheduler, but check for circular dependency
          if Vanilla.const_defined?(:FiberConcurrency) &&
             Vanilla::FiberConcurrency.const_defined?(:FiberScheduler) &&
             !Vanilla::FiberConcurrency::FiberScheduler.instance.equal?(self)
            Vanilla::FiberConcurrency::FiberScheduler.instance
          else
            nil # Will be initialized later once dependency cycle is broken
          end
        end
      end

      # Subscribe to events of a specific type
      # @param subscriber [Object] The object to subscribe to events
      # @param event_type [String, Symbol, Array<String, Symbol>] The event type(s) to subscribe to
      # @param mode [Symbol] The processing mode, one of: :immediate, :deferred, :scheduled
      # @param batch_interval [Float] For scheduled mode, how often to process events (in seconds)
      # @return [void]
      def subscribe(subscriber, event_type, mode = :immediate, batch_interval = 0.5)
        unless subscriber.respond_to?(:handle_event)
          raise ArgumentError, "Subscriber must implement handle_event method"
        end

        unless PROCESSING_MODES.include?(mode)
          raise ArgumentError, "Invalid processing mode, must be one of: #{PROCESSING_MODES.join(', ')}"
        end

        # Convert to array if it's not already
        event_types = event_type.is_a?(Array) ? event_type : [event_type]

        event_types.each do |type|
          type = type.to_sym if type.is_a?(String)

          @subscribers[type] ||= []
          @subscribers[type] << subscriber

          # Use the set_processing_mode method
          set_processing_mode(type, subscriber, mode, batch_interval)

          logger.info("Subscribed #{subscriber.class} to #{type} with mode: #{mode}")
        end

        nil
      end

      # Unsubscribe from events of a specific type
      # @param subscriber [Object] The subscriber to unsubscribe
      # @param event_type [String, Symbol, Array<String, Symbol>] The event type(s) to unsubscribe from
      # @return [void]
      def unsubscribe(subscriber, event_type)
        # Convert to array if it's not already
        event_types = event_type.is_a?(Array) ? event_type : [event_type]

        event_types.each do |type|
          type = type.to_sym if type.is_a?(String)

          @subscribers[type].delete(subscriber)
          @processing_modes[type]&.delete(subscriber)

          logger.info("Unsubscribed #{subscriber.class} from #{type}")
        end

        nil
      end

      # Publish an event to all subscribers
      # @param event [Object] The event to publish, must respond to type method
      # @return [void]
      def publish(event)
        return if event.nil?

        begin
          type = event.type
        rescue NoMethodError
          raise ArgumentError, "Event must respond to type method"
        end

        type = type.to_sym if type.is_a?(String)
        return if type.nil?

        subscribers = @subscribers[type] || []
        return if subscribers.empty?

        logger.debug("Publishing event: #{type}")

        subscribers.each do |subscriber|
          processing_mode = @processing_modes[type][subscriber]

          case processing_mode
          when :immediate
            begin
              subscriber.handle_event(event)
            rescue => e
              logger.error("Error in subscriber #{subscriber.class} handling #{type}: #{e.message}")
              logger.error(e.backtrace.join("\n"))
            end
          when :deferred, :scheduled
            @event_queues[type] << event
          end
        end
      end

      # Process events - should be called periodically from the game loop
      # @return [void]
      def tick
        return unless @running

        # Process all event types with pending events
        @event_queues.each do |event_type, events|
          next if events.empty?

          processing_mode = @processing_modes[event_type]
          next if processing_mode.nil?

          if processing_mode == :scheduled
            # Only process if the batch interval has elapsed
            batch_interval = @batch_intervals[event_type]
            last_time = @last_batch_time[event_type] || Time.now - batch_interval
            next if Time.now - last_time < batch_interval
          end

          # Process all events for this type
          process_events(event_type)
        end

        # Process all pending fibers
        resumed = scheduler&.resume_all || 0

        # Process any events that need to be handled during this tick
        process_events

        resumed
      end

      # Set the processing mode for a specific event type
      # @param event_type [Symbol, String] The event type
      # @param subscriber [Object] The subscriber object
      # @param mode [Symbol] The new processing mode
      # @param batch_interval [Float] For scheduled mode, how often to process events (in seconds)
      # @return [void]
      def set_processing_mode(event_type, subscriber, mode, batch_interval = 0.5)
        event_type = event_type.to_sym if event_type.is_a?(String)

        unless PROCESSING_MODES.include?(mode)
          raise ArgumentError, "Invalid processing mode, must be one of: #{PROCESSING_MODES.join(', ')}"
        end

        @processing_modes[event_type] ||= {}
        old_mode = @processing_modes[event_type][subscriber]
        @processing_modes[event_type][subscriber] = mode

        # If we're switching from immediate to non-immediate, set up the fiber processing
        if old_mode == :immediate && mode != :immediate
          setup_fiber_processing(event_type, batch_interval)
        end

        logger.info("Changed processing mode for #{event_type} from #{old_mode || 'none'} to #{mode}")
      end

      # Shutdown the event bus
      # @return [void]
      def shutdown
        return unless @running

        logger.info("Event bus shutting down")
        @running = false

        # Process any remaining events before shutting down
        process_all_events

        # Clean up the scheduler
        scheduler&.shutdown

        # Clean up resources
        @fibers.clear
        @event_queues.clear

        true
      end

      # Process all events across all event types
      # @return [Integer] Number of events processed
      def process_all_events
        count = 0

        @event_queues.each_key do |event_type|
          next if @event_queues[event_type].empty?

          count += process_events(event_type)
        end

        count
      end

      # Process events for a specific type
      # @param event_type [Symbol] The event type to process
      # @return [Integer] Number of events processed
      def process_events(event_type = nil)
        # If called without arguments, delegate to process_all_events
        return process_all_events if event_type.nil?

        subscribers = @subscribers[event_type] || []
        return 0 if subscribers.empty?

        queue = @event_queues[event_type]
        return 0 if queue.empty?

        events_to_process = queue.clone
        queue.clear

        processed = 0
        events_to_process.each do |event|
          subscribers.each do |subscriber|
            begin
              subscriber.handle_event(event)
              processed += 1
            rescue => e
              logger.error("Error in subscriber #{subscriber.class} handling #{event_type}: #{e.message}")
              logger.error(e.backtrace.join("\n"))
            end
          end
        end

        # Ensure scheduler gets a chance to resume other fibers
        scheduler.resume_all if processed > 0

        processed
      end

      private

      # Set up fiber for processing events in non-immediate mode
      # @param event_type [Symbol] The event type to set up processing for
      # @param batch_interval [Float] For scheduled mode, how often to process events (in seconds)
      # @return [void]
      def setup_fiber_processing(event_type, batch_interval = 0.5)
        # Skip if we're shutting down or the fiber already exists and is alive
        return unless @running

        if @fibers[event_type].nil? || !@fibers[event_type].alive?
          @fibers[event_type] = Fiber.new do
            while @running
              # Process events for this type
              process_events(event_type)

              # Yield control back to the scheduler
              Fiber.yield
            end
          end

          # Register with scheduler
          scheduler&.register(@fibers[event_type], "event_fiber_#{event_type}")
          @batch_intervals[event_type] = batch_interval
          @last_batch_time[event_type] = Time.now
        end
      end
    end
  end
end