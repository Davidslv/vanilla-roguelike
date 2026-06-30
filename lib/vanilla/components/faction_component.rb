# frozen_string_literal: true

module Vanilla
  module Components
    # Identifies which faction an entity belongs to and which factions it
    # treats as hostile.
    #
    # This is a *pure data* container by design: it stores a faction id and a
    # set of hostile faction ids, and nothing else. The logic for deciding
    # whether two entities are hostile or allied lives in {Vanilla::Factions}
    # so that this class stays within the ECS/ComponentBehavior cop's rules
    # (components may only define initialize, type, to_hash, from_hash and
    # attribute accessors).
    #
    # @example Give an entity a faction
    #   entity.add_component(
    #     FactionComponent.new(faction_id: :hero, hostile_to: [:monster])
    #   )
    #
    # @see Vanilla::Factions for hostility/ally queries.
    class FactionComponent < Component
      # @return [Symbol] the faction this entity belongs to
      attr_accessor :faction_id

      # @return [Set<Symbol>] faction ids this entity is hostile toward
      attr_accessor :hostile_to

      # @param faction_id [Symbol] the entity's own faction. Defaults to
      #   +:neutral+ so the component can be registered (Component.register
      #   instantiates with no arguments) and so an entity with an unspecified
      #   faction is hostile to nobody.
      # @param hostile_to [Array<Symbol>, Set<Symbol>] factions treated as enemies
      def initialize(faction_id: :neutral, hostile_to: [])
        super()
        @faction_id = faction_id
        @hostile_to = Set.new(hostile_to)
      end

      # @return [Symbol] the component type used by the ECS registry
      def type
        :faction
      end

      # @return [Hash] serialized representation (round-trips via {from_hash})
      def to_hash
        { type: type, faction_id: @faction_id, hostile_to: @hostile_to.to_a }
      end

      # Rebuild a component from its serialized hash.
      # @param hash [Hash] data produced by {#to_hash}
      # @return [FactionComponent]
      def self.from_hash(hash)
        new(faction_id: hash[:faction_id] || :neutral, hostile_to: hash[:hostile_to] || [])
      end
    end

    Component.register(FactionComponent)
  end
end
