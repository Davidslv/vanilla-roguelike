# frozen_string_literal: true

require 'spec_helper'

module Vanilla
  module Messages
    RSpec.describe MessageLog do
      let(:logger) { double('logger', debug: nil, info: nil, warn: nil, error: nil) }
      let(:message_log) { MessageLog.new(logger) }

      describe "#initialize" do
        it "creates an empty message list" do
          expect(message_log.messages).to be_empty
        end
      end

      describe "#add" do
        it "adds a message to the log" do
          message_log.add("Test message")
          expect(message_log.messages.size).to eq(1)
          expect(message_log.messages.first.content).to eq("Test message")
        end

        it "adds messages with the specified category" do
          message_log.add("Combat message", category: :combat)
          expect(message_log.messages.first.category).to eq(:combat)
        end

        it "adds messages with the specified importance" do
          message_log.add("Critical message", importance: :critical)
          expect(message_log.messages.first.importance).to eq(:critical)
        end

        it "trims messages when they exceed the maximum history size" do
          # Set a small history size for testing
          message_log = MessageLog.new(logger, history_size: 3)

          message_log.add("Message 1")
          message_log.add("Message 2")
          message_log.add("Message 3")
          message_log.add("Message 4")

          expect(message_log.messages.size).to eq(3)
          expect(message_log.messages.map(&:content)).to eq(["Message 4", "Message 3", "Message 2"])
        end
      end

      describe "#get_recent" do
        before do
          5.times { |i| message_log.add("Message #{i+1}") }
        end

        it "returns the specified number of recent messages" do
          recent = message_log.get_recent(3)
          expect(recent.size).to eq(3)
          expect(recent.map(&:content)).to eq(["Message 5", "Message 4", "Message 3"])
        end

        it "returns all messages if limit is greater than message count" do
          recent = message_log.get_recent(10)
          expect(recent.size).to eq(5)
        end
      end

      describe "#get_by_category" do
        before do
          message_log.add("Combat message 1", category: :combat)
          message_log.add("System message", category: :system)
          message_log.add("Combat message 2", category: :combat)
          message_log.add("Item message", category: :item)
        end

        it "returns messages filtered by category" do
          combat_messages = message_log.get_by_category(:combat)
          expect(combat_messages.size).to eq(2)
          expect(combat_messages.map(&:content)).to eq(["Combat message 2", "Combat message 1"])
        end

        it "returns an empty array if no messages match the category" do
          expect(message_log.get_by_category(:non_existent)).to be_empty
        end
      end

      describe "#get_by_importance" do
        before do
          message_log.add("Normal message", importance: :normal)
          message_log.add("Warning message", importance: :warning)
          message_log.add("Critical message", importance: :critical)
          message_log.add("Another warning", importance: :warning)
        end

        it "returns messages filtered by importance" do
          warning_messages = message_log.get_by_importance(:warning)
          expect(warning_messages.size).to eq(2)
          expect(warning_messages.map(&:content)).to eq(["Another warning", "Warning message"])
        end
      end

      describe "#clear" do
        before do
          3.times { |i| message_log.add("Message #{i+1}") }
        end

        it "removes all messages from the log" do
          expect(message_log.messages.size).to eq(3)
          message_log.clear
          expect(message_log.messages).to be_empty
        end
      end
    end
  end
end
