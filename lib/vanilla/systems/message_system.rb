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
      def update(delta_time)
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
            add_message("movement.player_moved", importance: :low)
          end

        when :entities_collided
          # Handle collision messages based on entity types
          entity = @world.get_entity(data[:entity_id])
          other = @world.get_entity(data[:other_entity_id])

          # Player collisions
          if entity&.has_tag?(:player) && other&.has_tag?(:item)
            add_message("collision.player_item", importance: :normal)
          elsif entity&.has_tag?(:player) && other&.has_tag?(:monster)
            add_message("collision.player_monster", importance: :high)
          elsif entity&.has_tag?(:player) && other&.has_tag?(:stairs)
            add_message("collision.player_stairs", importance: :normal)
          end

        when :level_transition_requested
          add_message("level.stairs_found", importance: :normal)

        when :level_transitioned
          difficulty = data[:difficulty]
          add_message("level.descended", { level: difficulty }, importance: :high)

        when :item_picked_up
          item_name = data[:item_name] || "item"
          add_message("item.picked_up", { item: item_name }, importance: :normal)

        when :damage_dealt
          attacker = @world.get_entity(data[:attacker_id])
          target = @world.get_entity(data[:target_id])
          damage = data[:damage]

          if attacker&.has_tag?(:player)
            add_message("combat.player_hit", { target: target&.name || "enemy", damage: damage }, importance: :normal)
          elsif target&.has_tag?(:player)
            add_message("combat.player_damaged", { attacker: attacker&.name || "enemy", damage: damage }, importance: :high)
          end

        when :entity_died
          entity = @world.get_entity(data[:entity_id])
          killer = @world.get_entity(data[:killer_id])

          if entity&.has_tag?(:monster)
            add_message("combat.monster_died", { monster: entity.name || "monster" }, importance: :normal)
          elsif entity&.has_tag?(:player)
            add_message("combat.player_died", importance: :critical)
          end
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
        # Implementation depends on the display system
        # This would typically render messages to a message log area
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
        case importance
        when :critical then 3
        when :high then 2
        when :normal then 1
        when :low then 0
        else 0
        end
      end
    end
  end
end
