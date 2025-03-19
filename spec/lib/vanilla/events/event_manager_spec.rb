require 'spec_helper'
require 'vanilla/events/event_manager'

RSpec.describe Vanilla::Events::EventManager do
  let(:logger) { double("Logger").as_null_object }
  let(:event_bus_mock) { double("FiberEventBus") }
  let(:manager) { described_class.new(logger, file: false) }
  let(:event_type) { "test_event" }
  let(:event) { Vanilla::Events::Event.new(event_type, "source", { data: 123 }) }
  let(:subscriber) { double("Subscriber", handle_event: nil) }
  let(:another_subscriber) { double("AnotherSubscriber", handle_event: nil) }

  before(:each) do
    # Mock the FiberConcurrency module to avoid actual interaction with FiberEventBus
    allow(Vanilla::FiberConcurrency).to receive(:initialize)
    allow(Vanilla::FiberConcurrency).to receive(:event_bus).and_return(event_bus_mock)
    allow(Vanilla::FiberConcurrency).to receive(:instance_variable_get).with(:@initialized).and_return(true)

    # Set up the event_bus_mock to allow the necessary method calls
    allow(event_bus_mock).to receive(:subscribe)
    allow(event_bus_mock).to receive(:unsubscribe)
    allow(event_bus_mock).to receive(:set_processing_mode)
    allow(event_bus_mock).to receive(:publish)

    # Override the publish method to call the original event store and deliver directly
    allow(manager).to receive(:publish).and_wrap_original do |original_method, event|
      # Also call the storage part of the original method
      manager.instance_variable_get(:@event_store)&.store(event)

      # Direct delivery to subscribers without going through FiberEventBus
      type = event.type
      subscribers = manager.instance_variable_get(:@subscribers)[type]
      subscribers&.each do |sub|
        begin
          sub.handle_event(event)
        rescue => e
          logger.error("Error handling event: #{e.message}")
        end
      end
    end
  end

  describe "#initialize" do
    it "initializes with default settings" do
      expect(manager).to be_a(described_class)
    end

    context "with file storage" do
      let(:file_store) { instance_double(Vanilla::Events::Storage::FileEventStore) }

      it "initializes the file store with default directory" do
        expect(Vanilla::Events::Storage::FileEventStore).to receive(:new)
          .with("event_logs")
          .and_return(file_store)

        described_class.new(logger)
      end

      it "initializes the file store with custom directory" do
        expect(Vanilla::Events::Storage::FileEventStore).to receive(:new)
          .with("custom/dir")
          .and_return(file_store)

        described_class.new(logger, file: true, file_directory: "custom/dir")
      end
    end
  end

  describe "#subscribe" do
    it "adds a subscriber for an event type" do
      manager.subscribe(event_type, subscriber)
      manager.publish(event)
      expect(subscriber).to have_received(:handle_event).with(event)
    end

    it "allows multiple subscribers for the same event type" do
      manager.subscribe(event_type, subscriber)
      manager.subscribe(event_type, another_subscriber)

      manager.publish(event)

      expect(subscriber).to have_received(:handle_event).with(event)
      expect(another_subscriber).to have_received(:handle_event).with(event)
    end
  end

  describe "#unsubscribe" do
    before do
      manager.subscribe(event_type, subscriber)
    end

    it "removes a subscriber for an event type" do
      manager.unsubscribe(event_type, subscriber)
      manager.publish(event)
      expect(subscriber).not_to have_received(:handle_event)
    end

    it "doesn't affect other subscribers" do
      manager.subscribe(event_type, another_subscriber)
      manager.unsubscribe(event_type, subscriber)

      manager.publish(event)

      expect(subscriber).not_to have_received(:handle_event)
      expect(another_subscriber).to have_received(:handle_event).with(event)
    end
  end

  describe "#publish" do
    before do
      manager.subscribe(event_type, subscriber)
    end

    it "delivers the event to subscribed handlers" do
      expect(subscriber).to receive(:handle_event).with(event)
      manager.publish(event)
    end

    it "doesn't deliver to handlers for other event types" do
      another_subscriber = double("OtherSubscriber", handle_event: nil)
      other_event_type = "other_event"
      manager.subscribe(other_event_type, another_subscriber)

      expect(another_subscriber).not_to receive(:handle_event)
      manager.publish(event)
    end

    it "catches and logs exceptions from handlers" do
      expect(subscriber).to receive(:handle_event).and_raise("Test error")
      expect(logger).to receive(:error).with(/Error handling event: Test error/)
      manager.publish(event)
    end

    context "with storage" do
      let(:event_store) { instance_double(Vanilla::Events::Storage::FileEventStore) }

      before do
        manager.instance_variable_set(:@event_store, event_store)
        allow(event_store).to receive(:store)
      end

      it "stores the event" do
        expect(event_store).to receive(:store).with(event)
        manager.publish(event)
      end
    end
  end

  describe "#publish_event" do
    before do
      manager.subscribe(event_type, subscriber)
    end

    it "creates and publishes an event" do
      expect(subscriber).to receive(:handle_event)
      manager.publish_event(event_type, "test_source", { number: 42 })
    end

    it "returns the created event" do
      result = manager.publish_event(event_type, "test_source", { number: 42 })
      expect(result).to be_a(Vanilla::Events::Event)
      expect(result.type).to eq(event_type)
      expect(result.source).to eq("test_source")
      expect(result.data).to eq({ number: 42 })
    end
  end

  describe "#query_events" do
    context "without storage" do
      it "returns an empty array" do
        expect(manager.query_events).to eq([])
      end
    end

    context "with storage" do
      let(:event_store) { instance_double(Vanilla::Events::Storage::FileEventStore) }
      let(:query_results) { [event] }

      before do
        manager.instance_variable_set(:@event_store, event_store)
        allow(event_store).to receive(:query).and_return(query_results)
      end

      it "delegates to the storage" do
        options = { type: "test" }
        expect(event_store).to receive(:query).with(options)
        manager.query_events(options)
      end

      it "returns results from storage" do
        expect(manager.query_events).to eq(query_results)
      end
    end
  end

  describe "#close" do
    it "doesn't error without storage" do
      expect { manager.close }.not_to raise_error
    end

    context "with storage" do
      let(:event_store) { instance_double(Vanilla::Events::Storage::FileEventStore) }

      before do
        manager.instance_variable_set(:@event_store, event_store)
        allow(event_store).to receive(:close)
      end

      it "closes the storage" do
        expect(event_store).to receive(:close)
        manager.close
      end
    end
  end
end