# frozen_string_literal: true

module Vanilla
  # The World class is the heart of the game, acting as a coordinator for all game objects and logic.
  # It follows the Entity-Component-System (ECS) pattern, a design commonly used in games to keep code
  # flexible and modular. In ECS:
  # - **Entities** are simple IDs representing game objects (e.g., a player, monster, or item).
  # - **Components** are data containers attached to entities (e.g., position, health).
  # - **Systems** are logic that operates on entities with specific components (e.g., movement, rendering).
  #
  # World ties these together: it stores all entities, runs systems in a specific order each frame,
  # and handles communication via events and commands.
  #
  # Think of it as a stage manager
  # it doesn't decide what happens but ensures everything runs smoothly and on time.
  #
  class World
    attr_reader :entities, :systems, :display, :current_level
    attr_accessor :quit, :level_changed

    # --- Initialization ---
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

    # --- Core Lifecycle Methods ---
    def update(_unused)
      # Update all systems in priority order
      @systems.each do |system, _| # rubocop:disable Style/HashEachMethods
        system.update(nil)
      end

      # Process commands before events to ensure event triggers are handled in the same cycle
      process_commands
      process_events
    end

    # --- State Query Methods ---
    def quit?
      @logger.debug("[World#quit?] quit: #{@quit}")
      @quit
    end

    def level_changed?
      changed = @level_changed
      @level_changed = false # Reset after querying
      changed
    end

    # --- Entity Management ---
    def add_entity(entity)
      @entities[entity.id] = entity
      entity
    end

    def remove_entity(entity_id)
      @entities.delete(entity_id)
    end

    def get_entity(entity_id)
      @entities[entity_id]
    end

    def get_entity_by_name(name)
      @entities.values.find { |e| e.name == name }
    end

    def find_entity_by_tag(tag)
      @entities.values.find { |e| e.has_tag?(tag) }
    end

    def query_entities(component_types)
      return @entities.values if component_types.empty?

      @entities.values.select { |entity| component_types.all? { |type| entity.has_component?(type) } }
    end

    # --- System Management ---
    def add_system(system, priority = 0)
      @systems << [system, priority]
      @systems.sort_by! { |_system, system_priority| system_priority }
      system
    end

    # --- Event and Command Handling ---
    def queue_command(command_type, params = {})
      @logger.debug("[World#queue_command] Queueing command: #{command_type}, params: #{params}")
      @command_queue << [command_type, params]
    end

    def emit_event(event_type, data = {})
      @event_queue << [event_type, data]
    end

    def subscribe(event_type, subscriber)
      @event_subscribers[event_type] << subscriber
    end

    def unsubscribe(event_type, subscriber)
      @event_subscribers[event_type].delete(subscriber)
    end

    # --- Level Management ---
    def set_level(level)
      @current_level = level
    end

    def grid
      @current_level&.grid
    end

    # --- Private Implementation Details ---
    private

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

    def process_events
      event_manager = Vanilla::ServiceRegistry.get(:event_manager)

      until @event_queue.empty?
        @logger.debug("[World#process_events] Processing events")

        event_type, data = @event_queue.shift
        @logger.debug("[World#process_events] Event type: #{event_type}, data: #{data}")

        if event_manager
          event_manager.publish_event(event_type, self, data)
        else
          @logger.error("[World#process_events] No event manager found")
        end

        @event_subscribers[event_type].each do |subscriber|
          @logger.debug("[World#process_events] Subscriber: #{subscriber}")
          subscriber.handle_event(event_type, data)
        end
      end
    end

    def handle_command(command_type, params)
      @logger.warn("[World#handle_command] This method is deprecated; use command.execute(self) instead")
      @logger.debug("[World#handle_command] command_type: #{command_type}, params: #{params}")
      case command_type
      when :change_level
        @logger.error("[World#handle_command] Deprecated; use ChangeLevelCommand instead")
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

    def add_to_inventory(player_id, item_id)
      player = get_entity(player_id)
      item = get_entity(item_id)
      return unless player && item && player.has_component?(:inventory) && item.has_component?(:item)

      player.get_component(:inventory).add_item(item)
    end
  end
end
