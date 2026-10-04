# frozen_string_literal: true

require_relative 'command'

module Vanilla
  module Commands
    # Drop an item from the inventory (#164). Takes a turn only if it happens.
    class DropItemCommand < Command
      attr_reader :entity, :item

      def initialize(entity, item)
        super()
        @entity = entity
        @item = item
      end

      # @return [Boolean] true if the item was dropped
      def execute(world)
        return false if @executed

        @executed = true
        system = world.systems.find { |s, _| s.is_a?(Vanilla::Systems::ItemDropSystem) }&.first
        unless system
          @logger.error("[DropItemCommand] No ItemDropSystem found")
          return false
        end

        done = system.drop_item(@entity, @item)
        world.end_turn if done
        done
      end
    end
  end
end
