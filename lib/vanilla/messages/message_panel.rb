module Vanilla
  module Messages
    # Panel for displaying messages beneath the map
    class MessagePanel
      attr_reader :x, :y, :width, :height, :message_log

      # Initialize a new message panel
      # @param x [Integer] X coordinate (column) for top-left corner
      # @param y [Integer] Y coordinate (row) for top-left corner
      # @param width [Integer] Width of the panel
      # @param height [Integer] Height of the panel (number of visible messages)
      # @param message_log [MessageLog] The message log to display
      def initialize(x, y, width, height, message_log)
        @x = x
        @y = y
        @width = width
        @height = height
        @message_log = message_log
        @scroll_offset = 0
      end

      # Render the message panel
      # @param renderer [Vanilla::Renderers::Renderer] The renderer to use
      # @param selection_mode [Boolean] Whether the game is in message selection mode
      def render(renderer, selection_mode = false)
        return unless renderer.respond_to?(:draw_character)

        # Debug output to verify rendering is being called
        puts "DEBUG: Rendering message panel with #{@message_log.messages.size} messages" if $DEBUG

        # Draw a separator line above the message panel
        draw_separator_line(renderer)

        # Get messages to display with scroll offset
        messages = @message_log.get_recent(@height + @scroll_offset)

        # Add a default message if no messages exist
        if messages.nil? || messages.empty?
          default_msg = "Welcome to Vanilla! Use movement keys to navigate."
          default_msg.each_char.with_index do |char, i|
            renderer.draw_character(@y + 1, @x + i, char)
          end
          return
        end

        visible_messages = messages[@scroll_offset, @height] || []

        # Force visibility with a marker
        renderer.draw_character(@y, @x, "#")

        # Draw messages directly using draw_character
        visible_messages.each_with_index do |message, idx|
          y_pos = @y + idx + 1

          # Handle both Message objects and hash-based messages
          if message.is_a?(Message)
            render_message_object(renderer, message, y_pos)
          else
            render_hash_message(renderer, message, y_pos)
          end
        end

        # Draw message count indicator
        draw_message_count(renderer, visible_messages.size)
      end

      # Scroll the panel up
      # @return [Integer] The new scroll offset
      def scroll_up
        # Increment offset to show older messages
        max_scroll = [@message_log.messages.size - @height, 0].max
        @scroll_offset = [(@scroll_offset + 1), max_scroll].min
      end

      # Scroll the panel down
      # @return [Integer] The new scroll offset
      def scroll_down
        # Decrement offset to show newer messages
        @scroll_offset = [(@scroll_offset - 1), 0].max
      end

      private

      # Render a Message object
      # @param renderer [Vanilla::Renderers::Renderer] The renderer to use
      # @param message [Message] The message object to render
      # @param y_pos [Integer] The y position to render at
      def render_message_object(renderer, message, y_pos)
        # If the message is selectable, add an indicator
        x_offset = 0

        if message.selectable?
          # Determine if this message is selected
          is_selected = false
          if @message_log.current_selection_index
            selectable_messages = @message_log.get_selectable_messages
            is_selected = selectable_messages[@message_log.current_selection_index] == message
          end

          # Show selection indicator (* or >)
          indicator = is_selected ? ">" : "*"
          renderer.draw_character(y_pos, @x, indicator, :cyan)
          x_offset += 1

          # If it has a shortcut key, show it
          if message.has_shortcut?
            shortcut_text = "#{message.shortcut_key})"
            shortcut_text.each_char.with_index do |char, char_idx|
              renderer.draw_character(y_pos, @x + x_offset + char_idx, char, :cyan)
            end
            x_offset += shortcut_text.length
          end

          # Add a space after indicators
          x_offset += 1
        end

        # Draw message text
        text = format_message_object(message, @width - x_offset)
        color = get_color_for_message(message)

        text.each_char.with_index do |char, char_idx|
          renderer.draw_character(y_pos, @x + char_idx + x_offset, char, color)
        end
      end

      # Render a hash-based message
      # @param renderer [Vanilla::Renderers::Renderer] The renderer to use
      # @param message [Hash] The message hash to render
      # @param y_pos [Integer] The y position to render at
      def render_hash_message(renderer, message, y_pos)
        # Draw message text
        text = message[:text].to_s
        text = text.length > @width ? text[0...(@width-3)] + "..." : text

        # Get color based on importance and category
        color = get_color_for_hash_message(message)

        text.each_char.with_index do |char, char_idx|
          renderer.draw_character(y_pos, @x + char_idx + 1, char, color)
        end
      end

      # Get color for a hash-based message
      # @param message [Hash] The message hash
      # @return [Symbol] Color to use
      def get_color_for_hash_message(message)
        # First check importance
        importance = message[:importance] || :normal
        category = message[:category] || :system

        case importance
        when :critical, :danger
          :red
        when :warning
          :yellow
        when :success
          :green
        else
          # Then check category
          case category
          when :combat
            :red
          when :item
            :green
          when :movement
            :cyan
          when :exploration
            :blue
          else
            :white
          end
        end
      end

      # Format a Message object for display, handling truncation
      # @param message [Message] The message to format
      # @param max_width [Integer] Maximum width for the message text
      # @return [String] The formatted message text
      def format_message_object(message, max_width)
        text = message.translated_text.to_s
        # Truncate to fit panel width
        text.length > max_width ? text[0...(max_width-3)] + "..." : text
      end

      # Format a message for display, handling truncation
      # @param message [Message] The message to format
      # @param max_width [Integer] Maximum width for the message text
      # @return [String] The formatted message text
      def format_message(message, max_width)
        if message.is_a?(Message)
          format_message_object(message, max_width)
        else
          text = message[:text].to_s
          # Truncate to fit panel width
          text.length > max_width ? text[0...(max_width-3)] + "..." : text
        end
      end

      # Draw a separator line at the top of the message panel
      # @param renderer [Vanilla::Renderers::Renderer] The renderer to use
      def draw_separator_line(renderer)
        (width + 2).times do |i|
          renderer.draw_character(@y, @x + i, "-")
        end
      end

      # Draw a message count indicator
      # @param renderer [Vanilla::Renderers::Renderer] The renderer to use
      # @param visible_count [Integer] The number of visible messages
      def draw_message_count(renderer, visible_count)
        count_text = "[#{visible_count}/#{@message_log.messages.size}]"
        count_text.each_char.with_index do |char, i|
          renderer.draw_character(@y, @x + width - count_text.length + i, char)
        end
      end

      # Get appropriate color for a message based on category and importance
      # @param message [Message] The message to color
      # @return [Symbol] The color symbol to use
      def get_color_for_message(message)
        # First check importance for critical/warning messages
        case message.importance
        when :critical, :danger
          :red
        when :warning
          :yellow
        when :success
          :green
        else
          # Then check category for normal importance messages
          case message.category
          when :combat
            :red
          when :item
            :green
          when :movement
            :cyan
          when :exploration
            :blue
          else
            :white
          end
        end
      end
    end
  end
end