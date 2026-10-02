# Event System Documentation

## Core Game Events

### ENTITY_CREATED
- **Type**: `entity_created`
- **Description**: An entity was created in the game world
- **Data**: { entity_id: String }

### ENTITY_DESTROYED
- **Type**: `entity_destroyed`
- **Description**: An entity was removed from the game world
- **Data**: { entity_id: String }

### ENTITY_MOVED
- **Type**: `entity_moved`
- **Description**: An entity changed its position in the game world (legacy, may be phased out)
- **Data**: { entity_id: String, old_position: { row: Integer, column: Integer }, new_position: { row: Integer, column: Integer }, direction: Symbol }

### ENTITY_COLLISION
- **Type**: `entity_collision`
- **Description**: An entity collided with another entity (legacy, see COLLISION_DETECTED)
- **Data**: { entity_id: String, other_entity_id: String, position: { row: Integer, column: Integer } }

### ENTITY_STATE_CHANGED
- **Type**: `entity_state_changed`
- **Description**: An entity’s internal state (e.g., health, status) changed
- **Data**: { entity_id: String, state: Hash }

### GAME_STARTED
- **Type**: `game_started`
- **Description**: The game session has begun
- **Data**: { seed: Integer, difficulty: Integer }

### GAME_ENDED
- **Type**: `game_ended`
- **Description**: The game session has concluded
- **Data**: { reason: String }

### LEVEL_CHANGED
- **Type**: `level_changed`
- **Description**: The game level has changed (alias for LEVEL_TRANSITIONED)
- **Data**: { difficulty: Integer, player_id: String }

### TURN_STARTED
- **Type**: `turn_started`
- **Description**: A new game turn has begun
- **Data**: { turn: Integer }

### TURN_ENDED
- **Type**: `turn_ended`
- **Description**: The current game turn has ended
- **Data**: { turn: Integer }

### KEY_PRESSED
- **Type**: `key_pressed`
- **Description**: A key was pressed by the player
- **Data**: { key: String, entity_id: String }

### COMMAND_ISSUED
- **Type**: `command_issued`
- **Description**: A general command was issued by the player
- **Data**: { command: String }

### MOVE_COMMAND_ISSUED
- **Type**: `move_command_issued`
- **Description**: A command to move an entity was issued
- **Data**: { entity_id: String, direction: Symbol }

### EXIT_COMMAND_ISSUED
- **Type**: `exit_command_issued`
- **Description**: A command to exit the game was issued
- **Data**: {}

### MOVEMENT_INTENT
- **Type**: `movement_intent`
- **Description**: An intent to move an entity was registered
- **Data**: { entity_id: String, direction: Symbol }

### MOVEMENT_SUCCEEDED
- **Type**: `movement_succeeded`
- **Description**: An entity successfully completed a movement
- **Data**: { entity_id: String, old_position: { row: Integer, column: Integer }, new_position: { row: Integer, column: Integer }, direction: Symbol }

### MOVEMENT_BLOCKED
- **Type**: `movement_blocked`
- **Description**: An entity’s movement was prevented or blocked
- **Data**: { entity_id: String, position: { row: Integer, column: Integer }, direction: Symbol }

### COMBAT_ATTACK
- **Type**: `combat_attack`
- **Description**: An attack was initiated in combat
- **Data**: { attacker_id: String, target_id: String, damage: Integer }

### COMBAT_DAMAGE
- **Type**: `combat_damage`
- **Description**: Damage was dealt during combat
- **Data**: { target_id: String, damage: Integer, source_id: String }

### COMBAT_DEATH
- **Type**: `combat_death`
- **Description**: An entity died as a result of combat
- **Data**: { entity_id: String, killer_id: String }

### ITEM_PICKED_UP
- **Type**: `item_picked_up`
- **Description**: A player picked up an item
- **Data**: { player_id: String, item_id: String, item_name: String }

### ITEM_DROPPED
- **Type**: `item_dropped`
- **Description**: A player dropped an item
- **Data**: { entity_id: String, item_id: String }

### ITEM_USED
- **Type**: `item_used`
- **Description**: A player used an item
- **Data**: { entity_id: String, item_id: String }

### MONSTER_SPAWNED
- **Type**: `monster_spawned`
- **Description**: A monster appeared in the game world
- **Data**: { monster_id: String, position: { row: Integer, column: Integer } }

### MONSTER_DESPAWNED
- **Type**: `monster_despawned`
- **Description**: A monster was removed from the game world
- **Data**: { monster_id: String }

### MONSTER_DETECTED_PLAYER
- **Type**: `monster_detected_player`
- **Description**: A monster detected the player’s presence
- **Data**: { monster_id: String, player_id: String }

### DEBUG_COMMAND
- **Type**: `debug_command`
- **Description**: A debug command was executed
- **Data**: { command: String }

### DEBUG_STATE_DUMP
- **Type**: `debug_state_dump`
- **Description**: A debug state dump was requested
- **Data**: { state: Hash }

### COLLISION_DETECTED
- **Type**: `collision_detected`
- **Description**: A general collision between entities was detected
- **Data**: { entity_id: String, other_entity_id: String, position: { row: Integer, column: Integer } }

