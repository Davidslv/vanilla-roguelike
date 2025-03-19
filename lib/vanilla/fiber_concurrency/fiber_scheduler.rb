# frozen_string_literal: true

require 'singleton'

module Vanilla
  module FiberConcurrency
    # The FiberScheduler class is responsible for managing fibers in the system.
    # It provides methods for registering, unregistering, and resuming fibers.
    #
    # The scheduler maintains a registry of active fibers, which can be resumed
    # in batches. This allows for efficient non-blocking operations.
    class FiberScheduler
      include Singleton

      # List of fibers managed by the scheduler
      attr_reader :fibers

      # Initialize the scheduler
      # @param logger [Logger] optional logger
      def initialize
        @fibers = []
        @fiber_lock = Mutex.new
        @logger = nil
        @active = true  # Start in active state
      end

      # Set the logger for the scheduler
      # @param logger [Logger] the logger to use
      # @return [void]
      def logger=(logger)
        @logger = logger
      end

      # Register a fiber with the scheduler
      # @param fiber [Fiber] the fiber to register
      # @param name [String] a descriptive name for the fiber (for debugging)
      # @param data [Hash] additional data associated with the fiber
      # @return [Fiber] the registered fiber
      def register(fiber, name = "unnamed_fiber", data = {})
        unless fiber.is_a?(Fiber)
          raise ArgumentError, "Expected a Fiber, got #{fiber.class}"
        end

        return fiber unless fiber.alive?

        @fiber_lock.synchronize do
          # Only add if it's not already there
          unless @fibers.any? { |f| f[:fiber] == fiber }
            @fibers << { fiber: fiber, name: name, data: data }
            @logger&.debug("Registered fiber: #{name}")
          end
        end

        fiber
      end

      # Unregister a fiber from the scheduler
      # @param fiber [Fiber] the fiber to unregister
      # @return [Boolean] true if fiber was removed, false otherwise
      def unregister(fiber)
        removed = false

        @fiber_lock.synchronize do
          fiber_data = @fibers.find { |f| f[:fiber] == fiber }

          if fiber_data
            @fibers.delete(fiber_data)
            @logger&.debug("Unregistered fiber: #{fiber_data[:name]}")
            removed = true
          end
        end

        removed
      end

      # Resume all registered fibers
      # @return [Integer] number of resumed fibers
      def resume_all
        resumed_count = 0
        dead_fibers = []

        @fiber_lock.synchronize do
          @fibers.each do |fiber_data|
            fiber = fiber_data[:fiber]
            name = fiber_data[:name]

            begin
              # Check if the fiber is still alive
              if fiber.alive?
                # Resume the fiber and count it
                fiber.resume
                resumed_count += 1
              else
                # Mark for removal
                dead_fibers << fiber_data
                @logger&.debug("Fiber #{name} is dead, removing from scheduler")
              end
            rescue => e
              # Log the error but don't stop processing
              error_message = "Error in fiber #{name}: #{e.message}"
              @logger&.error(error_message)
              @logger&.debug(e.backtrace.join("\n")) if @logger&.respond_to?(:debug)
            end
          end

          # Remove any dead fibers
          dead_fibers.each { |f| @fibers.delete(f) }
        end

        resumed_count
      end

      # Shutdown the scheduler by waiting for all fibers to complete
      # @param timeout [Integer] maximum time to wait in seconds
      # @return [Boolean] whether all fibers completed within the timeout
      def shutdown(timeout = 5)
        @logger&.info("Fiber scheduler shutting down")
        @active = false

        start_time = Time.now

        while !@fibers.empty? && (Time.now - start_time) < timeout
          resume_all
          sleep 0.01 # Small sleep to prevent CPU spinning
        end

        remaining = @fibers.count

        if remaining > 0
          @logger&.warn("Scheduler shutdown with #{remaining} fibers still active")
          @fibers.each do |f|
            @logger&.debug(" - #{f[:name]}")
          end
          false
        else
          @logger&.info("Scheduler shutdown complete, all fibers terminated")
          @fibers.clear
          true
        end
      end

      # Check if the scheduler is active
      # @return [Boolean] true if the scheduler is active
      def active?
        @active
      end

      # Get the current count of active fibers
      # @return [Integer] the number of active fibers
      def fiber_count
        @fibers.count
      end

      # Get the names of all active fibers
      # @return [Array<String>] names of active fibers
      def fiber_names
        @fibers.map { |f| f[:name] }
      end
    end
  end
end