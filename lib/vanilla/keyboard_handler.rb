# frozen_string_literal: true

require 'io/console'
module Vanilla
  class KeyboardHandler
    def wait_for_input
      $stdin.raw { $stdin.getc }
    end
  end
end
