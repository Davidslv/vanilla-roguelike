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
    # Initialize the fiber concurrency system
    # This sets up the event bus and logger
    # @return [void]
    def self.initialize
      # Create singleton instances
      fiber_event_bus = FiberEventBus.instance
      fiber_logger = FiberLogger.instance

      # Log initialization
      fiber_logger.info("Fiber concurrency system initialized")
    end

    # Tick the fiber scheduler to process events
    # Call this method once per game loop
    # @return [Integer] Number of fibers that were resumed
    def self.tick
      FiberEventBus.instance.tick
    end

    # Shutdown the fiber concurrency system
    # @param wait [Boolean] Whether to wait for fibers to complete
    # @return [void]
    def self.shutdown(wait = true)
      FiberEventBus.instance.shutdown(wait)
      FiberLogger.instance.close
    end
  end
end