# frozen_string_literal: true

require 'io/console'
module Vanilla
  class KeyboardHandler
    def wait_for_input
      $stdin.raw { $stdin.getc }
    end

    # Input is read inside a `$stdin.raw` block, which restores the terminal
    # mode after each read, so there is nothing to tear down here.
    def cleanup; end
  end
end
