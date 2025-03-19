require 'spec_helper'
require 'vanilla/fiber_concurrency'
require 'vanilla/fiber_concurrency/fiber_scheduler'
require 'vanilla/fiber_concurrency/fiber_logger'

# Add test environment flag
$TESTING = true

RSpec.describe Vanilla::FiberConcurrency::FiberScheduler do
  # Create a test scheduler instance with mocked dependencies
  let(:scheduler) do
    # Create a mock for FiberLogger to avoid circular dependency
    logger_mock = double("Logger")
    allow(logger_mock).to receive(:info)
    allow(logger_mock).to receive(:debug)
    allow(logger_mock).to receive(:error)
    allow(logger_mock).to receive(:warn)

    # Stub the singleton method to avoid circular dependency
    allow(Vanilla::FiberConcurrency::FiberLogger).to receive(:instance).and_return(logger_mock)

    # Get the singleton instance
    scheduler_instance = described_class.instance

    # Reset internal state for testing
    scheduler_instance.instance_variable_set(:@fibers, [])
    scheduler_instance.instance_variable_set(:@active, true)
    scheduler_instance.instance_variable_set(:@logger, logger_mock)

    scheduler_instance
  end

  before(:each) do
    # Reset all instance variables
    scheduler.instance_variable_set(:@fibers, [])
    scheduler.instance_variable_set(:@active, true)

    # Get the logger mock from the scheduler
    @logger_mock = scheduler.instance_variable_get(:@logger)
  end

  describe "#initialize" do
    it "creates an empty fiber list" do
      expect(scheduler.instance_variable_get(:@fibers)).to eq([])
    end

    it "starts in active state" do
      expect(scheduler.instance_variable_get(:@active)).to be true
    end
  end

  describe "#register" do
    let(:fiber) { Fiber.new {} }

    it "adds the fiber to the registry" do
      scheduler.register(fiber)
      fibers = scheduler.instance_variable_get(:@fibers)
      expect(fibers.map { |f| f[:fiber] }).to include(fiber)
    end

    it "logs a debug message" do
      expect(@logger_mock).to receive(:debug).with(/Registered fiber/)
      scheduler.register(fiber)
    end

    it "returns the registered fiber" do
      expect(scheduler.register(fiber)).to eq(fiber)
    end

    it "assigns the specified name" do
      scheduler.register(fiber, "test_fiber")
      fibers = scheduler.instance_variable_get(:@fibers)
      expect(fibers.first[:name]).to eq("test_fiber")
    end

    it "raises error for non-fiber objects" do
      expect { scheduler.register("not a fiber") }.to raise_error(ArgumentError, /Expected a Fiber/)
    end
  end

  describe "#unregister" do
    let(:fiber) { Fiber.new {} }

    before(:each) do
      scheduler.register(fiber)
    end

    it "removes the fiber from the registry" do
      scheduler.unregister(fiber)
      fibers = scheduler.instance_variable_get(:@fibers)
      expect(fibers.map { |f| f[:fiber] }).not_to include(fiber)
    end

    it "logs a debug message" do
      expect(@logger_mock).to receive(:debug).with(/Unregistered fiber/)
      scheduler.unregister(fiber)
    end

    it "returns true if fiber was removed" do
      expect(scheduler.unregister(fiber)).to be true
    end

    it "returns false if fiber was not found" do
      other_fiber = Fiber.new {}
      expect(scheduler.unregister(other_fiber)).to be false
    end
  end

  describe "#resume_all" do
    let(:fiber1) { Fiber.new { Fiber.yield; "result" } }
    let(:fiber2) { Fiber.new { Fiber.yield; "result" } }
    let(:dead_fiber) { Fiber.new {} }

    before do
      scheduler.register(fiber1, "live_fiber1")
      scheduler.register(fiber2, "live_fiber2")
      scheduler.register(dead_fiber, "dead_fiber")

      # Make the dead fiber dead by resuming it fully
      dead_fiber.resume
    end

    it "resumes all alive fibers" do
      expect(fiber1).to receive(:resume).and_call_original
      expect(fiber2).to receive(:resume).and_call_original
      expect(dead_fiber).not_to receive(:resume)

      scheduler.resume_all
    end

    it "captures and logs errors in fibers" do
      error_fiber = Fiber.new { raise "Test error" }
      scheduler.register(error_fiber, "error_fiber")

      expect(@logger_mock).to receive(:error).with(/Error in fiber error_fiber/)
      expect(@logger_mock).to receive(:error)

      # Should not raise the error
      expect { scheduler.resume_all }.not_to raise_error
    end

    it "cleans up dead fibers" do
      scheduler.resume_all
      fibers = scheduler.instance_variable_get(:@fibers)
      expect(fibers.size).to eq(2)
      expect(fibers.map { |f| f[:name] }).not_to include("dead_fiber")
    end

    it "returns the number of fibers that were resumed" do
      expect(scheduler.resume_all).to eq(2)
    end
  end

  describe "#shutdown" do
    let(:fiber1) { Fiber.new { Fiber.yield; "result" } }
    let(:fiber2) { Fiber.new { Fiber.yield; "result" } }

    before do
      scheduler.register(fiber1)
      scheduler.register(fiber2)
    end

    it "logs a shutdown message" do
      expect(@logger_mock).to receive(:info).with(/Fiber scheduler shutting down/)
      scheduler.shutdown
    end

    it "sets active to false" do
      scheduler.shutdown
      expect(scheduler.instance_variable_get(:@active)).to be false
    end

    it "clears all fibers" do
      scheduler.shutdown
      expect(scheduler.instance_variable_get(:@fibers)).to be_empty
    end

    context "with waiting enabled" do
      it "waits for fibers to complete" do
        # Create test fibers that will be dead after one resume
        dead_after_resume = Fiber.new { "I will be dead after one resume" }
        scheduler.register(dead_after_resume, "test_fiber")

        # Mock resume_all to make the fiber dead after being called
        expect(scheduler).to receive(:resume_all) do
          # Simulate the fiber becoming dead after resume is called
          scheduler.instance_variable_get(:@fibers).clear
        end

        # This should not enter an infinite loop
        scheduler.shutdown

        # Verify fibers are cleared
        expect(scheduler.instance_variable_get(:@fibers)).to be_empty
      end
    end
  end

  describe "#active?" do
    it "returns true when active" do
      expect(scheduler.active?).to be true
    end

    it "returns false after shutdown" do
      scheduler.shutdown
      expect(scheduler.active?).to be false
    end
  end

  describe "#fiber_count" do
    it "returns the number of registered fibers" do
      scheduler.register(Fiber.new {})
      scheduler.register(Fiber.new {})
      expect(scheduler.fiber_count).to eq(2)
    end
  end

  describe "#fiber_names" do
    it "returns the names of registered fibers" do
      scheduler.register(Fiber.new {}, "fiber1")
      scheduler.register(Fiber.new {}, "fiber2")
      expect(scheduler.fiber_names).to eq(["fiber1", "fiber2"])
    end
  end
end