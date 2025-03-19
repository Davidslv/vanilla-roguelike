module Vanilla
  module FiberConcurrency
    # FiberScheduler is responsible for managing and resuming fibers.
    # It provides cooperative concurrency without the overhead of threads.
    class FiberScheduler
      # Singleton access
      class << self
        def instance
          @instance ||= new
        end
      end

      private_class_method :new

      # Initialize a new fiber scheduler
      # @param logger [Logger] Optional logger for debugging
      def initialize(logger = nil)
        @fibers = []
        @active = true
        @logger = logger
      end

      # Get the logger, lazy-loaded if not provided in constructor
      def logger
        @logger ||= begin
          # Avoid circular dependency by checking if FiberLogger is already defined
          if Vanilla.const_defined?(:FiberConcurrency) &&
             Vanilla::FiberConcurrency.const_defined?(:FiberLogger) &&
             !Vanilla::FiberConcurrency::FiberLogger.instance.equal?(self)
            Vanilla::FiberConcurrency::FiberLogger.instance
          else
            # Fallback to a simple logger that just outputs to STDOUT if there's a circular dependency
            logger = Object.new
            def logger.method_missing(method, *args)
              puts "[FiberScheduler] #{method}: #{args.join(' ')}" if [:debug, :info, :warn, :error, :fatal].include?(method)
            end
            logger
          end
        end
      end

      # Register a fiber with the scheduler
      # @param fiber [Fiber] The fiber to register
      # @param name [String, Symbol] Optional name for the fiber (for debugging)
      # @return [Fiber] The registered fiber
      def register(fiber, name = nil)
        unless fiber.is_a?(Fiber)
          raise ArgumentError, "Expected a Fiber object, got #{fiber.class}"
        end

        @fibers << { fiber: fiber, name: name || "fiber_#{@fibers.size}" }
        logger.debug("Registered fiber: #{name || 'unnamed'}")
        fiber
      end

      # Unregister a fiber from the scheduler
      # @param fiber [Fiber] The fiber to unregister
      # @return [Boolean] Whether the fiber was found and removed
      def unregister(fiber)
        size_before = @fibers.size
        @fibers.reject! { |f| f[:fiber] == fiber }
        removed = size_before > @fibers.size
        logger.debug("Unregistered fiber: #{removed ? 'success' : 'not found'}")
        removed
      end

      # Resume all registered fibers that are alive
      # @return [Integer] Number of fibers that were resumed
      def resume_all
        count = 0
        @fibers.each do |f|
          if f[:fiber].alive?
            begin
              f[:fiber].resume
              count += 1
            rescue => e
              logger.error("Error in fiber #{f[:name]}: #{e.message}")
              logger.error(e.backtrace.join("\n"))
            end
          else
            logger.debug("Fiber #{f[:name]} is dead, will be removed")
          end
        end

        # Clean up dead fibers
        @fibers.reject! { |f| !f[:fiber].alive? }

        count
      end

      # Shutdown the scheduler and clean up resources
      # @param wait [Boolean] Whether to wait for fibers to complete
      # @param max_attempts [Integer] Maximum number of resume_all attempts when waiting
      # @return [void]
      def shutdown(wait = true, max_attempts = 10)
        @active = false
        logger.info("Fiber scheduler shutting down, waiting for fibers: #{wait}")

        if wait && !@fibers.empty?
          # Give fibers a chance to clean up, but with a maximum number of attempts
          attempts = 0
          while @fibers.any? { |f| f[:fiber].alive? } && attempts < max_attempts
            resume_all
            attempts += 1
          end
        end

        @fibers.clear
      end

      # Check if the scheduler is active
      # @return [Boolean] Whether the scheduler is active
      def active?
        @active
      end

      # Get the number of registered fibers
      # @return [Integer] Number of registered fibers
      def fiber_count
        @fibers.size
      end

      # Get names of all registered fibers
      # @return [Array<String>] Names of registered fibers
      def fiber_names
        @fibers.map { |f| f[:name] }
      end
    end
  end
end