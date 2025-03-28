# frozen_string_literal: true

require_relative 'system'

module Vanilla
  module Systems
    # System for managing and displaying game messages
    class MessageSystem < System
      MAX_MESSAGES = 100

      # Initialize the message system
      # @param world [World] The world this system belongs to
      def initialize(world)
        super
        @message_queue = []

        # Subscribe to relevant events
        # Define what are relevant events for this system
        @world.subscribe(:entity_moved, self)
        @world.subscribe(:entities_collided, self)
        @world.subscribe(:level_transition_requested, self)
        @world.subscribe(:level_transitioned, self)
        @world.subscribe(:item_picked_up, self)
        @world.subscribe(:damage_dealt, self)
        @world.subscribe(:entity_died, self)
      end

      # Update method called once per frame
      # @param delta_time [Float] Time since last update
      def update(_delta_time)
        # Process any queued messages
        process_message_queue
      end

      # Handle events from the world
      # @param event_type [Symbol] The type of event
      # @param data [Hash] The event data
      def handle_event(event_type, data)
        case event_type
        when :entity_moved
          entity = @world.get_entity(data[:entity_id])
          if entity&.has_tag?(:player)
            add_message("movement.moved", metadata: { x: data[:new_position][:row], y: data[:new_position][:column] })
          end
        when :monster_spawned
          type = @world.get_entity(data[:monster_id]).name

          add_message(
            "monster.spawned",
            metadata: { type: type, x: data[:position][:row], y: data[:position][:column] }
          )
        when :monster_despawned
          add_message("monster.died", metadata: { monster: @world.get_entity(data[:monster_id])&.name || "monster" })
        when :entities_collided
          entity = @world.get_entity(data[:entity_id])
          other = @world.get_entity(data[:other_entity_id])

          if entity&.has_tag?(:player) && other&.has_tag?(:monster)
            add_message(
              "combat.collision",
              metadata: { x: data[:position][:row], y: data[:position][:column] },
              options: [{ key: '1', content: "Attack Monster [M]", callback: :attack_monster }]
            )
          elsif entity&.has_tag?(:player) && other&.has_tag?(:stairs)
            add_message("level.stairs_found")
          end

        when :level_transition_requested
          add_message("level.stairs_found")
        when :level_transitioned
          add_message("level.descended", metadata: { level: data[:difficulty] }, importance: :high)
        when :item_picked_up
          add_message("item.picked_up", metadata: { item: data[:item_name] || "item" })
        end
      end

      # Add a message to the queue
      # @param key [String] The message key/text
      # @param metadata [Hash] Additional message data
      # @param importance [Symbol] Message importance (:low, :normal, :high, :critical)
      def add_message(key, metadata = {}, importance: :normal)
        message = {
          key: key,
          metadata: metadata,
          importance: importance,
          timestamp: Time.now
        }

        @message_queue << message
        trim_message_queue if @message_queue.size > MAX_MESSAGES
      end

      private

      # Process and display messages in the queue
      def process_message_queue
        # Delegate to MessageManager for now; will integrate with panel later
      end

      # Keep message queue at a reasonable size
      def trim_message_queue
        # Keep the most recent messages, prioritizing by importance
        @message_queue.sort_by! { |msg| [msg[:timestamp], importance_value(msg[:importance])] }
        @message_queue = @message_queue.last(MAX_MESSAGES)
      end

      # Convert importance symbol to numeric value for sorting
      # @param importance [Symbol] The importance level
      # @return [Integer] Numeric importance value
      def importance_value(importance)
        importance_values = { critical: 3, high: 2, normal: 1, low: 0 }

        importance_values[importance] || 0
      end
    end
  end
end
