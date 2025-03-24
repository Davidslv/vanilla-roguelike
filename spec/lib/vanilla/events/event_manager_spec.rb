# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Vanilla::Events::EventManager do
  let(:logger) { double("Logger").as_null_object }
  let(:manager) { described_class.new(logger, file: false) }
  let(:event_type) { "test_event" }
  let(:event) { Vanilla::Events::Event.new(event_type, "source", { data: 123 }) }
  let(:subscriber) { double("Subscriber") }

  before do
    allow(subscriber).to receive(:handle_event)
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
      another_subscriber = double("AnotherSubscriber")
      allow(another_subscriber).to receive(:handle_event)

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
      another_subscriber = double("AnotherSubscriber")
      allow(another_subscriber).to receive(:handle_event)

      manager.subscribe(event_type, another_subscriber)
      manager.unsubscribe(event_type, subscriber)

      manager.publish(event)

      expect(subscriber).not_to have_received(:handle_event)
      expect(another_subscriber).to have_received(:handle_event).with(event)
    end
  end

  describe "#publish" do
    it "delivers the event to subscribed handlers" do
      manager.subscribe(event_type, subscriber)
      manager.publish(event)
      expect(subscriber).to have_received(:handle_event).with(event)
    end

    it "doesn't deliver to handlers for other event types" do
      manager.subscribe("other_event", subscriber)
      manager.publish(event)
      expect(subscriber).not_to have_received(:handle_event)
    end

    it "catches and logs exceptions from handlers" do
      error_subscriber = double("ErrorSubscriber")
      allow(error_subscriber).to receive(:handle_event).and_raise("Test error")
      expect(logger).to receive(:error).at_least(:once)

      manager.subscribe(event_type, error_subscriber)
      expect { manager.publish(event) }.not_to raise_error
    end

    context "with storage" do
      let(:file_store) { instance_double(Vanilla::Events::Storage::FileEventStore) }
      let(:manager_with_storage) { described_class.new(logger, file: true) }

      before do
        allow(Vanilla::Events::Storage::FileEventStore).to receive(:new)
          .and_return(file_store)
        allow(file_store).to receive(:store)
      end

      it "stores the event" do
        expect(file_store).to receive(:store).with(event)
        manager_with_storage.publish(event)
      end
    end
  end

  describe "#publish_event" do
    it "creates and publishes an event" do
      manager.subscribe(event_type, subscriber)

      manager.publish_event(event_type, "test_source", { number: 42 })

      expect(subscriber).to have_received(:handle_event) do |received_event|
        expect(received_event.type).to eq(event_type)
        expect(received_event.source).to eq("test_source")
        expect(received_event.data).to eq({ number: 42 })
      end
    end

    it "returns the created event" do
      result = manager.publish_event(event_type, "test_source", { number: 42 })
      expect(result).to be_a(Vanilla::Events::Event)
      expect(result.type).to eq(event_type)
    end
  end

  describe "#query_events" do
    context "without storage" do
      it "returns an empty array" do
        expect(manager.query_events).to eq([])
      end
    end

    context "with storage" do
      let(:file_store) { instance_double(Vanilla::Events::Storage::FileEventStore) }
      let(:manager_with_storage) { described_class.new(logger, file: true) }
      let(:events) { [event] }

      before do
        allow(Vanilla::Events::Storage::FileEventStore).to receive(:new)
          .and_return(file_store)
        allow(file_store).to receive(:query).and_return(events)
      end

      it "delegates to the storage" do
        options = { type: "test", limit: 10 }
        expect(file_store).to receive(:query).with(options)
        manager_with_storage.query_events(options)
      end

      it "returns results from storage" do
        expect(manager_with_storage.query_events).to eq(events)
      end
    end
  end

  describe "#close" do
    it "doesn't error without storage" do
      expect { manager.close }.not_to raise_error
    end

    context "with storage" do
      let(:file_store) { instance_double(Vanilla::Events::Storage::FileEventStore) }
      let(:manager_with_storage) { described_class.new(logger, file: true) }

      before do
        allow(Vanilla::Events::Storage::FileEventStore).to receive(:new)
          .and_return(file_store)
        allow(file_store).to receive(:close)
      end

      it "closes the storage" do
        expect(file_store).to receive(:close)
        manager_with_storage.close
      end
    end
  end
end
