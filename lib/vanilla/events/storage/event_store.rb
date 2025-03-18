module Vanilla
  module Events
    module Storage
      # Interface for event storage implementations
      # All concrete event store classes should implement these methods
      class EventStore
        # Store an event
        # @param event [Vanilla::Events::Event] The event to store
        # @return [void]
        def store(event)
          raise NotImplementedError, "#{self.class} must implement store(event)"
        end

        # Query for events based on options
        # @param options [Hash] Query options (type, time range, limit, etc.)
        # @return [Array<Vanilla::Events::Event>] Matching events
        def query(options = {})
          raise NotImplementedError, "#{self.class} must implement query(options)"
        end

        # Load all events from a session
        # @param session_id [String, nil] Session ID to load, or current session if nil
        # @return [Array<Vanilla::Events::Event>] Events from the session
        def load_session(session_id = nil)
          raise NotImplementedError, "#{self.class} must implement load_session(session_id)"
        end

        # List available sessions
        # @return [Array<String>] List of session IDs
        def list_sessions
          raise NotImplementedError, "#{self.class} must implement list_sessions"
        end

        # Close the event store and release resources
        # @return [void]
        def close
          # Optional method, default implementation does nothing
        end
      end
    end
  end
end