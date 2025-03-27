# frozen_string_literal: true

module Vanilla
  module Events
    module Types
      # Represents an event with name, description, and expected data structure
      Event = Struct.new(:name, :description, :data) do
        def to_s
          name
        end
      end

      # Define all events with their names, descriptions, and data structures
      EVENTS = {
        # Entity events - related to entity lifecycle and state changes
        entity_created: Event.new(
          "entity_created",
          "An entity was created in the game world",
          "{ entity_id: String }"
        ),
        entity_destroyed: Event.new(
          "entity_destroyed",
          "An entity was removed from the game world",
          "{ entity_id: String }"
        ),
        entity_moved: Event.new(
          "entity_moved",
          "An entity changed its position in the game world (legacy, may be phased out)",
          "{ entity_id: String, old_position: { row: Integer, column: Integer }, new_position: { row: Integer, column: Integer }, direction: Symbol }"
        ),
        entity_collision: Event.new(
          "entity_collision",
          "An entity collided with another entity (legacy, see COLLISION_DETECTED)",
          "{ entity_id: String, other_entity_id: String, position: { row: Integer, column: Integer } }"
        ),
        entity_state_changed: Event.new(
          "entity_state_changed",
          "An entity’s internal state (e.g., health, status) changed",
          "{ entity_id: String, state: Hash }"
        ),

        # Game state events - related to overall game state
        game_started: Event.new(
          "game_started",
          "The game session has begun",
          "{ seed: Integer, difficulty: Integer }"
        ),
        game_ended: Event.new(
          "game_ended",
          "The game session has concluded",
          "{ reason: String }"
        ),
        level_changed: Event.new(
          "level_changed",
          "The game level has changed (alias for LEVEL_TRANSITIONED)",
          "{ difficulty: Integer, player_id: String }"
        ),
        turn_started: Event.new(
          "turn_started",
          "A new game turn has begun",
          "{ turn: Integer }"
        ),
        turn_ended: Event.new(
          "turn_ended",
          "The current game turn has ended",
          "{ turn: Integer }"
        ),

        # Input events - related to user input
        key_pressed: Event.new(
          "key_pressed",
          "A key was pressed by the player",
          "{ key: String, entity_id: String }"
        ),
        command_issued: Event.new(
          "command_issued",
          "A general command was issued by the player",
          "{ command: String }"
        ),

        # Command-specific events
        move_command_issued: Event.new(
          "move_command_issued",
          "A command to move an entity was issued",
          "{ entity_id: String, direction: Symbol }"
        ),
        exit_command_issued: Event.new(
          "exit_command_issued",
          "A command to exit the game was issued",
          "{}"
        ),

        # Movement-related events
        movement_intent: Event.new(
          "movement_intent",
          "An intent to move an entity was registered",
          "{ entity_id: String, direction: Symbol }"
        ),
        movement_succeeded: Event.new(
          "movement_succeeded",
          "An entity successfully completed a movement",
          "{ entity_id: String, old_position: { row: Integer, column: Integer }, new_position: { row: Integer, column: Integer }, direction: Symbol }"
        ),
        movement_blocked: Event.new(
          "movement_blocked",
          "An entity’s movement was prevented or blocked",
          "{ entity_id: String, position: { row: Integer, column: Integer }, direction: Symbol }"
        ),

        # Combat events
        combat_attack: Event.new(
          "combat_attack",
          "An attack was initiated in combat",
          "{ attacker_id: String, target_id: String, damage: Integer }"
        ),
        combat_damage: Event.new(
          "combat_damage",
          "Damage was dealt during combat",
          "{ target_id: String, damage: Integer, source_id: String }"
        ),
        combat_death: Event.new(
          "combat_death",
          "An entity died as a result of combat",
          "{ entity_id: String, killer_id: String }"
        ),

        # Item events
        item_picked_up: Event.new(
          "item_picked_up",
          "A player picked up an item",
          "{ player_id: String, item_id: String, item_name: String }"
        ),
        item_dropped: Event.new(
          "item_dropped",
          "A player dropped an item",
          "{ entity_id: String, item_id: String }"
        ),
        item_used: Event.new(
          "item_used",
          "A player used an item",
          "{ entity_id: String, item_id: String }"
        ),

        # Monster events
        monster_spawned: Event.new(
          "monster_spawned",
          "A monster appeared in the game world",
          "{ monster_id: String, position: { row: Integer, column: Integer } }"
        ),
        monster_despawned: Event.new(
          "monster_despawned",
          "A monster was removed from the game world",
          "{ monster_id: String }"
        ),
        monster_detected_player: Event.new(
          "monster_detected_player",
          "A monster detected the player’s presence",
          "{ monster_id: String, player_id: String }"
        ),

        # Debug events
        debug_command: Event.new(
          "debug_command",
          "A debug command was executed",
          "{ command: String }"
        ),
        debug_state_dump: Event.new(
          "debug_state_dump",
          "A debug state dump was requested",
          "{ state: Hash }"
        ),

        # Collision events
        collision_detected: Event.new(
          "collision_detected",
          "A general collision between entities was detected",
          "{ entity_id: String, other_entity_id: String, position: { row: Integer, column: Integer } }"
        )
      }

      # Dynamically define constants for each event
      EVENTS.each do |key, event|
        const_set(key.to_s.upcase, event.name)
      end

      # Access event descriptions programmatically
      # @param event_name [String] The event name to describe
      # @return [String] The event’s description or a fallback message
      def self.describe(event_name)
        event = EVENTS.values.find { |e| e.name == event_name }
        event&.description || "No description available for #{event_name}"
      end

      # Access event data structure programmatically
      # @param event_name [String] The event name to get data for
      # @return [String] The event’s data structure or a fallback message
      def self.data(event_name)
        event = EVENTS.values.find { |e| e.name == event_name }
        event&.data || "No data structure defined for #{event_name}"
      end
    end
  end
end
