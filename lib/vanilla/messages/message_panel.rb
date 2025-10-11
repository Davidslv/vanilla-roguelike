# frozen_string_literal: true

module Vanilla
  module Messages
    # The MessagePanel class displays a panel of messages beneath the game map in a roguelike game.
    # It shows recent messages (e.g., "You moved to (3, 5)") and, in selection mode, options for the player
    # to choose from (e.g., "1) Attack Monster"). The panel supports scrolling to view older messages and
    # uses a renderer to draw to the screen. It observes the message log for updates, ensuring the display
    # stays current with the game state.

    class MessagePanel
      # Color mappings for importance and category (shared between methods)
      IMPORTANCE_COLORS = {
        critical: :red,
        danger: :red,
        warning: :yellow,
        success: :green
      }.freeze

      CATEGORY_COLORS = {
        combat: :red,
        item: :green,
        movement: :cyan,
        exploration: :blue,
        system: :white
      }.freeze

      attr_reader :x, :y, :width, :height, :message_log

      # --- Initialization ---
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

        # Register as an observer of the message log to get updates
        @message_log.add_observer(self) if @message_log.respond_to?(:add_observer)
      end

      # --- Core Lifecycle Methods ---
      def render(renderer, selection_mode = false)
        # Adjust the width to account for borders (| on each side), so the content fits inside
        # Currently this is manually set to 5 to account for the borders and padding.
        width_adjusted = @width - 5

        # Draw the top border: a + followed by dashes (e.g., +------+) to frame the panel
        puts "+#{'-' * width_adjusted}+"

        # Get the current game turn (e.g., 42) to show in the header
        turn = Vanilla.game_turn

        # Create the header text, e.g., "Messages (Turn 42):"
        header = "Messages (Turn #{turn}):"

        # Calculate padding to right-align the header within the adjusted width
        # - 1 for the padding accounting the pipe character to be aligned with the top border.
        padding = width_adjusted - header.length - 1

        # Draw the header line, e.g., "| Messages (Turn 42):    |" (padded with spaces)
        puts "| #{header}#{' ' * padding}|"

        # Determine how many messages to show: reduce height by 2 (for header and bottom border),
        # or by 3 if in selection mode (to make room for options)
        visible_message_count = @height - (selection_mode ? 3 : 2)

        # Get the most recent messages from the log, limited to the visible count
        messages = @message_log.get_recent(visible_message_count)

        # For each message, draw a line with the message text
        messages.each do |msg|
          # Format the message: prefix with "- " and truncate to fit within the width
          # (subtract 3 to account for "- " and potential "...")
          text = "- #{msg.translated_text[0..width_adjusted - 3]}"

          # Pad the text to the adjusted width with spaces for consistent alignment
          text = text.ljust(width_adjusted)

          # Draw the message line, e.g., "| - You moved to (3, 5)  |"
          puts "| #{text}|"
        end

        # If in selection mode, show a menu of options for the player to choose from
        if selection_mode
          # Draw a separator line for the options section, e.g., "| Options:    |"
          puts "| Options:#{' ' * (width_adjusted - 8)}|"

          # Check if there are any options to display
          if @message_log.options.empty?
            # If no options, show a message indicating how to close the menu
            text = "No options available, press 'm' to close".ljust(width_adjusted)
            puts "| #{text}|"
          else
            # For each option, draw a line with the option key and content
            @message_log.options.each do |opt|
              # Format the option, e.g., "1) Attack Monster", truncated to fit
              text = "#{opt[:key]}) #{opt[:content][0..width_adjusted - 4]}".ljust(width_adjusted)
              puts "| #{text}|"
            end

            # Always show a "Close Menu" option, e.g., "m) Close Menu"
            text = "m) Close Menu".ljust(width_adjusted)
            puts "| #{text}|"
          end
        end

        # Draw the bottom border, matching the top: +------+
        puts "+#{'-' * width_adjusted}+"
      end

      def cleanup
        @message_log.remove_observer(self) if @message_log.respond_to?(:remove_observer)
      end

      # --- Interaction Methods ---
      def update
        # No-op: panel updates on next render (Observer pattern)
      end

      def scroll_up
        # Increment offset to show older messages
        max_scroll = [@message_log.messages.size - @height, 0].max
        @scroll_offset = [(@scroll_offset + 1), max_scroll].min
      end

      def scroll_down
        # Decrement offset to show newer messages
        @scroll_offset = [(@scroll_offset - 1), 0].max
      end

      # --- Private Implementation Details ---
      private

      def render_message_object(renderer, message, y_pos)
        x_offset = 0
        if message.selectable?
          is_selected = @message_log.current_selection_index &&
                        @message_log.get_selectable_messages[@message_log.current_selection_index] == message
          indicator = is_selected ? ">" : "*"
          renderer.draw_character(y_pos, @x, indicator, :cyan)
          x_offset += 1

          if message.has_shortcut?
            shortcut_text = "#{message.shortcut_key})"
            shortcut_text.each_char.with_index do |char, char_idx|
              renderer.draw_character(y_pos, @x + x_offset + char_idx, char, :cyan)
            end
            x_offset += shortcut_text.length
          end

          x_offset += 1
        end

        text = format_message_object(message, @width - x_offset)
        color = get_color_for_message(message)
        text.each_char.with_index do |char, char_idx|
          renderer.draw_character(y_pos, @x + char_idx + x_offset, char, color)
        end
      end

      def render_hash_message(renderer, message, y_pos)
        text = format_hash_message(message, @width)
        color = get_color_for_hash_message(message)
        text.each_char.with_index do |char, char_idx|
          renderer.draw_character(y_pos, @x + char_idx, char, color)
        end
      end

      def draw_separator_line(renderer)
        renderer.draw_character(@y, @x, "+")
        width.times do |i|
          char = (i % 2 == 0) ? "=" : "-"
          renderer.draw_character(@y, @x + i + 1, char)
        end
        renderer.draw_character(@y, @x + width + 1, "+")
      end

      def draw_message_count(renderer, visible_count)
        count_text = "**[#{visible_count}/#{@message_log.messages.size}]**"
        count_text.each_char.with_index do |char, i|
          renderer.draw_character(@y, @x + width - count_text.length + i, char)
        end
      end

      def format_message_object(message, max_width)
        text = message.translated_text.to_s
        prefix = case message.importance
                 when :critical then "!! "
                 when :warning then "* "
                 when :success then "+ "
                 else "> "
                 end
        prefixed_text = prefix + text
        prefixed_text.length > max_width ? prefixed_text[0...(max_width - 3)] + "..." : prefixed_text
      end

      def format_hash_message(message, max_width)
        text = message[:text].to_s
        prefix = case message[:importance]
                 when :critical, :danger then "!! "
                 when :warning then "* "
                 when :success then "+ "
                 else "> "
                 end
        prefixed_text = prefix + text
        prefixed_text.length > max_width ? prefixed_text[0...(max_width - 3)] + "..." : prefixed_text
      end

      def get_color_for_message(message)
        # Check if the importance has a specific color
        importance_color = IMPORTANCE_COLORS[message.importance]
        return importance_color if importance_color

        # Otherwise, use the category color, defaulting to :white if not found
        CATEGORY_COLORS[message.category] || :white
      end

      def get_color_for_hash_message(hash_message)
        # Extract importance and category, defaulting to :normal and :system
        importance = hash_message[:importance] || :normal
        category = hash_message[:category] || :system

        # Check if the importance has a specific color
        importance_color = IMPORTANCE_COLORS[importance]
        return importance_color if importance_color

        # Otherwise, use the category color, defaulting to :white if not found
        CATEGORY_COLORS[category] || :white
      end
    end
  end
end
