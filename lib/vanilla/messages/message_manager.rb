# frozen_string_literal: true
module Vanilla
  module Messages
    class MessageManager
      attr_reader :selection_mode

      def initialize(logger, render_system)
        @logger = logger
        @render_system = render_system
        @message_log = MessageLog.new(logger)
        @panel = nil
        @selection_mode = false
        @selection_index = 0
      end

      # Log a message with the translation key
      def log_message(key, options = {})
        @message_log.add(key, options)
      end

      # Add method to log translated messages
      def log_translated(key, importance: :normal, category: :system, **options)
        # Extract metadata if it's nested
        metadata = options.delete(:metadata) || options

        # Create a new message with the content and translation key
        message = Message.new(
          key,
          category: category,
          importance: importance,
          metadata: metadata
        )

        @message_log.add_message(message)
        message
      end

      # Add a message directly
      def add_message(content, options = {})
        message = Message.new(
          content,
          category: options[:category] || :system,
          importance: options[:importance] || :normal,
          metadata: options[:metadata] || {}
        )

        @message_log.add_message(message)
        message
      end

      # Toggle message selection mode on/off
      # @return [Boolean] The new selection mode state
      def toggle_selection_mode
        @selection_mode = !@selection_mode
        @logger.info("Message selection mode: #{@selection_mode ? 'ON' : 'OFF'}")

        # Reset selection index when toggling
        @selection_index = 0 if @selection_mode

        @selection_mode
      end

      # Handle user input for message selection and interaction
      # @param key [Symbol, String] The key pressed by the user
      # @return [Boolean] Whether the input was handled
      def handle_input(key)
        # Never intercept 'q' keys for quitting
        return false if key == 'q' || key == 'Q'

        # Handle shortcut keys for messages with shortcuts
        if !@selection_mode && key.is_a?(String) && key.length == 1
          # First try from get_recent_messages for test compatibility
          selectable_messages = get_recent_messages

          # Find a message with matching shortcut key
          message_with_shortcut = selectable_messages.find do |m|
            m.selectable? && m.has_shortcut? && m.shortcut_key == key
          end

          if message_with_shortcut
            result = message_with_shortcut.select
            return true
          end
        end

        # Handle navigation in selection mode
        if @selection_mode
          case key
          when :KEY_UP, :KEY_LEFT, 'k', 'h'
            navigate_selection(-1)
            return true
          when :KEY_DOWN, :KEY_RIGHT, 'j', 'l'
            navigate_selection(1)
            return true
          when :enter, "\r", ' '
            return select_current_message
          when :escape, "\e"
            toggle_selection_mode
            return true
          end
        end

        # If we got here, input wasn't handled
        false
      end

      # Get the currently selected message
      def currently_selected_message
        selectable_messages = @message_log.get_selectable_messages
        return nil if selectable_messages.empty?

        # Ensure index is within bounds
        @selection_index = @selection_index.clamp(0, selectable_messages.size - 1)
        selectable_messages[@selection_index]
      end

      # Select the currently highlighted message
      def select_current_message
        return false unless @selection_mode

        message = currently_selected_message
        return false unless message

        message.select
        true
      end

      # Set up the message panel with the specified dimensions
      def setup_panel(x, y, width, height)
        @panel = MessagePanel.new(x, y, width, height, @message_log)
      end

      # Render the message panel
      def render(render_system)
        if $DEBUG
          puts "DEBUG: Rendering message panel, selection mode: #{@selection_mode}"
        end

        return unless @panel

        @panel.render(render_system, @selection_mode)
      end

      # Get recent messages from the log
      def get_recent_messages(limit = 10)
        @message_log.get_recent(limit)
      end

      # Get messages by category
      def get_messages_by_category(category, limit = 10)
        @message_log.get_by_category(category, limit)
      end

      # Clear all messages
      def clear_messages
        @message_log.clear
      end

      #
      # Convenience methods for different message types
      #

      # Log a combat message
      def log_combat(key, metadata = {}, importance = :normal)
        log_translated(key,
                       category: :combat,
                       importance: importance,
                       metadata: metadata
        )
      end

      # Log a movement message
      def log_movement(key, metadata = {})
        log_translated(key,
                       category: :movement,
                       importance: :normal,
                       metadata: metadata
        )
      end

      # Log an item-related message
      def log_item(key, metadata = {}, importance = :info)
        log_translated(key,
                       category: :item,
                       importance: importance,
                       metadata: metadata
        )
      end

      # Log an exploration message
      def log_exploration(key, metadata = {}, importance = :info)
        log_translated(key,
                       category: :exploration,
                       importance: importance,
                       metadata: metadata
        )
      end

      # Log a warning message
      def log_warning(key, metadata = {})
        log_translated(key,
                       category: :system,
                       importance: :warning,
                       metadata: metadata
        )
      end

      # Log a critical message
      def log_critical(key, metadata = {})
        log_translated(key,
                       category: :system,
                       importance: :critical,
                       metadata: metadata
        )
      end

      # Log a success message
      def log_success(key, metadata = {})
        log_translated(key,
                       category: :system,
                       importance: :success,
                       metadata: metadata
        )
      end

      private

      # Navigate through selectable messages
      def navigate_selection(direction)
        selectable_messages = @message_log.get_selectable_messages
        return if selectable_messages.empty?

        @selection_index = (@selection_index + direction) % selectable_messages.size
        @logger.debug("Selection index: #{@selection_index} (#{selectable_messages.size} selectable)")
      end
    end
  end
end
