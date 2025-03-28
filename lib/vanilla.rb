# frozen_string_literal: true

STDOUT.sync = true

require 'pry'
require 'logger'
require 'securerandom'
require 'i18n'

module Vanilla
  # New ECS Framework
  require_relative 'vanilla/world'
  require_relative 'vanilla/keyboard_handler'
  require_relative 'vanilla/display_handler'
  require_relative 'vanilla/entity_factory'
  require_relative 'vanilla/game'

  # Systems
  require_relative 'vanilla/systems'

  # game
  require_relative 'vanilla/input_handler'
  require_relative 'vanilla/logger'
  require_relative 'vanilla/level'

  # map
  require_relative 'vanilla/map_utils'
  require_relative 'vanilla/map'

  # renderers
  require_relative 'vanilla/renderers'

  # algorithms
  require_relative 'vanilla/algorithms'

  # support
  require_relative 'vanilla/support/tile_type'

  # components (entity component system)
  require_relative 'vanilla/components'

  # entities
  require_relative 'vanilla/entities'

  # event system
  require_relative 'vanilla/events'

  # inventory system
  require_relative 'vanilla/inventory'

  # Setup I18n if it hasn't been set up already (like in tests)
  if I18n.load_path.empty?
    I18n.load_path += Dir[File.expand_path('../config/locales/*.yml', __dir__)]
    I18n.default_locale = :en
  end

  # Have a seed for the random number generator
  # This is used to generate the same map for the same seed
  # This is useful for testing
  $seed = nil

  # Service registry to replace global variables
  # Implementation of Service Locator pattern
  class ServiceRegistry
    @@services = {}

    def self.register(key, service)
      @@services[key] = service
    end

    def self.get(key)
      @@services[key]
    end

    def self.unregister(key)
      @@services.delete(key)
    end

    def self.clear
      @@services.clear
    end
  end

  # Get the current game turn
  # @return [Integer] The current game turn or 0 if the game is not running
  def self.game_turn
    game = ServiceRegistry.get(:game)
    game&.turn || 0
  end

  # Get the current event manager
  # @return [EventManager] The current event manager or nil if not available
  def self.event_manager
    game = ServiceRegistry.get(:game)
    game&.instance_variable_get(:@event_manager)
  end

  # Game class implements the core game loop pattern and orchestrates the game's
  # main components. It manages the game lifecycle from initialization to cleanup.
  #
  # The Game Loop pattern provides a way to:
  # 1. Process player input
  # 2. Update game state
  # 3. Render the updated state
  # 4. Repeat until the game ends
  #
  # This implementation uses a turn-based approach appropriate for roguelike games,
  # where updates happen in discrete steps rather than in real-time.

  class Scheduler
    def initialize
      @entities = []
    end

    def register(entity)
      @entities << entity
    end

    def unregister(entity)
      @entities.delete(entity)
    end

    def update
      @entities.each { |entity| entity.update }
    end
  end

  # Entry point for starting the game
  # Creates a new Game instance and manages its lifecycle
  # @return [void]
  def self.run
    # Skip game initialization in test mode
    return if ENV['VANILLA_TEST_MODE'] == 'true'

    game = Game.new
    begin
      game.start
    ensure
      game.cleanup
    end
  end
end
