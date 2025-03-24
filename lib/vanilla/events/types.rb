# frozen_string_literal: true
module Vanilla
  module Events
    # Constants for all event types used in the system
    module Types
      # Entity events - related to entity lifecycle and state changes
      ENTITY_CREATED = "entity_created"
      ENTITY_DESTROYED = "entity_destroyed"
      ENTITY_MOVED = "entity_moved"
      ENTITY_COLLISION = "entity_collision"
      ENTITY_STATE_CHANGED = "entity_state_changed"

      # Game state events - related to overall game state
      GAME_STARTED = "game_started"
      GAME_ENDED = "game_ended"
      LEVEL_CHANGED = "level_changed"
      TURN_STARTED = "turn_started"
      TURN_ENDED = "turn_ended"

      # Input events - related to user input
      KEY_PRESSED = "key_pressed"
      COMMAND_ISSUED = "command_issued"

      # Command-specific events
      MOVE_COMMAND_ISSUED = "move_command_issued"
      EXIT_COMMAND_ISSUED = "exit_command_issued"

      # Movement-related events
      MOVEMENT_INTENT = "movement_intent"  # Intent to move
      MOVEMENT_SUCCEEDED = "movement_succeeded"  # Movement was successful
      MOVEMENT_BLOCKED = "movement_blocked"  # Movement was blocked

      # Combat events
      COMBAT_ATTACK = "combat_attack"
      COMBAT_DAMAGE = "combat_damage"
      COMBAT_DEATH = "combat_death"

      # Item events
      ITEM_PICKED_UP = "item_picked_up"
      ITEM_DROPPED = "item_dropped"
      ITEM_USED = "item_used"

      # Monster events
      MONSTER_SPAWNED = "monster_spawned"
      MONSTER_DESPAWNED = "monster_despawned"
      MONSTER_DETECTED_PLAYER = "monster_detected_player"

      # Debug events
      DEBUG_COMMAND = "debug_command"
      DEBUG_STATE_DUMP = "debug_state_dump"
    end
  end
end
