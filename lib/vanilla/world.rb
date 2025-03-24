# frozen_string_literal: true

module Vanilla
  # The World class is the central container for all entities and systems.
  # It manages entities, systems, events, and commands.
  #
  # World acts as a coordinator, not a decision-maker.
  #  It runs systems in order (update loop) and provides access to entities/components.

  class World
    attr_reader :entities, :systems, :display, :current_level

    # Initialize a new world
    def initialize
      @entities = {}
      @systems = []

      @display = DisplayHandler.new
      @current_level = nil
      @event_subscribers = Hash.new { |h, k| h[k] = [] }
      @event_queue = Queue.new
      @command_queue = Queue.new
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
      # Process queued commands
      process_commands

      # Update all systems
      @systems.each do |system, _| # rubocop:disable Style/HashEachMethods
        system.update(nil)
      end

      # Process events after systems have updated
      process_events
    end

    # Queue a command to be processed
    # @param command_type [Symbol] The type of command
    # @param params [Hash] The command parameters
    def queue_command(command_type, params = {})
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
        event_type, data = @event_queue.pop
        @event_subscribers[event_type].each do |subscriber|
          subscriber.handle_event(event_type, data)
        end
      end
    end

    # Process all queued commands
    def process_commands
      until @command_queue.empty?
        command_type, params = @command_queue.pop
        handle_command(command_type, params)
      end
    end

    # Handle a specific command
    # @param command_type [Symbol] The type of command
    # @param params [Hash] The command parameters
    def handle_command(command_type, params)
      case command_type
      when :change_level
        change_level(params[:difficulty], params[:player_id])
      when :add_entity
        add_entity(params[:entity])
      when :remove_entity
        remove_entity(params[:entity_id])
      when :add_to_inventory
        add_to_inventory(params[:player_id], params[:item_id])
        # Other command handlers...
      end
    end

    def change_level(difficulty, player_id)
      level_generator = LevelGenerator.new
      new_level = level_generator.generate(difficulty)
      player = get_entity(player_id)
      if player
        position = player.get_component(:position)
        entrance_row = new_level.respond_to?(:entrance_row) ? new_level.entrance_row : 0
        entrance_column = new_level.respond_to?(:entrance_column) ? new_level.entrance_column : 0
        position.set_position(entrance_row, entrance_column)
        new_level.add_entity(player) # Ensure player is added to new level's entities
      end
      set_level(new_level)

      # Spawn monsters for the new level
      monster_system = systems.find { |sys, _| sys.is_a?(Vanilla::Systems::MonsterSystem) }&.first
      monster_system&.spawn_monsters(difficulty)

      emit_event(:level_transitioned, { difficulty: difficulty, player_id: player_id })
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
