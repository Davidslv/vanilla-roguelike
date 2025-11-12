# frozen_string_literal: true

require_relative 'command'

module Vanilla
  module Commands
    class ChangeLevelCommand < Command
      def initialize(difficulty, player)
        super()
        @difficulty = difficulty
        @player = player
        @logger = Vanilla::Logger.instance
        @executed = false
      end

      def execute(world)
        return if @executed

        @logger.info("[ChangeLevelCommand] Changing level to difficulty #{@difficulty}")

        # Update MazeSystem difficulty and trigger regeneration
        maze_system = world.systems.find { |s, _| s.is_a?(Vanilla::Systems::MazeSystem) }&.first
        if maze_system
          maze_system.difficulty = @difficulty # Update difficulty
          world.level_changed = true # Signal MazeSystem to regenerate
          maze_system.update(nil) # Force immediate regeneration
        else
          @logger.error("[ChangeLevelCommand] No MazeSystem found")
          return
        end

        if @player
          position = @player.get_component(:position)
          position.set_position(0, 0) # Reset to [0, 0] as per MazeSystem
          @logger.debug("[ChangeLevelCommand] Player position reset to [0, 0]")
          
          # Reset FOV for new level - clear explored and visible tiles
          visibility = @player.get_component(:visibility)
          if visibility
            visibility.reset
            @logger.debug("[ChangeLevelCommand] Player visibility reset for new level")
          end
          
          world.current_level.add_entity(@player) # Ensure player is in new level's entities
          
          # Trigger FOV recalculation immediately for new level
          fov_system = world.systems.find { |s, _| s.is_a?(Vanilla::Systems::FOVSystem) }&.first
          fov_system&.update(nil)
          @logger.debug("[ChangeLevelCommand] FOV recalculated for new level")
        else
          @logger.error("[ChangeLevelCommand] No player provided")
        end

        # Monster Spawning here... but not yet. Game needs to work first.
        # monster_system = world.systems.find { |s, _| s.is_a?(Vanilla::Systems::MonsterSystem) }&.first
        # monster_system&.spawn_monsters(@difficulty)

        world.emit_event(:level_transitioned, { difficulty: @difficulty, player_id: @player&.id })
        world.level_changed = false # Reset flag after transition

        @executed = true
      end
    end
  end
end
