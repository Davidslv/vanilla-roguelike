module Vanilla
  # Handles keyboard input for the game
  class KeyboardHandler
    def initialize
      @pressed_keys = {}
    end

    # Check if a key is currently pressed
    # @param key [Symbol] The key to check
    # @return [Boolean] True if the key is pressed
    def key_pressed?(key)
      @pressed_keys[key] || false
    end

    # Set a key's pressed state
    # @param key [Symbol] The key to set
    # @param pressed [Boolean] Whether the key is pressed
    def set_key_pressed(key, pressed)
      @pressed_keys[key] = pressed
    end

    # Clear all pressed keys
    def clear
      @pressed_keys.clear
    end
  end
end