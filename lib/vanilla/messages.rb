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
  end
end