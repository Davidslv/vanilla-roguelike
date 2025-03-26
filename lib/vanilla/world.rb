# frozen_string_literal: true

module Vanilla
  # The World class is the central container for all entities and systems.
  # It manages entities, systems, events, and commands.
  #
  # World acts as a coordinator, not a decision-maker.
  #  It runs systems in order (update loop) and provides access to entities/components.

  class World
    attr_reader :entities, :systems, :display, :current_level
    attr_accessor :quit

    # Initialize a new world
    def initialize
      @entities = {}
      @systems = []

      @quit = false

      @display = DisplayHandler.new
      @logger = Vanilla::Logger.instance

      @current_level = nil
      @level_changed = false

      @event_subscribers = Hash.new { |h, k| h[k] = [] }
      @event_queue = Queue.new
      @command_queue = Queue.new
    end

    def quit?
      @logger.debug("[World#quit?] quit: #{@quit}")
      @quit
    end

    # Check if the level changed this frame (resets after checking)
    def level_changed?
      changed = @level_changed
      @level_changed = false # Reset after querying
      changed
    end

    # Add an entity to the world
    # @param entity [Entity] The entity to add
    # @return [Entity] The added entity
    def add_entity(entity)
      @entities[entity.id] = entity
      entity
    end

    # Remove an entity from the world
    # @param entity_id [String] The ID of the entity to remove
    # @return [Entity, nil] The removed entity or nil if not found
    def remove_entity(entity_id)
      @entities.delete(entity_id)
    end

    def get_entity_by_name(name)
      @entities.values.find { |e| e.name == name }
    end

    # Get an entity by ID
    # @param entity_id [String] The ID of the entity to find
    # @return [Entity, nil] The entity or nil if not found
    def get_entity(entity_id)
      @entities[entity_id]
    end

    # Find the first entity with a specific tag
    # @param tag [Symbol, String] The tag to find
    # @return [Entity, nil] The first entity with the tag or nil if none found
    def find_entity_by_tag(tag)
      @entities.values.find { |e| e.has_tag?(tag) }
    end

    # Query entities with specific component types
    # @param component_types [Array<Symbol>] The component types to find
    # @return [Array<Entity>] Entities with all specified component types
    def query_entities(component_types)
      return @entities.values if component_types.empty?

      @entities.values.select do |entity|
        component_types.all? { |type| entity.has_component?(type) }
      end
    end

    # Add a system to the world with a priority
    # @param system [System] The system to add
    # @param priority [Integer] The priority for update order (lower numbers run first)
    # @return [System] The added system
    def add_system(system, priority = 0)
      @systems << [system, priority]

      @systems.sort_by! { |_system, system_priority| system_priority }

      system
    end

    # Update all systems and process events and commands
    # @param delta_time [Float] The time since the last update
    def update(_unused)
      # Update all systems
      @systems.each do |system, _| # rubocop:disable Style/HashEachMethods
        system.update(nil)
      end

      # IMPORTANT:
      # Commands are processed before events to ensure any events triggered by commands
      # are handled in the same update cycle

      # Process queued commands
      process_commands

      # Process events after systems have updated
      process_events
    end

    # Queue a command to be processed
    # @param command_type [Symbol] The type of command
    # @param params [Hash] The command parameters
    def queue_command(command_type, params = {})
      @logger.debug("[World#queue_command] Queueing command: #{command_type}, params: #{params}")
      @command_queue << [command_type, params]
    end

    # Emit an event to be processed
    # @param event_type [Symbol] The type of event
    # @param data [Hash] The event data
    def emit_event(event_type, data = {})
      @event_queue << [event_type, data]
    end

    # Subscribe a system to an event
    # @param event_type [Symbol] The type of event
    # @param subscriber [Object] The object that will handle the event
    def subscribe(event_type, subscriber)
      @event_subscribers[event_type] << subscriber
    end

    # Unsubscribe a system from an event
    # @param event_type [Symbol] The type of event
    # @param subscriber [Object] The object to unsubscribe
    def unsubscribe(event_type, subscriber)
      @event_subscribers[event_type].delete(subscriber)
    end

    # Set the current level
    # @param level [Level] The level to set
    def set_level(level)
      @current_level = level
    end

    # Get the grid from the current level
    # @return [Grid, nil] The grid or nil if no level is set
    def grid
      @current_level&.grid
    end

    private

    # Process all queued events
    def process_events
      until @event_queue.empty?
        @logger.debug("[World#process_events] Processing events")

        event_type, data = @event_queue.pop
        @logger.debug("[World#process_events] Event type: #{event_type}, data: #{data}")

        @event_subscribers[event_type].each do |subscriber|
          @logger.debug("[World#process_events] Subscriber: #{subscriber}")
          subscriber.handle_event(event_type, data)
        end
      end
    end

    # Process all queued commands
    def process_commands
      @logger.debug("[World#process_commands] Processing commands")
      until @command_queue.empty?
        @logger.debug("[World#process_commands] #{@command_queue.size} commands in queue")

        command, params = @command_queue.shift
        @logger.debug("[World#process_commands] Command #{command.class.name}, params: #{params}")

        if command.is_a?(Vanilla::Commands::Command)
          command.execute(self)
        else
          handle_command(command, params)
        end
      end
    end

    # Handle a specific command
    # @param command_type [Symbol] The type of command
    # @param params [Hash] The command parameters
    def handle_command(command_type, params)
      @logger.warn("[World#handle_command] this method is deprecated, use command.execute(self) instead")
      @logger.debug("[World#handle_command] command_type: #{command_type}, params: #{params}")
      case command_type
      when :change_level
        change_level(params[:difficulty], params[:player_id])
      when :add_entity
        add_entity(params[:entity])
      when :remove_entity
        remove_entity(params[:entity_id])
      when :add_to_inventory
        add_to_inventory(params[:player_id], params[:item_id])
      else
        @logger.error("[World#handle_command] Unknown command type: #{command_type}")
      end
    end

    # TODO: Consider refactoring it into smaller methods to improve maintainability.
    # Setting the flag (@level_changed) after level transition ensures the rendering system knows when to refresh the display, which is essential for the game loop.
    # The change_level method is quite long and handles multiple responsibilities.
    def change_level(difficulty, player_id)
      level_generator = LevelGenerator.new
      new_level = level_generator.generate(difficulty)
      player = get_entity_by_name("Player")
      if player
        @logger.debug("[World#change_level] Player found: #{player.id}")
        @logger.debug("[World#change_level] Player position: #{player.get_component(:position).to_hash}")

        position = player.get_component(:position)
        entrance_row = new_level.respond_to?(:entrance_row) ? new_level.entrance_row : 0
        entrance_column = new_level.respond_to?(:entrance_column) ? new_level.entrance_column : 0

        position.set_position(entrance_row, entrance_column)
        @logger.debug("[World#change_level] Player position set: #{position.to_hash}")
        new_level.add_entity(player) # Ensure player is added to new level's entities
      end
      set_level(new_level)

      # Spawn monsters for the new level
      monster_system = systems.find { |sys, _| sys.is_a?(Vanilla::Systems::MonsterSystem) }&.first
      monster_system&.spawn_monsters(difficulty)

      emit_event(:level_transitioned, { difficulty: difficulty, player_id: player_id })

      # Flag to inform world that there's a new level to be rendered
      @level_changed = true
    end

    # Add an item to a player's inventory
    # @param player_id [String] The ID of the player entity
    # @param item_id [String] The ID of the item entity
    def add_to_inventory(player_id, item_id)
      player = get_entity(player_id)
      item = get_entity(item_id)

      return unless player && item
      return unless player.has_component?(:inventory) && item.has_component?(:item)

      inventory = player.get_component(:inventory)
      inventory.add_item(item)
    end
  end
end
