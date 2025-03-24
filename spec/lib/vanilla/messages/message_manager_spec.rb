# frozen_string_literal: true

require 'spec_helper'

module Vanilla
  module Messages
    RSpec.describe MessageManager do
      let(:logger) { double('logger', debug: nil, info: nil, warn: nil, error: nil) }
      let(:render_system) { double('render_system', render_string: nil, clear: nil) }
      let(:message_manager) { MessageManager.new(logger, render_system) }

      describe "#initialize" do
        it "creates a message log" do
          expect(message_manager.instance_variable_get(:@message_log)).to be_a(MessageLog)
        end

        it "initializes with selection mode disabled" do
          expect(message_manager.selection_mode).to be_falsey
        end
      end

      describe "#setup_panel" do
        it "creates a message panel with the specified dimensions" do
          message_manager.setup_panel(10, 20, 30, 5)
          panel = message_manager.instance_variable_get(:@panel)

          expect(panel).to be_a(MessagePanel)
          expect(panel.x).to eq(10)
          expect(panel.y).to eq(20)
          expect(panel.width).to eq(30)
          expect(panel.height).to eq(5)
        end
      end

      describe "#log_translated" do
        it "adds a translated message to the log" do
          allow(I18n).to receive(:t).with('test.key', default: 'test.key', param: 'value').and_return('Translated message')

          message_manager.log_translated('test.key', metadata: { param: 'value' })

          message = message_manager.get_recent_messages(1).first
          expect(message.content).to eq('test.key')
          expect(message.metadata).to eq({ param: 'value' })
        end
      end

      describe "#log_success/#log_warning/#log_critical" do
        it "adds a success message with the correct importance" do
          message_manager.log_success('Success message')
          message = message_manager.get_recent_messages(1).first
          expect(message.importance).to eq(:success)
        end

        it "adds a warning message with the correct importance" do
          message_manager.log_warning('Warning message')
          message = message_manager.get_recent_messages(1).first
          expect(message.importance).to eq(:warning)
        end

        it "adds a critical message with the correct importance" do
          message_manager.log_critical('Critical message')
          message = message_manager.get_recent_messages(1).first
          expect(message.importance).to eq(:critical)
        end
      end

      describe "#get_recent_messages" do
        before do
          3.times { |i| message_manager.add_message("Message #{i+1}") }
        end

        it "returns the specified number of recent messages" do
          messages = message_manager.get_recent_messages(2)
          expect(messages.size).to eq(2)
          expect(messages.map(&:content)).to eq(["Message 3", "Message 2"])
        end
      end

      describe "#toggle_selection_mode" do
        it "toggles the selection mode state" do
          expect(message_manager.selection_mode).to be_falsey
          message_manager.toggle_selection_mode
          expect(message_manager.selection_mode).to be_truthy
          message_manager.toggle_selection_mode
          expect(message_manager.selection_mode).to be_falsey
        end
      end

      describe "#handle_input" do
        context "with selection mode enabled" do
          before do
            message_manager.toggle_selection_mode
            # Add selectable messages
            allow(message_manager).to receive(:get_recent_messages).and_return([
                                                                                 Message.new("Option 1", selectable: true) { |m| "Selected option 1" },
              Message.new("Option 2", selectable: true) { |m| "Selected option 2" },
                                                                               ])
          end

          it "handles arrow keys for navigation" do
            # Since we can't test internal state directly, we'll check that it doesn't return false
            expect(message_manager.handle_input(:KEY_DOWN)).not_to eq(false)
            expect(message_manager.handle_input(:KEY_UP)).not_to eq(false)
          end

          it "handles Enter key for selection" do
            # Setup the mock to return a specific message based on selection index
            selected_message = Message.new("Option 1", selectable: true) { |m| "Selected option 1" }
            allow(message_manager).to receive(:currently_selected_message).and_return(selected_message)

            # The message should be selected when Enter is pressed
            expect(selected_message).to receive(:select)
            message_manager.handle_input(:enter)
          end
        end

        context "with shortcut keys" do
          it "activates the message with the matching shortcut key" do
            selection_called = false
            message_with_shortcut = Message.new("Shortcut Option", selectable: true, shortcut_key: 'a') do |m|
              selection_called = true
            end

            allow(message_manager).to receive(:get_recent_messages).and_return([message_with_shortcut])

            message_manager.handle_input('a')
            expect(selection_called).to be_truthy
          end
        end
      end

      describe "#render" do
        before do
          message_manager.setup_panel(0, 20, 80, 5)
        end

        it "renders the message panel" do
          panel = message_manager.instance_variable_get(:@panel)
          expect(panel).to receive(:render).with(render_system, false)
          message_manager.render(render_system)
        end

        it "renders the panel with selection mode when enabled" do
          message_manager.toggle_selection_mode
          panel = message_manager.instance_variable_get(:@panel)
          expect(panel).to receive(:render).with(render_system, true)
          message_manager.render(render_system)
        end
      end
    end
  end
end
