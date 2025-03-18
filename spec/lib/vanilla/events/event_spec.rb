require 'spec_helper'

RSpec.describe Vanilla::Events::Event do
  let(:type) { "test_event" }
  let(:source) { "test_source" }
  let(:data) { { key: "value", number: 42 } }
  let(:event) { described_class.new(type, source, data) }

  describe "#initialize" do
    it "initializes with required attributes" do
      expect(event.type).to eq(type)
      expect(event.source).to eq(source)
      expect(event.data).to eq(data)
      expect(event.timestamp).to be_a(Time)
    end

    it "sets default values for optional parameters" do
      event = described_class.new(type)
      expect(event.source).to be_nil
      expect(event.data).to eq({})
    end
  end

  describe "#to_s" do
    it "returns a human-readable string representation" do
      string = event.to_s
      expect(string).to include(type)
      expect(string).to include(data.inspect)
    end
  end

  describe "#to_h" do
    it "returns a hash representation" do
      hash = event.to_h
      expect(hash[:type]).to eq(type)
      expect(hash[:source]).to eq(source.to_s)
      expect(hash[:data]).to eq(data)
      expect(hash[:timestamp]).to be_a(String)
    end
  end

  describe "#to_json" do
    it "returns a JSON string representation" do
      json = event.to_json
      expect(json).to be_a(String)

      # Parse and verify
      parsed = JSON.parse(json, symbolize_names: true)
      expect(parsed[:type]).to eq(type)
      expect(parsed[:data]).to eq(data)
    end
  end

  describe ".from_json" do
    it "recreates an event from its JSON representation" do
      json = event.to_json
      recreated = described_class.from_json(json)

      expect(recreated.type).to eq(event.type)
      expect(recreated.source).to eq(event.source.to_s)
      expect(recreated.data).to eq(event.data)
      expect(recreated.timestamp.to_i).to eq(event.timestamp.to_i)
    end
  end
end