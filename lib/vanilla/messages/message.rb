# frozen_string_literal: true

module Vanilla
  module Messages
    # Message represents a single message in the game's message log.
    # It supports translation through I18n, selectable options, and shortcut keys.
    class Message
      attr_reader :content, :category, :importance, :turn, :timestamp, :metadata
      attr_accessor :selectable, :selection_callback, :shortcut_key

      # Initialize a new message
      # @param content [String, Symbol] The message text or translation key
      # @param category [Symbol] Category of the message (e.g., :combat, :item, :system)
      # @param importance [Symbol] Importance level affecting display (:normal, :warning, :critical, :success)
      # @param turn [Integer, nil] Game turn when the message was created (defaults to current turn)
      # @param metadata [Hash] Additional data for translation interpolation or message context
      # @param selectable [Boolean] Whether the message is selectable for interaction
      # @param shortcut_key [String, nil] Single-key shortcut for direct selection (optional)
      # @param turn_provider [Proc] Optional proc that provides the current turn number
      # @yield [Message] Called when the message is selected, if selectable
      def initialize(content, category: :system, importance: :normal,
                     turn: nil, metadata: {}, selectable: false,
                     shortcut_key: nil, turn_provider: -> { Vanilla.game_turn rescue 0 },
                     &selection_callback)
        @content = content
        @category = category
        @importance = importance
        @turn = turn || turn_provider.call
        @timestamp = Time.now
        @metadata = metadata
        @selectable = selectable
        @shortcut_key = shortcut_key
        @selection_callback = selection_callback if block_given?
      end

      # Check if the message is selectable
      # @return [Boolean] true if the message is selectable
      def selectable?
        @selectable
      end

      # Activate the message's selection callback if it's selectable
      # @return [Object] The result of the callback, or nil if not selectable
      def select
        @selection_callback&.call(self) if @selectable
      end

      # Check if the message has a shortcut key
      # @return [Boolean] true if the message has a shortcut key
      def has_shortcut?
        !@shortcut_key.nil?
      end

      # Get the translated text of the message
      # If the text is a symbol, it will be translated using I18n
      # @return [String] The translated text
      def translated_text
        return @content unless @content.is_a?(Symbol) || @content.is_a?(String) && @content.include?('.')

        # Handle translation with interpolation values from metadata
        key = @content.is_a?(Symbol) ? @content.to_s : @content
        I18n.t(key, default: key, **@metadata)
      end
    end
  end
end
