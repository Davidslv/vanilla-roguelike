# frozen_string_literal: true
module Vanilla
  module Events
    # Interface for components that respond to events
    # Classes including this module must implement the handle_event method
    module EventSubscriber
      # Handle an event that this subscriber is interested in
      # @param event [Vanilla::Events::Event] The event to handle
      # @return [void]
      def handle_event(event)
        raise NotImplementedError, "#{self.class} must implement handle_event(event)"
      end
    end
  end
end
