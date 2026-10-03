# frozen_string_literal: true

module Vanilla
  module Messages
    # Picks the death message for a player_died event (#159). Pure lookup, so
    # new causes (starvation, traps) only add a row here.
    module DeathMessage
      KEYS = {
        combat: 'death.player_dies',
        starvation: 'death.starvation'
      }.freeze
      FALLBACK = 'death.generic_death'

      # @param data [Hash] player_died event data (:cause, :killer_name)
      # @return [Array(String, Hash)] message key and its metadata
      def self.for(data)
        key = KEYS.fetch(data[:cause], FALLBACK)
        metadata = data[:cause] == :combat ? { enemy: data[:killer_name] || 'enemy' } : {}
        [key, metadata]
      end
    end
  end
end
