# lib/keyboard_handler.rb
require 'io/console'

class KeyboardHandler
  def wait_for_input
    $stdin.raw { $stdin.getc }
  end
end
