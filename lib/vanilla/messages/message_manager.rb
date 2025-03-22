module Vanilla
  module Messages
    class MessageManager
      attr_reader :selection_mode

      def initialize(logger, render_system)
        @logger = logger
        @render_system = render_system
        @message_log = MessageLog.new
        @message_panel = nil
        @selection_mode = false
        # Additional initialization as needed
      end

      def log_message(key, options = {})
        @message_log.add(key, options)
      end

      # Add method to log translated messages
      def log_translated(key, importance: :info, category: :system, **options)
        # Extract metadata if it's nested
        metadata = options.delete(:metadata) || options

        # Get the translated content with interpolation
        content = I18n.t(key, **metadata)

        # Create a new message with the content
        message = Message.new(
          content,
          category: category,
          importance: importance,
          metadata: metadata
        )
        @message_log.add_message(message)
      end

      # Toggle message selection mode on/off
      # @return [Boolean] The new selection mode state
      def toggle_selection_mode
        @selection_mode = !@selection_mode
        @logger.info("Message selection mode: #{@selection_mode ? 'ON' : 'OFF'}")

        # If entering selection mode, set initial selection
        if @selection_mode
          selectable_messages = @message_log.get_selectable_messages
          @message_log.current_selection_index = 0 if selectable_messages.any?
        else
          @message_log.current_selection_index = nil
        end

        @selection_mode
      end

      # Handle input for message system
      # @param key [String, Symbol] The input key or action
      # @return [Boolean] Whether the input was handled
      def handle_input(key)
        # Never intercept 'q' keys for quitting
        return false if key == 'q' || key == 'Q'

        return false unless @message_panel # No panel to interact with

        # If not in selection mode, only handle specific keys
        unless @selection_mode
          case key
          when '?', :help
            # Show help
            @logger.info("Message help requested")
            return true
          when 'm'
            # Toggle message history view
            toggle_selection_mode
            return true
          else
            # Don't handle movement keys like h, j, k, l when not in selection mode
            return false
          end
        end

        # In selection mode, handle navigation
        case key
        when :KEY_UP, 'k'
          # Navigate up in message history
          @message_panel.scroll_up
          return true
        when :KEY_DOWN, 'j'
          # Navigate down in message history
          @message_panel.scroll_down
          return true
        when :enter, "\r", "\n"
          # Select current message
          select_current_message
          return true
        when :escape, "\e", 'q'
          # Exit selection mode
          toggle_selection_mode
          return true
        else
          # Check for shortcut keys
          selectable_messages = @message_log.get_selectable_messages
          selectable_messages.each do |message|
            if message.has_shortcut? && message.shortcut_key == key
              message.select
              return true
            end
          end
          return false
        end
      end

      # Select the currently highlighted message
      # @return [Boolean] Whether a message was selected
      def select_current_message
        return false unless @selection_mode

        selectable_messages = @message_log.get_selectable_messages
        index = @message_log.current_selection_index
        return false unless index && selectable_messages[index]

        message = selectable_messages[index]
        message.select
        true
      end

      def setup_panel(x, y, width, height)
        @message_panel = MessagePanel.new(x, y, width, height, @message_log)
      end

      def render(render_system)
        @message_panel&.render(render_system, @selection_mode)
      end

      def get_recent_messages(limit = 10)
        @message_log.get_recent(limit)
      end

      def get_messages_by_category(category, limit = 10)
        @message_log.get_by_category(category, limit)
      end

      def clear_messages
        @message_log.clear
      end

      # Add a combat-related message
      # @param key [String, Symbol] The translation key
      # @param metadata [Hash] Interpolation values
      # @param importance [Symbol] Message importance
      def log_combat(key, metadata = {}, importance = :normal)
        log_translated(key,
                      category: :combat,
                      importance: importance,
                      metadata: metadata)
      end

      # Add a movement-related message
      # @param key [String, Symbol] The translation key
      # @param metadata [Hash] Interpolation values
      def log_movement(key, metadata = {})
        log_translated(key,
                      category: :movement,
                      importance: :info,
                      metadata: metadata)
      end

      # Add an item interaction message
      # @param key [String, Symbol] The translation key
      # @param metadata [Hash] Interpolation values
      # @param importance [Symbol] Message importance
      def log_item(key, metadata = {}, importance = :info)
        log_translated(key,
                      category: :item,
                      importance: importance,
                      metadata: metadata)
      end

      # Add an exploration-related message
      # @param key [String, Symbol] The translation key
      # @param metadata [Hash] Interpolation values
      # @param importance [Symbol] Message importance
      def log_exploration(key, metadata = {}, importance = :info)
        log_translated(key,
                      category: :exploration,
                      importance: importance,
                      metadata: metadata)
      end

      # Add a warning message
      # @param key [String, Symbol] The translation key
      # @param metadata [Hash] Interpolation values
      def log_warning(key, metadata = {})
        log_translated(key,
                      importance: :warning,
                      metadata: metadata)
      end

      # Add a critical message
      # @param key [String, Symbol] The translation key
      # @param metadata [Hash] Interpolation values
      def log_critical(key, metadata = {})
        log_translated(key,
                      importance: :critical,
                      metadata: metadata)
      end

      # Add a success/achievement message
      # @param key [String, Symbol] The translation key
      # @param metadata [Hash] Interpolation values
      def log_success(key, metadata = {})
        log_translated(key,
                      importance: :success,
                      metadata: metadata)
      end

      # Additional methods to manage message system
    end
  end
end
