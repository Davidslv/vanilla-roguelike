# Helper module for capturing game state snapshots
module GameStateHelper
  # Captures the current state of the game in a structured format
  # @param game [Vanilla::Game] The game instance
  # @return [Hash] A hash representation of the current game state
  def capture_game_state(game)
    {
      player: capture_player_state(game.player),
      level: capture_level_state(game.current_level),
      systems: capture_systems_state(game)
    }
  end

  private

  def capture_player_state(player)
    return nil unless player

    position = player.get_component(:position)
    health = player.get_component(:health)

    {
      id: player.id,
      position: position ? { row: position.row, column: position.column } : nil,
      health: health ? health.current_health : nil,
      found_stairs: player.respond_to?(:found_stairs?) ? player.found_stairs? : nil
    }
  end

  def capture_level_state(level)
    return nil unless level

    {
      difficulty: level.difficulty,
      entities_count: level.respond_to?(:all_entities) ? level.all_entities.count : nil,
      stairs_position: level.respond_to?(:stairs) && level.stairs.respond_to?(:get_component) ?
        capture_entity_position(level.stairs) : nil
    }
  end

  def capture_systems_state(game)
    {
      # Add relevant system state information here as we identify it
      movement_system: game.respond_to?(:movement_system) ? { initialized: !game.movement_system.nil? } : nil,
      render_system: game.respond_to?(:render_system) ? { initialized: !game.render_system.nil? } : nil,
      message_system: game.respond_to?(:message_system) ?
        { message_count: game.message_system.respond_to?(:get_recent_messages) ?
          game.message_system.get_recent_messages.count : nil } : nil
    }
  end

  def capture_entity_position(entity)
    return nil unless entity && entity.respond_to?(:get_component)

    position = entity.get_component(:position)
    position ? { row: position.row, column: position.column } : nil
  end
end