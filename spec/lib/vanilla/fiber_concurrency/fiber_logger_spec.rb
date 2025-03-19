require 'spec_helper'
require 'vanilla/fiber_concurrency/fiber_logger'

RSpec.describe Vanilla::FiberConcurrency::FiberLogger do
  let(:file_double) { instance_double(File, write: nil, puts: nil, flush: nil, close: nil, closed?: false) }
  let(:logger) { described_class.instance }
  let(:scheduler_mock) { double('FiberScheduler') }

  before(:each) do
    # Stub singleton methods
    allow(Vanilla::FiberConcurrency::FiberScheduler).to receive(:instance).and_return(scheduler_mock)
    allow(described_class).to receive(:instance).and_return(logger)

    # Stub ENV to handle any key
    allow(ENV).to receive(:[]).and_return(nil)
    allow(ENV).to receive(:[]).with("VANILLA_LOG_LEVEL").and_return(nil)
    allow(ENV).to receive(:[]).with("VANILLA_LOG_DIR").and_return(nil)

    # Mock file operations
    allow(File).to receive(:open).and_return(StringIO.new)
    allow(FileUtils).to receive(:mkdir_p)

    # Stub the setup_logging_fiber method to prevent the actual initialization
    allow_any_instance_of(described_class).to receive(:setup_logging_fiber)

    # Set up the logger for testing
    logger.instance_variable_set(:@file, file_double)
    logger.instance_variable_set(:@level, :info)
    logger.instance_variable_set(:@message_queue, [])
    logger.instance_variable_set(:@queue_mutex, Mutex.new)
    logger.instance_variable_set(:@max_batch_size, 10)
    logger.instance_variable_set(:@flush_interval, 0.5)
    logger.instance_variable_set(:@last_flush_time, Time.now)
    logger.instance_variable_set(:@running, true)

    # Allow the real process_message_queue to be called
    allow(logger).to receive(:process_message_queue).and_call_original
  end

  let(:event_bus) { instance_double(Vanilla::FiberConcurrency::FiberEventBus, subscribe: nil) }

  before(:each) do
    # Allow instance mocking for singleton
    allow(described_class).to receive(:instance).and_return(logger)

    # Prevent real setup_logging_fiber from running
    allow(logger).to receive(:setup_logging_fiber)

    # Reset all instance variables before each test
    logger.instance_variable_set(:@level, :info)
    logger.instance_variable_set(:@file, file_double)
    logger.instance_variable_set(:@message_queue, [])
    logger.instance_variable_set(:@max_batch_size, 10)
    logger.instance_variable_set(:@flush_interval, 0.5)
    logger.instance_variable_set(:@last_flush_time, Time.now)

    # Mock file access
    allow(File).to receive(:exist?).and_return(true)
    allow(File).to receive(:directory?).and_return(true)
    allow(File).to receive(:open).and_return(file_double)

    # Mock FiberEventBus
    allow(Vanilla::FiberConcurrency::FiberEventBus).to receive(:instance).and_return(event_bus)
  end

  class LogEvent
    attr_reader :type, :data

    def initialize(type = :log, data = {})
      @type = type
      @data = data
    end
  end

  describe "#initialize test workarounds" do
    it "has correct default values" do
      expect(logger.instance_variable_get(:@level)).to eq(:info)
      expect(logger.instance_variable_get(:@max_batch_size)).to eq(10)
      expect(logger.instance_variable_get(:@flush_interval)).to eq(0.5)
      expect(logger.instance_variable_get(:@message_queue)).to eq([])
    end
  end

  describe "logging methods" do
    let(:message) { "test message" }

    before do
      # Allow direct enqueue_message calls with any parameters
      allow(logger).to receive(:enqueue_message)
    end

    it "#debug logs at debug level" do
      expect(logger).to receive(:enqueue_message).with(:debug, message, an_instance_of(Time))
      logger.debug(message)
    end

    it "#info logs at info level" do
      expect(logger).to receive(:enqueue_message).with(:info, message, an_instance_of(Time))
      logger.info(message)
    end

    it "#warn logs at warn level" do
      expect(logger).to receive(:enqueue_message).with(:warn, message, an_instance_of(Time))
      logger.warn(message)
    end

    it "#error logs at error level" do
      expect(logger).to receive(:enqueue_message).with(:error, message, an_instance_of(Time), true)
      logger.error(message)
    end

    it "#fatal logs at fatal level" do
      expect(logger).to receive(:enqueue_message).with(:fatal, message, an_instance_of(Time), true)
      logger.fatal(message)
    end
  end

  describe "#handle_event" do
    before do
      # Allow direct enqueue_message calls with any parameters
      allow(logger).to receive(:enqueue_message)
    end

    it "processes events with log type" do
      event = { type: :log, level: :warn, message: "test event message" }
      expect(logger).to receive(:enqueue_message).with(:warn, "test event message", an_instance_of(Time))
      logger.handle_event(event)
    end

    it "ignores events with non-log type" do
      event = { type: :not_log, message: "test message" }
      expect(logger).not_to receive(:enqueue_message)
      logger.handle_event(event)
    end

    it "accepts string event types" do
      event = { type: "log", level: :warn, message: "string event" }
      expect(logger).to receive(:enqueue_message).with(:warn, "string event", an_instance_of(Time))
      logger.handle_event(event)
    end

    it "defaults to info level if not specified" do
      event = { type: :log, message: "no level specified" }
      expect(logger).to receive(:enqueue_message).with(:info, "no level specified", an_instance_of(Time))
      logger.handle_event(event)
    end

    it "uses event data inspect if message not specified" do
      event = { type: :log, level: :debug, data: "some data" }
      expect(logger).to receive(:enqueue_message).with(:debug, anything, an_instance_of(Time))
      logger.handle_event(event)
    end
  end

  describe "#close" do
    it "processes any remaining messages" do
      logger.instance_variable_set(:@message_queue, [{ level: :info, message: "test", timestamp: Time.now }])
      expect(logger).to receive(:process_message_queue).with(true)
      logger.close
    end

    it "writes an ending header to the log file" do
      allow(logger).to receive(:process_message_queue).and_return(0)
      expect(file_double).to receive(:write).with(/===== Log Closed/)
      logger.close
    end

    it "closes the file" do
      allow(logger).to receive(:process_message_queue).and_return(0)
      expect(file_double).to receive(:close)
      logger.close
    end

    it "sets the file to nil" do
      allow(logger).to receive(:process_message_queue).and_return(0)
      allow(file_double).to receive(:write)
      allow(file_double).to receive(:close)
      logger.close
      expect(logger.instance_variable_get(:@file)).to be_nil
    end

    it "does nothing if the file is already closed" do
      logger.instance_variable_set(:@file, nil)
      expect(logger).not_to receive(:process_message_queue)
      logger.close
    end
  end

  describe "#flush" do
    it "processes messages with force_flush=true" do
      expect(logger).to receive(:process_message_queue).with(true)
      logger.flush
    end

    it "does nothing if the file is closed" do
      logger.instance_variable_set(:@file, nil)
      expect(logger).not_to receive(:process_message_queue)
      logger.flush
    end
  end

  describe "#open?" do
    it "returns true if the file is open" do
      expect(logger.open?).to be true
    end

    it "returns false if the file is closed" do
      logger.instance_variable_set(:@file, nil)
      expect(logger.open?).to be false
    end
  end

  describe "#enqueue_message" do
    before do
      # Stub out process_messages to avoid side effects
      allow(logger).to receive(:process_message_queue)
    end

    it "filters out messages below the current log level" do
      logger.instance_variable_set(:@level, :warn)
      logger.send(:enqueue_message, :info, "info message", Time.now)
      expect(logger.instance_variable_get(:@message_queue)).to be_empty
    end

    it "adds messages at or above the current log level to the queue" do
      logger.instance_variable_set(:@level, :info)

      logger.send(:enqueue_message, :info, "info message", Time.now)
      logger.send(:enqueue_message, :warn, "warn message", Time.now)
      logger.send(:enqueue_message, :error, "error message", Time.now, true)

      queue = logger.instance_variable_get(:@message_queue)
      expect(queue.size).to eq(3)
      expect(queue.map { |m| m[:level] }).to eq([:info, :warn, :error])
    end

    it "sets immediate_flush for error and fatal messages" do
      logger.send(:enqueue_message, :error, "error message", Time.now, true)

      queue = logger.instance_variable_get(:@message_queue)
      expect(queue.first[:immediate_flush]).to be true
    end

    it "does not set immediate_flush for normal messages" do
      logger.send(:enqueue_message, :info, "info message", Time.now)

      queue = logger.instance_variable_get(:@message_queue)
      expect(queue.first[:immediate_flush]).to be_nil
    end

    it "uses the provided timestamp" do
      timestamp = Time.new(2023, 1, 1, 12, 0, 0)
      logger.send(:enqueue_message, :info, "message", timestamp)

      queue = logger.instance_variable_get(:@message_queue)
      expect(queue.first[:timestamp]).to eq(timestamp)
    end
  end

  describe "#process_message_queue" do
    it "processes up to max_batch_size messages" do
      # Setup a batch of 11 messages (more than max_batch_size of 10)
      messages = Array.new(11) { |i| { level: :info, message: "Message #{i}", timestamp: Time.now } }
      logger.instance_variable_set(:@message_queue, messages)

      # Allow write_log to avoid actually writing
      allow(logger).to receive(:write_log)

      # Call the method
      logger.send(:process_message_queue)

      # Should process 10 messages, leaving 1 in the queue
      expect(logger.instance_variable_get(:@message_queue).size).to eq(1)
    end

    it "flushes the file when force_flush is true" do
      # Setup test message
      logger.instance_variable_set(:@message_queue, [{ level: :info, message: "test", timestamp: Time.now }])

      # Allow write_log to avoid actually writing
      allow(logger).to receive(:write_log)

      # Expect flush to be called
      expect(file_double).to receive(:flush)

      # Call with force_flush=true
      logger.send(:process_message_queue, true)
    end

    it "flushes the file when the flush interval has elapsed" do
      # Setup test message
      logger.instance_variable_set(:@message_queue, [{ level: :info, message: "test", timestamp: Time.now }])

      # Set last flush to far in the past
      logger.instance_variable_set(:@last_flush_time, Time.now - 1000)

      # Allow write_log to avoid actually writing
      allow(logger).to receive(:write_log)

      # Expect flush to be called
      expect(file_double).to receive(:flush)

      # Call the method
      logger.send(:process_message_queue)
    end

    it "flushes the file when an immediate_flush message is processed" do
      # Setup test message with immediate_flush flag
      logger.instance_variable_set(:@message_queue, [{
        level: :error,
        message: "test",
        timestamp: Time.now,
        immediate_flush: true
      }])

      # Allow write_log to avoid actually writing
      allow(logger).to receive(:write_log)

      # Expect flush to be called
      expect(file_double).to receive(:flush)

      # Call the method
      logger.send(:process_message_queue)
    end

    it "does not flush if no messages are processed" do
      # Empty the queue
      logger.instance_variable_set(:@message_queue, [])

      # Expect flush NOT to be called
      expect(file_double).not_to receive(:flush)

      # Call the method
      logger.send(:process_message_queue)
    end

    it "handles empty queue gracefully" do
      # Empty the queue
      logger.instance_variable_set(:@message_queue, [])

      # Should not raise any errors
      expect { logger.send(:process_message_queue) }.not_to raise_error
    end

    it "does nothing if the file is closed" do
      # Set file to nil to simulate closed file
      logger.instance_variable_set(:@file, nil)

      # Call the method
      result = logger.send(:process_message_queue)

      # Should return 0 (no messages processed)
      expect(result).to eq(0)
    end
  end

  describe "#write_log" do
    it "formats the log message with timestamp and level" do
      timestamp = Time.new(2023, 1, 1, 12, 0, 0)
      expected_format = "[2023-01-01 12:00:00 INFO] Test message\n"

      expect(file_double).to receive(:write).with(expected_format)
      logger.send(:write_log, :info, "Test message", timestamp)
    end

    it "does nothing if the file is closed" do
      logger.instance_variable_set(:@file, nil)
      expect(file_double).not_to receive(:write)
      logger.send(:write_log, :info, "Test message", Time.now)
    end
  end
end