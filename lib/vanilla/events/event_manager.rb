require_relative '../fiber_concurrency'

module Vanilla
  module Events
    # Central event management class that handles event publication and subscription
    # This class now uses the FiberEventBus under the hood for improved performance
    class EventManager
      # Initialize a new event manager
      # @param logger [Logger] Logger instance for event logging
      # @param store_config [Hash] Configuration for event storage
      #   file: [Boolean] Whether to use file-based storage (default: true)
      #   file_directory: [String] Directory for event files (default: "event_logs")
      def initialize(logger, store_config = { file: true })
        @subscribers = Hash.new { |h, k| h[k] = [] }
        @logger = logger

        # Initialize the fiber concurrency system if not already done
        Vanilla::FiberConcurrency.initialize unless Vanilla::FiberConcurrency.instance_variable_get(:@initialized)

        # Get a reference to the FiberEventBus for delegation
        @event_bus = Vanilla::FiberConcurrency.event_bus

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

        # Also subscribe through the FiberEventBus for deferred processing
        # Use immediate mode by default - can be changed with set_processing_mode
        @event_bus.subscribe(subscriber, event_type.to_sym)

        @logger.debug("Subscribed #{subscriber.class} to #{event_type}")
      end

      # Unsubscribe from events of a specific type
      # @param event_type [String] The event type to unsubscribe from
      # @param subscriber [Object] The subscriber to remove
      # @return [void]
      def unsubscribe(event_type, subscriber)
        @subscribers[event_type].delete(subscriber)

        # Also unsubscribe from the FiberEventBus
        @event_bus.unsubscribe(subscriber, event_type.to_sym)

        @logger.debug("Unsubscribed #{subscriber.class} from #{event_type}")
      end

      # Set the processing mode for a subscriber
      # @param event_type [String] The event type
      # @param subscriber [Object] The subscriber
      # @param mode [Symbol] The processing mode (:immediate, :deferred, or :scheduled)
      # @param batch_interval [Float] For scheduled mode, the batch interval in seconds
      # @return [void]
      def set_processing_mode(event_type, subscriber, mode, batch_interval = nil)
        @event_bus.set_processing_mode(event_type.to_sym, subscriber, mode, batch_interval)
        @logger.debug("Set processing mode for #{subscriber.class} on #{event_type} to #{mode}")
      end

      # Publish an event to all subscribers
      # @param event [Vanilla::Events::Event] The event to publish
      # @return [void]
      def publish(event)
        @logger.debug("Publishing event: #{event}")

        # Store the event if storage is configured
        @event_store&.store(event)

        # Convert to FiberEventBus-compatible event if needed
        fiber_event = create_fiber_event(event)

        # Publish through FiberEventBus for improved performance
        @event_bus.publish(fiber_event)
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

      private

      # Create a FiberEventBus-compatible event from an Events::Event
      # @param event [Vanilla::Events::Event] The original event
      # @return [Object] A fiber-compatible event
      def create_fiber_event(event)
        # Create a simple event object that responds to type and has data
        fiber_event = Object.new

        # Define type method to return the event type as a symbol
        event_type = event.type.to_sym
        def fiber_event.type
          @type
        end
        fiber_event.instance_variable_set(:@type, event_type)

        # Define data method to return the event data
        event_data = {
          source: event.source,
          data: event.data,
          timestamp: event.timestamp
        }
        def fiber_event.data
          @data
        end
        fiber_event.instance_variable_set(:@data, event_data)

        # Define to_s method for debugging
        def fiber_event.to_s
          "FiberEvent(#{@type})"
        end

        # Store the original event for the subscribers
        def fiber_event.original_event
          @original_event
        end
        fiber_event.instance_variable_set(:@original_event, event)

        fiber_event
      end
    end
  end
end