# frozen_string_literal: true

module Vanilla
  module Messages
    class MessageLog
      attr_reader :messages, :history_size

      DEFAULT_CATEGORIES = [:system, :combat, :movement, :item, :story, :debug]

      def initialize(history_size: 20)
        @logger = Vanilla::Logger.instance
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

      # Get the current game turn instead of directly accessing the global
      def current_game_turn
        Vanilla.game_turn rescue 0
      end

      # Add a message with options
      def add_message(message)
        return unless message.is_a?(Message)

        @messages.unshift(message)
        @messages.pop if @messages.size > @history_size

        notify_observers

        message
      end

      # Add a message using a key or text
      def add(key, options = {})
        category = options.delete(:category) || :system
        importance = options.delete(:importance) || :normal
        opts = options.delete(:options) || []
        metadata = options

        message = Message.new(
          key,
          category: category,
          importance: importance,
          turn: current_game_turn,
          options: opts,
          metadata: metadata
        )
        add_message(message)
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

      # Fetch current options from all messages
      def options
        @messages.flat_map(&:options)
      end

      # Clear all messages
      def clear
        @messages.clear
        notify_observers
      end

      # Register a formatter for a specific category
      def register_formatter(name, formatter)
        @formatters[name] = formatter
      end

      private

      def notify_observers
        @observers.each { |observer| observer.update }
      end

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
