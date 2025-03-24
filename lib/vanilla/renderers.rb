# frozen_string_literal: true

module Vanilla
  # The Renderers module provides interfaces and implementations for different
  # rendering approaches in the Vanilla game.
  #
  # This module uses Ruby's `autoload` instead of `require_relative` for lazy loading:
  # - Files are only loaded when their corresponding constants are first accessed
  # - This improves startup performance by deferring loading until needed
  # - Helps avoid circular dependencies by delaying actual loading
  # - Reduces memory usage by not loading renderers that aren't used
  # - Makes it easier to extend with new renderers in the future
  #
  # The `File.expand_path` with `__dir__` ensures paths are resolved correctly
  # regardless of the current working directory when the code is executed.
  module Renderers
    # Load rendering-related code
    autoload :Renderer, File.expand_path('renderers/renderer', __dir__)
    autoload :TerminalRenderer, File.expand_path('renderers/terminal_renderer', __dir__)
  end
end
