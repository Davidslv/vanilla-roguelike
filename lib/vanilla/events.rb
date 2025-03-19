# Event system for Vanilla game
# This file requires all components of the event system

require_relative 'events/event'
require_relative 'events/types'
require_relative 'events/event_subscriber'
require_relative 'events/storage/event_store'
require_relative 'events/storage/file_event_store'
require_relative 'fiber_concurrency'

module Vanilla
  # The EventManager is responsible for managing all events in the game.
  # It provides methods for subscribing to events and publishing events.
  # This implements a facade pattern that delegates to the FiberEventBus
  # for better performance while maintaining backward compatibility.
  class EventManager
    class << self
      def subscribe(event_type, subscriber, &block)
        initialize_if_needed

        # If a block is provided, wrap it in a handler object
        actual_subscriber = block_given? ? create_block_handler(block) : subscriber

        # Subscribe to the FiberEventBus
        event_bus.subscribe(event_type, actual_subscriber)

        # Default to immediate processing mode
        event_bus.set_processing_mode(event_type, actual_subscriber, :immediate)
      end

      def subscribe_deferred(event_type, subscriber, &block)
        initialize_if_needed

        # If a block is provided, wrap it in a handler object
        actual_subscriber = block_given? ? create_block_handler(block) : subscriber

        # Subscribe to the FiberEventBus
        event_bus.subscribe(event_type, actual_subscriber)

        # Set deferred processing mode
        event_bus.set_processing_mode(event_type, actual_subscriber, :deferred)
      end

      def subscribe_scheduled(event_type, subscriber, interval = 1.0/60, &block)
        initialize_if_needed

        # If a block is provided, wrap it in a handler object
        actual_subscriber = block_given? ? create_block_handler(block) : subscriber

        # Subscribe to the FiberEventBus
        event_bus.subscribe(event_type, actual_subscriber)

        # Set scheduled processing mode with the specified interval
        event_bus.set_processing_mode(event_type, actual_subscriber, :scheduled, interval)
      end

      def unsubscribe(event_type, subscriber)
        return unless @initialized
        event_bus.unsubscribe(event_type, subscriber)
      end

      def publish(event)
        initialize_if_needed
        event_bus.publish(event)
      end

      def process_events
        return unless @initialized
        # This is a no-op now, as event processing happens in the FiberConcurrency.tick method
      end

      private

      def initialize_if_needed
        unless @initialized
          require_relative 'fiber_concurrency'

          # Initialize the FiberConcurrency system if not already done
          if defined?(Vanilla::FiberConcurrency) &&
             Vanilla::FiberConcurrency.respond_to?(:initialize) &&
             !Vanilla::FiberConcurrency.instance_variable_get(:@initialized)
            Vanilla::FiberConcurrency.initialize
          end

          @initialized = true
        end
      end

      def event_bus
        # Lazily get the event bus from FiberConcurrency
        return @event_bus if @event_bus

        if defined?(Vanilla::FiberConcurrency) && Vanilla::FiberConcurrency.respond_to?(:event_bus)
          @event_bus = Vanilla::FiberConcurrency.event_bus
        else
          # Fallback to a simple in-memory implementation if FiberConcurrency is not available
          @event_bus ||= create_fallback_event_bus
        end

        @event_bus
      end

      def create_block_handler(block)
        # Create a simple handler object that wraps the block
        handler = Object.new
        handler.define_singleton_method(:handle_event) do |event|
          block.call(event)
        end
        handler
      end

      def create_fallback_event_bus
        # Simple event bus implementation for fallback
        bus = Object.new
        subscribers = Hash.new { |h, k| h[k] = [] }

        # Define the subscribe method
        bus.define_singleton_method(:subscribe) do |event_type, subscriber|
          subscribers[event_type.to_sym] << subscriber
        end

        # Define the unsubscribe method
        bus.define_singleton_method(:unsubscribe) do |event_type, subscriber|
          subscribers[event_type.to_sym].delete(subscriber)
        end

        # Define the publish method
        bus.define_singleton_method(:publish) do |event|
          return if event.nil?
          event_type = event.respond_to?(:type) ? event.type.to_sym : nil
          return unless event_type && subscribers.key?(event_type)

          subscribers[event_type].each do |subscriber|
            if subscriber.respond_to?(:handle_event)
              subscriber.handle_event(event)
            end
          end
        end

        # Define the set_processing_mode method (no-op in fallback)
        bus.define_singleton_method(:set_processing_mode) do |event_type, subscriber, mode, interval = nil|
          # No-op in the fallback implementation
        end

        bus
      end
    end
  end
end