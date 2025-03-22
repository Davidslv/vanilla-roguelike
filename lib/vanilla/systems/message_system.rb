module Vanilla
  module Systems
    # System for managing game messages and notifications
    #
    # This system handles logging game events as messages for the player,
    # prioritizing them and formatting them appropriately.
    #
    # It follows the ECS pattern by:
    # 1. Subscribing to various game events
    # 2. Not storing entity state directly
    # 3. Using events for communication
    class MessageSystem < System
      # Maximum number of messages to keep in history
      MAX_MESSAGES = 100

      # Initialize a new message system
      # @param world [Vanilla::World] The world this system operates on
      def initialize(world)
        super
        @messages = []
        @logger = Vanilla::Logger.instance

        # Subscribe to relevant events
        world.subscribe(:entity_moved, self)
        world.subscribe(:entities_collided, self)
        world.subscribe(:stairs_found, self)
        world.subscribe(:level_changed, self)
      end

      # Update method called each frame
      # @param delta_time [Float] Time in seconds since the last update
      def update(delta_time)
        # Process any queued messages
        # For now, this is a no-op since processing happens in handle_event
      end

      # Handle events
      # @param event_type [Symbol] The type of event
      # @param data [Hash] Event data
      def handle_event(event_type, data)
        case event_type
        when :entity_moved
          handle_movement_message(data)
        when :entities_collided
          handle_collision_message(data)
        when :stairs_found
          handle_stairs_message(data)
        when :level_changed
          handle_level_change_message(data)
        end
      end

      # Add a message to the message queue
      # @param key [String] The message key/identifier
      # @param metadata [Hash] Additional data for the message
      # @param importance [Symbol] Message importance (:low, :normal, :high, :critical)
      # @param category [Symbol] Message category
      def add_message(key, metadata = {}, importance: :normal, category: :general)
        message = {
          key: key,
          metadata: metadata,
          importance: importance,
          category: category,
          timestamp: Time.now
        }

        @messages << message
        trim_message_queue

        # Log to actual logger for debugging
        @logger.info("#{importance.to_s.upcase}: #{format_message(key, metadata)}")

        # Emit message event for UI to respond to
        emit_event(:message_added, {
          message: message,
          formatted_text: format_message(key, metadata)
        })
      end

      # Get all messages
      # @return [Array<Hash>] The message queue
      def get_messages
        @messages
      end

      # Get messages by category
      # @param category [Symbol] The category to filter by
      # @return [Array<Hash>] Messages in the specified category
      def get_messages_by_category(category)
        @messages.select { |m| m[:category] == category }
      end

      # Clear all messages
      def clear_messages
        @messages.clear
      end

      private

      # Handle movement messages
      # @param data [Hash] Movement event data
      def handle_movement_message(data)
        entity_id = data[:entity_id]
        entity = @world.get_entity(entity_id)
        return unless entity

        # Only log player movements
        return unless entity.has_tag?(:player)

        # Get direction as text
        direction = data[:direction]
        direction_text = direction_to_text(direction)

        add_message("movement.player_moved", { direction: direction_text },
                    importance: :low, category: :movement)
      end

      # Handle collision messages
      # @param data [Hash] Collision event data
      def handle_collision_message(data)
        entity_id = data[:entity_id]
        other_entity_id = data[:other_entity_id]

        entity = @world.get_entity(entity_id)
        other_entity = @world.get_entity(other_entity_id)

        return unless entity && other_entity

        # We only care about player collisions for now
        if entity.has_tag?(:player) || other_entity.has_tag?(:player)
          player = entity.has_tag?(:player) ? entity : other_entity
          other = entity.has_tag?(:player) ? other_entity : entity

          # Different message depending on what was collided with
          if other.has_tag?(:monster)
            monster_type = other.get_data(:monster_type) || "monster"
            add_message("collision.with_monster", { monster_type: monster_type },
                        importance: :normal, category: :combat)
          elsif other.has_tag?(:item)
            item_name = other.get_data(:name) || "item"
            add_message("collision.with_item", { item_name: item_name },
                        importance: :normal, category: :item)
          end
        end
      end

      # Handle stairs messages
      # @param data [Hash] Stairs event data
      def handle_stairs_message(data)
        entity_id = data[:entity_id]
        entity = @world.get_entity(entity_id)
        return unless entity

        # Only care about player finding stairs
        return unless entity.has_tag?(:player)

        add_message("exploration.stairs_found", {},
                    importance: :high, category: :exploration)
      end

      # Handle level change messages
      # @param data [Hash] Level change event data
      def handle_level_change_message(data)
        level = data[:level] || "unknown"

        add_message("level.changed", { level: level },
                    importance: :high, category: :exploration)
      end

      # Convert a direction symbol to human-readable text
      # @param direction [Symbol] The direction
      # @return [String] Human-readable direction text
      def direction_to_text(direction)
        case direction
        when :north then "north"
        when :south then "south"
        when :east then "east"
        when :west then "west"
        else direction.to_s
        end
      end

      # Format a message for display
      # @param key [String] The message key
      # @param metadata [Hash] Message metadata
      # @return [String] Formatted message
      def format_message(key, metadata)
        # In a real implementation, this would use a proper
        # localization system with message templates
        case key
        when "movement.player_moved"
          "You move #{metadata[:direction]}."
        when "collision.with_monster"
          "You encounter a #{metadata[:monster_type]}!"
        when "collision.with_item"
          "You see a #{metadata[:item_name]}."
        when "exploration.stairs_found"
          "You found stairs leading down!"
        when "level.changed"
          "You descend to level #{metadata[:level]}."
        else
          "#{key}: #{metadata.inspect}"
        end
      end

      # Keep the message queue at a reasonable size
      def trim_message_queue
        if @messages.size > MAX_MESSAGES
          # Remove oldest messages when queue gets too large
          @messages = @messages.last(MAX_MESSAGES)
        end
      end
    end
  end
end