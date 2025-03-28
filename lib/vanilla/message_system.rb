# frozen_string_literal: true

# Main entry point for the message system
# This file requires all individual message system components

require_relative 'messages/message'
require_relative 'messages/message_log'
require_relative 'messages/message_panel'
require_relative 'messages/message_manager'

module Vanilla
  module Messages
    # This module contains the message system for the game
    # The message system is responsible for displaying messages to the player
    # and providing a way to browse through message history.

    # MessageSystem serves as a facade for the message subsystem
    # TODO: Separete Concerns: MessageSystem and MessageSystemFacade?
    # This follows the Facade pattern to provide a simplified interface
    class MessageSystem
      attr_reader :manager

      def initialize(logger = Vanilla::Logger.instance, render_system)
        @logger = logger

        @logger.warn('[Vanilla::MessageSystem] DEPRECATED: Use Vanilla::Systems::MessageSystem instead')
        @logger.warn('[Vanilla::MessageSystem] DEPRECATED: Use Vanilla::Systems::MessageSystem instead')

        @manager = MessageManager.new(logger, render_system)

        # Register this system in the service registry
        Vanilla::ServiceRegistry.register(:message_system, self)
      end

      # Set up the message panel with the given dimensions
      def setup_panel(x, y, width, height)
        @manager.setup_panel(x, y, width, height)
      end

      # Render the message panel
      def render(render_system)
        @manager.render(render_system)
      end

      # Log a message with the given translation key
      def log_message(key, options = {})
        @manager.log_translated(key, **options)
      end

      # Log a success message
      def log_success(key, metadata = {})
        @manager.log_success(key, metadata)
      end

      # Log a warning message
      def log_warning(key, metadata = {})
        @manager.log_warning(key, metadata)
      end

      # Log a critical message
      def log_critical(key, metadata = {})
        @manager.log_critical(key, metadata)
      end

      # Get recent messages
      def get_recent_messages(limit = 10)
        @manager.get_recent_messages(limit)
      end

      # Handle user input
      def handle_input(key)
        @manager.handle_input(key)
      end

      # Toggle selection mode
      def toggle_selection_mode
        @manager.toggle_selection_mode
      end

      # Check if in selection mode
      def selection_mode?
        @manager.selection_mode
      end

      # Get the service instance - implementing Service Locator
      def self.instance
        Vanilla::ServiceRegistry.get(:message_system)
      end

      # Clean up resources - called when the game ends
      def cleanup
        Vanilla::ServiceRegistry.unregister(:message_system)
      end
    end
  end
end
