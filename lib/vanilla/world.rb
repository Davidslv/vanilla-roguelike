module Vanilla
  # The World class manages entities and systems
  class World
    # @return [Hash<String, Vanilla::Components::Entity>] All entities in the world
    attr_reader :entities

    # @return [Array<Object>] All systems in the world
    attr_reader :systems

    # Initialize a new world
    def initialize
      @entities = {}
      @systems = []
      @event_subscribers = Hash.new { |h, k| h[k] = [] }
      @event_queue = Queue.new
    end

    # Add an entity to the world
    # @param entity [Vanilla::Components::Entity] The entity to add
    # @return [Vanilla::Components::Entity] The added entity
    def add_entity(entity)
      @entities[entity.id] = entity
      entity
    end

    # Remove an entity from the world
    # @param entity_id [String] The ID of the entity to remove
    # @return [Vanilla::Components::Entity, nil] The removed entity, or nil if not found
    def remove_entity(entity_id)
      @entities.delete(entity_id)
    end

    # Get an entity by ID
    # @param entity_id [String] The ID of the entity to get
    # @return [Vanilla::Components::Entity, nil] The entity, or nil if not found
    def get_entity(entity_id)
      @entities[entity_id]
    end

    # Find entities with all the given components
    # @param component_types [Array<Symbol>] The component types to find
    # @return [Array<Vanilla::Components::Entity>] Entities with all the specified components
    def query_entities(component_types)
      return @entities.values if component_types.empty?

      @entities.values.select do |entity|
        component_types.all? { |type| entity.has_component?(type) }
      end
    end

    # Find entities with the given tag
    # @param tag [Symbol] The tag to find
    # @return [Array<Vanilla::Components::Entity>] Entities with the specified tag
    def find_entities_by_tag(tag)
      @entities.values.select { |entity| entity.has_tag?(tag) }
    end

    # Find the first entity with the given tag
    # @param tag [Symbol] The tag to find
    # @return [Vanilla::Components::Entity, nil] The first entity with the tag, or nil if none found
    def find_entity_by_tag(tag)
      @entities.values.find { |entity| entity.has_tag?(tag) }
    end

    # Add a system to the world
    # @param system [Object] The system to add
    # @param priority [Integer] The priority of the system (lower numbers run first)
    # @return [Object] The added system
    def add_system(system, priority = 0)
      @systems << [system, priority]
      @systems.sort_by! { |s| s[1] }
      system
    end

    # Update all systems
    # @param delta_time [Float] Time in seconds since the last update
    def update(delta_time)
      # Update all systems
      @systems.each do |system, _|
        system.update(delta_time)
      end

      # Process events after systems have updated
      process_events
    end

    # Queue an event to be processed
    # @param event_type [Symbol] The type of event
    # @param data [Hash] Event data
    def emit_event(event_type, data = {})
      @event_queue << [event_type, data]
    end

    # Subscribe a system to an event type
    # @param event_type [Symbol] The type of event to subscribe to
    # @param subscriber [Object] The system that will handle the event
    def subscribe(event_type, subscriber)
      @event_subscribers[event_type] << subscriber
    end

    # Unsubscribe a system from an event type
    # @param event_type [Symbol] The type of event to unsubscribe from
    # @param subscriber [Object] The system to unsubscribe
    def unsubscribe(event_type, subscriber)
      @event_subscribers[event_type].delete(subscriber)
    end

    # Convert the world to a hash representation
    # @return [Hash] Serialized world data
    def to_hash
      {
        entities: @entities.values.map(&:to_hash)
      }
    end

    # Create a world from a hash representation
    # @param hash [Hash] Serialized world data
    # @return [World] The deserialized world
    def self.from_hash(hash)
      world = new

      hash[:entities].each do |entity_hash|
        entity = Components::Entity.from_hash(entity_hash)
        world.add_entity(entity)
      end

      world
    end

    private

    # Process all events in the queue
    def process_events
      until @event_queue.empty?
        event_type, data = @event_queue.pop
        @event_subscribers[event_type].each do |subscriber|
          subscriber.handle_event(event_type, data)
        end
      end
    end
  end
end