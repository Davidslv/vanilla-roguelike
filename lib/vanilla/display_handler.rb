# frozen_string_literal: true

module Vanilla
  class DisplayHandler
    attr_reader :keyboard_handler

    def initialize
      @keyboard_handler = Vanilla::KeyboardHandler.new
    end

    def cleanup
      @keyboard_handler.cleanup
    end
  end
end
