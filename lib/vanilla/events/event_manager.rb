module Vanilla
  module Events
    # Central event management class that handles event publication and subscription
    class EventManager
      # Initialize a new event manager
      # @param logger [Logger] Logger instance for event logging
      # @param store_config [Hash] Configuration for event storage
      #   file: [Boolean] Whether to use file-based storage (default: true)
      #   file_directory: [String] Directory for event files (default: "event_logs")
      def initialize(logger, store_config = { file: true })
        @subscribers = Hash.new { |h, k| h[k] = [] }
        @logger = logger

        # Set up file storage if configured
        if store_config[:file]
          require_relative 'storage/file_event_store'
          directory = store_config[:file_directory] || "event_logs"
          @event_store = Storage::FileEventStore.new(directory)
          @logger.info("Event system initialized with file storage in #{directory}")
        else
          @logger.info("Event system initialized without persistent storage")
        end
      end

      # Subscribe to events of a specific type
      # @param event_type [String] The event type to subscribe to
      # @param subscriber [Object] The subscriber that will handle the events
      # @return [void]
      def subscribe(event_type, subscriber)
        @subscribers[event_type] << subscriber
        @logger.debug("Subscribed #{subscriber.class} to #{event_type}")
      end

      # Unsubscribe from events of a specific type
      # @param event_type [String] The event type to unsubscribe from
      # @param subscriber [Object] The subscriber to remove
      # @return [void]
      def unsubscribe(event_type, subscriber)
        @subscribers[event_type].delete(subscriber)
        @logger.debug("Unsubscribed #{subscriber.class} from #{event_type}")
      end

      # Publish an event to all subscribers
      # @param event [Vanilla::Events::Event] The event to publish
      # @return [void]
      def publish(event)
        @logger.debug("Publishing event: #{event}")

        # Store the event if storage is configured
        @event_store&.store(event)

        # Deliver to subscribers
        @subscribers[event.type].each do |subscriber|
          begin
            subscriber.handle_event(event)
          rescue => e
            @logger.error("Error in subscriber #{subscriber.class} handling #{event.type}: #{e.message}")
            @logger.error(e.backtrace.join("\n"))
          end
        end
      end

      # Create and publish an event in one step
      # @param type [String] The event type
      # @param source [Object] The source of the event
      # @param data [Hash] Additional event data
      # @return [Event] The published event
      def publish_event(type, source = nil, data = {})
        event = Event.new(type, source, data)
        publish(event)
        event
      end

      # Query for events based on options
      # @param options [Hash] Query options
      # @return [Array<Vanilla::Events::Event>] Matching events
      def query_events(options = {})
        @event_store&.query(options) || []
      end

      # Get the current session ID
      # @return [String, nil] The current session ID, or nil if no event store
      def current_session
        @event_store&.current_session
      end

      # Close the event store
      # @return [void]
      def close
        @event_store&.close
      end
    end
  end
end