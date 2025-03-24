# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'

RSpec.describe Vanilla::Events::Storage::FileEventStore do
  let(:test_dir) { "event_logs/test/event_test" }
  let(:store) { described_class.new(test_dir) }
  let(:event) { Vanilla::Events::Event.new("test_event", "test_source", { data: "value" }) }

  before do
    # Clean up test directory before each test
    FileUtils.rm_rf(test_dir)
    FileUtils.mkdir_p(test_dir)
  end

  after do
    # Clean up after tests
    FileUtils.rm_rf(test_dir)
  end

  describe "#initialize" do
    it "creates the directory if it doesn't exist" do
      nonexistent_dir = "#{test_dir}/nonexistent"
      expect(Dir.exist?(nonexistent_dir)).to be false

      described_class.new(nonexistent_dir)
      expect(Dir.exist?(nonexistent_dir)).to be true
    end

    it "sets a current session ID" do
      expect(store.current_session).to be_a(String)
      expect(store.current_session).to match(/\d{8}_\d{6}/)
    end

    it "allows a custom session ID" do
      custom_session = "custom_session_123"
      custom_store = described_class.new(test_dir, custom_session)
      expect(custom_store.current_session).to eq(custom_session)
    end
  end

  describe "#store" do
    it "stores events to the file system" do
      store.store(event)
      expect(Dir.glob("#{test_dir}/events_*.jsonl").size).to eq(1)
    end

    it "appends events to the same file within a session" do
      5.times { store.store(event) }
      event_files = Dir.glob("#{test_dir}/events_*.jsonl")
      expect(event_files.size).to eq(1)

      content = File.read(event_files.first)
      expect(content.lines.count).to eq(5)
    end

    it "writes valid JSON for each event" do
      store.store(event)
      event_file = Dir.glob("#{test_dir}/events_*.jsonl").first
      content = File.read(event_file)

      parsed = JSON.parse(content)
      expect(parsed["type"]).to eq("test_event")
    end
  end

  describe "#load_session" do
    before do
      # Store multiple events
      3.times { |i| store.store(Vanilla::Events::Event.new("event_#{i}", "source", { index: i })) }
    end

    it "loads events from the current session by default" do
      events = store.load_session
      expect(events.size).to eq(3)
      expect(events.map(&:type)).to eq(["event_0", "event_1", "event_2"])
    end

    it "reconstructs event objects with correct data" do
      events = store.load_session
      expect(events[0].data).to include(index: 0)
      expect(events[1].data).to include(index: 1)
      expect(events[2].data).to include(index: 2)
    end

    it "returns an empty array for nonexistent sessions" do
      events = store.load_session("nonexistent_session")
      expect(events).to eq([])
    end
  end

  describe "#query" do
    before do
      # Store events of different types
      store.store(Vanilla::Events::Event.new("type_a", "source", { index: 1 }))
      store.store(Vanilla::Events::Event.new("type_a", "source", { index: 2 }))
      store.store(Vanilla::Events::Event.new("type_b", "source", { index: 3 }))
    end

    it "filters events by type" do
      events = store.query(type: "type_a")
      expect(events.size).to eq(2)
      expect(events.map(&:type).uniq).to eq(["type_a"])
    end

    it "returns all events when no filter is specified" do
      events = store.query
      expect(events.size).to eq(3)
    end

    it "limits the number of results" do
      events = store.query(limit: 2)
      expect(events.size).to eq(2)
    end
  end

  describe "#list_sessions" do
    it "returns an empty array when no sessions exist" do
      expect(store.list_sessions).to eq([])
    end

    it "lists all available sessions" do
      # Create multiple session files
      store1 = described_class.new(test_dir, "session1")
      store2 = described_class.new(test_dir, "session2")

      store1.store(event)
      store2.store(event)

      sessions = store.list_sessions
      expect(sessions.sort).to eq(["session1", "session2"])
    end
  end

  describe "#close" do
    it "closes the file handle" do
      store.store(event)

      # Get file handle through reflection
      file = store.instance_variable_get(:@current_file)
      expect(file.closed?).to be false

      store.close
      expect(file.closed?).to be true
    end

    it "doesn't error when called multiple times" do
      store.close
      expect { store.close }.not_to raise_error
    end
  end
end
