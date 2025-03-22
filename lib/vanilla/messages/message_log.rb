module Vanilla
  module Messages
    class MessageLog
      attr_reader :messages, :history_size

      DEFAULT_CATEGORIES = [:system, :combat, :movement, :item, :story, :debug]

      def initialize(history_size: 120)
        @messages = []
        @history_size = history_size
        @formatters = {}
        @current_selection_index = nil

        # Initialize default formatters
        register_default_formatters
      end

      # Add a message using a translation key
      def add(key, options = {})
        text = I18n.t("messages.#{key}", options)
        category = options[:category] || :system
        importance = options[:importance] || :normal
        timestamp = Time.now

        message = {
          text: text,
          category: category,
          importance: importance,
          timestamp: timestamp,
          metadata: options[:metadata] || {}
        }

        # Apply formatters
        message = apply_formatters(message)

        # Add to message list
        @messages.unshift(message)

        # Trim history if needed
        @messages.pop if @messages.size > @history_size

        message
      end

      # Add a Message object directly to the log
      def add_message(message)
        return unless message.is_a?(Message)

        # Apply formatters to Message objects too
        message = apply_formatters(message)

        # Add to the beginning of the message list
        @messages.unshift(message)

        # Trim history if needed
        @messages.pop if @messages.size > @history_size

        message
      end

      def get_by_category(category, limit = 10)
        @messages.select { |m| m[:category] == category || m.respond_to?(:category) && m.category == category }.take(limit)
      end

      def get_recent(limit = 10)
        @messages.take(limit)
      end

      # Get all selectable messages
      def get_selectable_messages
        @messages.select { |m| m.respond_to?(:selectable?) && m.selectable? }
      end

      # Current selected message index for UI navigation
      attr_accessor :current_selection_index

      def register_formatter(name, formatter)
        @formatters[name] = formatter
      end

      def clear
        @messages.clear
      end

      private

      def register_default_formatters
        # Register formatters for different message types
        register_formatter(:combat, ->(message) {
          if message.is_a?(Message)
            # For Message objects, handle translated_text with string manipulation
            orig_text = message.instance_variable_get(:@content)
            # If it's just a string and not a translation key, we can format it
            unless orig_text.is_a?(Symbol) || (orig_text.is_a?(String) && orig_text.include?('.'))
              message.instance_variable_set(:@content, orig_text.gsub(/(\d+)/) { |m| "*#{m}*" })
            end
          else
            # For hash-based messages
            message[:text] = message[:text].gsub(/(\d+)/) { |m| "*#{m}*" }
          end
          message
        })

        # ... more formatters
      end

      def apply_formatters(message)
        if message.is_a?(Message)
          category = message.category
        else
          category = message[:category]
        end

        formatter = @formatters[category]
        return message unless formatter

        formatter.call(message)
      end
    end
  end
end