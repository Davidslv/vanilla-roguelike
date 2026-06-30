# frozen_string_literal: true

module Vanilla
  # Canonical faction identifiers and the hostility/ally queries that operate
  # on them.
  #
  # {Vanilla::Components::FactionComponent} is a pure data container, so the
  # *behaviour* of factions — deciding whether two entities are enemies or
  # allies — lives here. Systems and commands call these helpers instead of
  # checking entity tags such as +:player+ / +:monster+ directly, which keeps
  # combat targeting player-agnostic and ready for allied NPCs or
  # monster-vs-monster combat (see
  # documents/proposals/010_faction_system_proposal.md).
  #
  # Entities without a FactionComponent are treated as neutral: hostile to
  # nobody and allied with nobody.
  module Factions
    # The player's faction.
    HERO = :hero
    # The default faction for spawned monsters.
    MONSTER = :monster
    # Entities with no declared allegiance.
    NEUTRAL = :neutral

    module_function

    # Whether +attacker+ regards +target+ as an enemy.
    #
    # @param attacker [Vanilla::Entities::Entity, nil]
    # @param target [Vanilla::Entities::Entity, nil]
    # @return [Boolean] true only when both entities have a faction and the
    #   attacker's faction lists the target's faction as hostile
    def hostile?(attacker, target)
      attacker_faction = faction_of(attacker)
      target_faction = faction_of(target)
      return false unless attacker_faction && target_faction

      attacker_faction.hostile_to.include?(target_faction.faction_id)
    end

    # Whether two entities belong to the same faction.
    #
    # @param entity [Vanilla::Entities::Entity, nil]
    # @param other [Vanilla::Entities::Entity, nil]
    # @return [Boolean] true only when both entities share a faction id
    def allies?(entity, other)
      entity_faction = faction_of(entity)
      other_faction = faction_of(other)
      return false unless entity_faction && other_faction

      entity_faction.faction_id == other_faction.faction_id
    end

    # @api private
    # @return [Vanilla::Components::FactionComponent, nil]
    def faction_of(entity)
      entity&.get_component(:faction)
    end
  end
end
