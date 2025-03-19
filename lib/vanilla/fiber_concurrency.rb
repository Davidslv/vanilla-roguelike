require_relative 'fiber_concurrency/fiber_scheduler'
require_relative 'fiber_concurrency/fiber_event_bus'
require_relative 'fiber_concurrency/fiber_logger'

module Vanilla
  # FiberConcurrency module provides fiber-based asynchronous event handling
  # and logging to improve performance in the Vanilla game engine.
  #
  # This module implements an event bus pattern using Ruby fibers for cooperative
  # multitasking instead of threads, resulting in lower memory usage and
  # avoiding threading issues while still allowing for non-blocking I/O.
  module FiberConcurrency
    class << self
      # Initialize the fiber concurrency system
      # This sets up the scheduler, logger, and event bus
      def initialize
        return if @initialized

        # Get singletons
        @scheduler = Vanilla::FiberConcurrency::FiberScheduler.instance
        @logger = Vanilla::FiberConcurrency::FiberLogger.instance
        @event_bus = Vanilla::FiberConcurrency::FiberEventBus.instance

        @initialized = true
      end

      # Process all queued fibers
      # This should be called once per game loop
      def tick
        return unless @initialized
        @scheduler.resume_all
      end

      # Shutdown the fiber concurrency system
      # This waits for all fibers to complete and closes the logger
      def shutdown
        return unless @initialized
        @scheduler.shutdown
        @logger.close
        @initialized = false
      end

      # Get the logger instance
      def logger
        @logger
      end

      # Get the event bus instance
      def event_bus
        @event_bus
      end

      # Get the scheduler instance
      def scheduler
        @scheduler
      end

      # Check if the system is initialized
      def initialized?
        @initialized
      end
    end
  end
end