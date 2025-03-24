# frozen_string_literal: true
module Vanilla
  module Messages
    class MessageLog
      attr_reader :messages, :history_size

      DEFAULT_CATEGORIES = [:system, :combat, :movement, :item, :story, :debug]

      def initialize(logger, history_size: 120)
        @logger = logger
        @messages = []
        @history_size = history_size
        @formatters = {}
        @current_selection_index = nil
        @observers = []

        # Initialize default formatters
        register_default_formatters
      end

      # Observer pattern methods
      def add_observer(observer)
        @observers << observer unless @observers.include?(observer)
      end

      def remove_observer(observer)
        @observers.delete(observer)
      end

      def notify_observers
        @observers.each { |observer| observer.update }
      end

      # Get the current game turn instead of directly accessing the global
      def current_game_turn
        Vanilla.game_turn rescue 0
      end

      # Add a message using a translation key
      def add(key, options = {}, turn_provider = method(:current_game_turn))
        # Extract category and importance from options
        category = options.delete(:category) || :system
        importance = options.delete(:importance) || :normal

        # Create a new Message object with the content
        message = Message.new(
          key,
          category: category,
          importance: importance,
          metadata: options
        )

        add_message(message)
        message
      end

      # Add a pre-constructed message object
      def add_message(message)
        return unless message.is_a?(Message)

        # Add to message list
        @messages.unshift(message)

        # Trim history if needed
        @messages.pop if @messages.size > @history_size

        # Notify observers that a message was added
        notify_observers

        message
      end

      # Get messages by category
      def get_by_category(category, limit = 10)
        @messages.select { |m| m.category == category }.take(limit)
      end

      # Get messages by importance level
      def get_by_importance(importance, limit = 10)
        @messages.select { |m| m.importance == importance }.take(limit)
      end

      # Get recent messages
      def get_recent(limit = 10)
        @messages.take(limit)
      end

      # Get selectable messages
      def get_selectable_messages
        @messages.select { |m| m.respond_to?(:selectable?) && m.selectable? }
      end

      # Register a formatter for a specific category
      def register_formatter(name, formatter)
        @formatters[name] = formatter
      end

      # Clear all messages
      def clear
        @messages.clear
        notify_observers
      end

      private

      def register_default_formatters
        # Register formatters for different message types
        register_formatter(:combat, ->(message) {
          # Format combat messages (highlighting damage numbers, etc)
          message
        })

        # Add more formatters as needed
      end

      def apply_formatters(message)
        if message.is_a?(Message)
          formatter = @formatters[message.category]
          return message unless formatter

          formatter.call(message)
        else
          message
        end
      end
    end
  end
end
