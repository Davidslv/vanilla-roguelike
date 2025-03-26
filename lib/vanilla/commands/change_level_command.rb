# frozen_string_literal: true

require_relative 'command'

module Vanilla
  module Commands
    class ChangeLevelCommand < Command
      def initialize(difficulty, player)
        super(logger)
        @difficulty = difficulty
        @player = player
        @logger = Vanilla::Logger.instance
        @executed = false
      end

      def execute(world)
        return if @executed

        @logger.info("[ChangeLevelCommand] Changing level to difficulty #{@difficulty}")

        level_generator = LevelGenerator.new(@logger)
        new_level = level_generator.generate(@difficulty) # Assuming generate returns a Level

        if @player
          position = @player.get_component(:position)
          entrance_row = new_level.entrance_row
          entrance_column = new_level.entrance_column
          position.set_position(entrance_row, entrance_column)
          @logger.debug("[ChangeLevelCommand] Player position reset to [#{entrance_row}, #{entrance_column}]")
          new_level.add_entity(@player) # This updates the grid via Level#add_entity
        else
          @logger.error("[ChangeLevelCommand] No player provided")
        end

        world.set_level(new_level)
        monster_system = world.systems.find { |s, _| s.is_a?(Vanilla::Systems::MonsterSystem) }&.first
        monster_system&.spawn_monsters(@difficulty)

        world.emit_event(:level_transitioned, { difficulty: @difficulty, player_id: @player&.id })
        world.instance_variable_set(:@level_changed, true)
        @executed = true
      end
    end
  end
end
