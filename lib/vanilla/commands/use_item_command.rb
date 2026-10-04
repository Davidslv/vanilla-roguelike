# frozen_string_literal: true

require_relative 'command'

module Vanilla
  module Commands
    # Use an item from the inventory (#164). Takes a turn only if it happens.
    class UseItemCommand < Command
      attr_reader :entity, :item

      def initialize(entity, item)
        super()
        @entity = entity
        @item = item
      end

      # @return [Boolean] true if the item was used
      def execute(world)
        return false if @executed

        @executed = true
        system = world.systems.find { |s, _| s.is_a?(Vanilla::Systems::ItemUseSystem) }&.first
        unless system
          @logger.error("[UseItemCommand] No ItemUseSystem found")
          return false
        end

        done = system.use_item(@entity, @item)
        world.end_turn if done
        done
      end
    end
  end
end
