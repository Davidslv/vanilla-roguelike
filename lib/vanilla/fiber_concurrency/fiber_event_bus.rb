require 'fiber'
require 'thread'
require 'singleton'

module Vanilla
  module FiberConcurrency
    # Central event management class that uses fibers for cooperative concurrency
    # This allows non-critical event handling to be deferred without blocking the main game loop
    class FiberEventBus
      include Singleton

      # Processing modes for event subscribers
      PROCESSING_MODES = [:immediate, :deferred, :scheduled].freeze

      # Initialize the event bus
      # @param scheduler [FiberScheduler] the fiber scheduler
      # @param logger [FiberLogger] the logger
      def initialize
        @scheduler = FiberScheduler.instance
        @logger = FiberLogger.instance

        @logger&.info("FiberEventBus initialized")

        # Initialize instance variables
        @subscribers = Hash.new { |h, k| h[k] = [] }
        @processing_modes = {}
        @batch_intervals = Hash.new(0.5)
        @last_batch = {}
        @event_queues = Hash.new { |h, k| h[k] = [] }
        @fibers = {}
        @mutex = Mutex.new
        @running = true
      end

      # Subscribe to events of a specific type
      # @param subscriber [Object] the object that will handle the events
      # @param event_type [Symbol, String, Array] the type of event to subscribe to
      # @param processing_mode [Symbol] how events should be processed (:immediate, :deferred, :scheduled)
      # @param batch_interval [Numeric] interval in seconds for scheduled processing
      # @return [Object] the subscriber object
      def subscribe(subscriber, event_type, processing_mode = :immediate, batch_interval = nil)
        # Validate the subscriber implements handle_event
        unless subscriber.respond_to?(:handle_event)
          raise ArgumentError, "Subscriber must implement handle_event method"
        end

        # Validate the processing mode
        unless PROCESSING_MODES.include?(processing_mode)
          raise ArgumentError, "Invalid processing mode: #{processing_mode}"
        end

        # Convert event types to symbols
        event_types = Array(event_type).map { |type| type.is_a?(String) ? type.to_sym : type }

        @mutex.synchronize do
          event_types.each do |type|
            # Initialize hash entries if they don't exist
            @processing_modes[type] ||= {}
            @last_batch[type] ||= {}

            # Add the subscriber if not already subscribed
            @subscribers[type] << subscriber unless @subscribers[type].include?(subscriber)

            # Set the processing mode for this subscriber
            @processing_modes[type][subscriber] = processing_mode

            # Set up fiber processing for non-immediate modes
            if processing_mode != :immediate
              @last_batch[type][subscriber] = Time.now

              # Set up fiber processing
              setup_fiber_processing(type, batch_interval || 0.5)
            end

            @logger&.info("Subscribed #{subscriber.class} to #{type} with mode #{processing_mode}")
          end
        end

        subscriber
      end

      # Unsubscribe from events of a specific type
      # @param subscriber [Object] the subscriber to unsubscribe
      # @param event_type [Symbol, String, Array] the event type(s) to unsubscribe from
      # @return [Boolean] true if the subscriber was unsubscribed
      def unsubscribe(subscriber, event_type = nil)
        event_types = if event_type.nil?
                        @subscribers.keys
                      elsif event_type.is_a?(Array)
                        event_type.map { |t| t.is_a?(String) ? t.to_sym : t.to_sym }
                      else
                        [event_type.is_a?(String) ? event_type.to_sym : event_type.to_sym]
                      end

        @mutex.synchronize do
          event_types.each do |type|
            next unless @subscribers[type]&.include?(subscriber)

            @subscribers[type].delete(subscriber)
            @processing_modes[type]&.delete(subscriber)
            @last_batch[type]&.delete(subscriber)

            @logger&.info("Unsubscribed #{subscriber} from #{type}")
          end
        end

        true
      end

      # Publish an event to all subscribers
      # @param event [Object] the event to publish
      # @return [Integer] number of subscribers that received the event
      def publish(event)
        return 0 if event.nil?

        # Validate event type
        unless event.respond_to?(:type)
          raise ArgumentError, "Event must respond to type method"
        end

        event_type = event.type.is_a?(String) ? event.type.to_sym : event.type.to_sym
        delivery_count = 0

        @mutex.synchronize do
          # Skip if no subscribers for this event type
          return 0 unless @subscribers.key?(event_type) && !@subscribers[event_type].empty?

          @logger&.debug("Publishing event: #{event_type}")

          @subscribers[event_type].each do |subscriber|
            mode = @processing_modes.dig(event_type, subscriber) || :immediate

            # Use original event if available (for EventManager compatibility)
            event_to_deliver = event.respond_to?(:original_event) ? event.original_event : event

            case mode
            when :immediate
              # Deliver immediately
              subscriber.handle_event(event_to_deliver)
              delivery_count += 1
            when :deferred, :scheduled
              # Queue for later processing
              @event_queues[event_type] << { subscriber: subscriber, event: event_to_deliver }
              delivery_count += 1
            end
          end
        end

        delivery_count
      end

      # Process queued events for scheduled subscribers
      # @param current_time [Time] the current time, defaults to Time.now
      # @return [Integer] number of events processed
      def tick(current_time = Time.now)
        total_processed = 0

        @mutex.synchronize do
          # Process each event type
          @event_queues.each do |event_type, events|
            next if events.empty?

            processed_indices = []

            # Process each queued event
            events.each_with_index do |event_data, index|
              subscriber = event_data[:subscriber]
              event = event_data[:event]

              # Event is already the original event from the publish method,
              # so no need to check for original_event here

              mode = @processing_modes.dig(event_type, subscriber) || :immediate

              # Skip immediate mode events (shouldn't be in queue)
              next if mode == :immediate

              # For scheduled mode, check if it's time to process
              if mode == :scheduled
                batch_interval = @batch_intervals[event_type]
                last_batch_time = @last_batch.dig(event_type, subscriber) || 0

                # Skip if not enough time has passed
                # Use to_f to convert Time to float
                current_time_float = current_time.to_f
                next if current_time_float - last_batch_time < batch_interval

                # Update last batch time
                @last_batch[event_type] ||= {}
                @last_batch[event_type][subscriber] = current_time_float
              end

              # Process the event
              begin
                subscriber.handle_event(event)
                total_processed += 1
                processed_indices << index
              rescue => e
                @logger&.error("Error in subscriber #{subscriber}: #{e.message}")
              end
            end

            # Remove processed events (in reverse order to avoid index issues)
            processed_indices.reverse.each do |index|
              events.delete_at(index)
            end
          end
        end

        # Ensure the scheduler resumes all fibers
        @scheduler.resume_all if total_processed > 0

        @logger&.debug("Processed #{total_processed} queued events") if total_processed > 0

        total_processed
      end

      # Set the processing mode for a subscriber's events
      # @param event_type [Symbol, String] the event type to set mode for
      # @param subscriber [Object] the subscriber to set mode for
      # @param mode [Symbol] the processing mode (:immediate, :deferred, :scheduled)
      # @param batch_interval [Float] the interval in seconds between scheduled batches
      # @return [Symbol] the new processing mode
      def set_processing_mode(event_type, subscriber, mode, batch_interval = nil)
        event_type = event_type.to_sym if event_type.is_a?(String)

        # Validate mode
        unless [:immediate, :deferred, :scheduled].include?(mode)
          raise ArgumentError, "Invalid processing mode: #{mode}, must be one of :immediate, :deferred, :scheduled"
        end

        # Ensure the subscriber is already subscribed
        unless @subscribers[event_type]&.include?(subscriber)
          raise ArgumentError, "Subscriber is not subscribed to #{event_type}"
        end

        # Get the previous mode
        prev_mode = @processing_modes.dig(event_type, subscriber) || :immediate

        @mutex.synchronize do
          # Initialize data structures if needed
          @processing_modes[event_type] ||= {}

          # Set the new mode
          @processing_modes[event_type][subscriber] = mode

          # Set batch interval if provided
          if batch_interval
            # Use the provided interval
            if @batch_intervals.is_a?(Hash) && !@batch_intervals.default.nil?
              # It's a default hash, update the value for this key
              @batch_intervals[event_type] = batch_interval
            else
              # Initialize as a regular hash if needed
              @batch_intervals ||= {}
              @batch_intervals[event_type] = batch_interval
            end
          end

          # Set up fiber processing for non-immediate modes
          # Only if changing from immediate to non-immediate
          if prev_mode == :immediate && mode != :immediate
            setup_fiber_processing(event_type, batch_interval || 0.5)
          end

          # Initialize last batch time for scheduled mode
          if mode == :scheduled
            @last_batch[event_type] ||= {}
            @last_batch[event_type][subscriber] = Time.now.to_f
          end
        end

        @logger&.info("Changed processing mode for #{event_type} to #{mode} for #{subscriber.class}")

        mode
      end

      # Shutdown the event bus and process any remaining events
      # @return [Boolean] true if the shutdown was successful
      def shutdown
        @logger&.info("FiberEventBus shutting down")
        @running = false

        # Process any remaining events
        @mutex.synchronize do
          # For each event type with queued events
          @event_queues.each do |event_type, events|
            next if events.empty?

            # Process each event
            events.each do |event_data|
              subscriber = event_data[:subscriber]
              event = event_data[:event]

              # Event is already the original event from the publish method

              begin
                subscriber.handle_event(event)
              rescue => e
                @logger&.error("Error processing event during shutdown: #{e.message}")
              end
            end

            # Clear the queue
            events.clear
          end
        end

        true
      end

      # Process all events for all event types
      # @return [Integer] number of events processed
      def process_all_events
        processed_count = 0

        @subscribers.keys.each do |type|
          processed_count += process_events_for_type(type)
        end

        processed_count
      end

      # Set up fiber processing for a specific event type and interval
      # @param event_type [Symbol] the event type
      # @param interval [Float] processing interval in seconds
      # @return [void]
      def setup_fiber_processing(event_type, interval = nil)
        return if @fibers[event_type]

        @fibers[event_type] = true
        @logger&.debug("Set up fiber processing for #{event_type} with interval #{interval || 'default'}")
      end

      private

      # Process events for a specific event type
      # @param event_type [Symbol] the event type to process
      # @return [Integer] number of events processed
      def process_events_for_type(event_type)
        processed_count = 0

        return 0 unless @subscribers[event_type]

        # Process deferred events
        @subscribers[event_type].each do |subscriber|
          mode = @processing_modes[event_type][subscriber]
          next if mode == :immediate

          case mode
          when :deferred
            # Process all queued events for this subscriber
            queue = @event_queues[event_type][subscriber] || []
            next if queue.empty?

            begin
              queue.each do |event|
                subscriber.handle_event(event)
                processed_count += 1
              end
              @event_queues[event_type][subscriber] = []
            rescue => e
              @logger&.error("Error processing events for #{subscriber}: #{e.message}")
            end

          when :scheduled
            # Process scheduled events if interval has elapsed
            interval = @batch_intervals[event_type][subscriber] || 1.0
            last_time = @last_batch[event_type][subscriber] || Time.now
            now = Time.now

            if now - last_time >= interval
              queue = @event_queues[event_type][subscriber] || []
              next if queue.empty?

              begin
                queue.each do |event|
                  subscriber.handle_event(event)
                  processed_count += 1
                end
                @event_queues[event_type][subscriber] = []
              rescue => e
                @logger&.error("Error processing events for #{subscriber}: #{e.message}")
              end

              @last_batch[event_type][subscriber] = now
            end
          end
        end

        processed_count
      end
    end
  end
end