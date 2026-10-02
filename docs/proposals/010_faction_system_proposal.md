# Faction System (Foundation) - Proposal 010

## Status

**Phase 1 (this proposal): implemented.** Foundation only — a data model and
hostility queries, wired into the existing player-vs-monster combat with no
change to observable gameplay. Phase 2 (monster targeting/AI that *uses*
factions) is described under [Future Work](#future-work) and is intentionally
out of scope here.

## Overview

Today the game tells entities apart with a direct `@player` reference (held by
`MonsterSystem`) and entity **tags** (`:player`, `:monster`). Combat routing is
hard-coded around those tags: `AttackCommand` starts turn-based combat only when
"a `:player` attacks a `:monster`".

This proposal introduces a **faction** as the first-class notion of *"who is an
enemy of whom"*. An entity belongs to a faction and declares which factions it
treats as hostile. Combat then asks *"are these two hostile?"* instead of
*"is one the player and the other a monster?"*.

This makes the architecture **player-agnostic** and unlocks (in later phases)
allied NPCs, monster-vs-monster infighting, and dynamic diplomacy — without the
combat code needing to know about "the player" specifically.

The design follows the analysis written up for the r/roguelikedev thread
(see `reddit_response_enemy_targeting copy.md`, linked from GitHub issue #119),
adapted to respect this codebase's ECS discipline.

## Motivation

Current coupling and its limits:

- `AttackCommand` (`lib/vanilla/commands/attack_command.rb`) branches on
  `has_tag?(:player) && has_tag?(:monster)`.
- `MonsterSystem` (`lib/vanilla/systems/monster_system.rb`) takes a direct
  `player:` reference for spawn placement and collision checks.

Consequences:

- **No allied NPCs** — anything that isn't the player is implicitly an enemy.
- **No monster infighting** — two monster types can't be hostile to each other.
- **Player-centric systems** — combat/AI logic can't reason about a third party.

A faction component decouples "what kind of thing is this" (tags) from "who does
it fight" (faction), which is the axis combat actually cares about.

## Design

### New Component: `FactionComponent`

A **pure data** container (`lib/vanilla/components/faction_component.rb`):

```ruby
FactionComponent.new(faction_id: :hero, hostile_to: [:monster])
```

| Field        | Type           | Meaning                                   |
|--------------|----------------|-------------------------------------------|
| `faction_id` | `Symbol`       | the faction this entity belongs to        |
| `hostile_to` | `Set<Symbol>`  | faction ids this entity treats as enemies |

It implements the component contract (`type`, `to_hash`, `from_hash`) and is
registered with `Component.register`.

#### Why the logic lives *outside* the component

The project enforces a custom RuboCop cop, `ECS/ComponentBehavior`, which allows
components to define **only** `initialize`, `type`, `to_hash`, `from_hash`, and
attribute writers. Predicate methods such as `hostile_to?`/`ally_of?` (as drafted
in the original Reddit write-up) would violate it. So the **behaviour** lives in
a separate module, keeping the component a pure data bag — which is also the
better ECS design.

#### Why `faction_id` defaults to `:neutral`

`Component.register` instantiates each class with no arguments
(`klass.new rescue return`). A component whose `initialize` has a *required*
keyword therefore fails to register silently (this already affects several
existing components — see [Known Limitations](#known-limitations)). Defaulting
`faction_id: :neutral` makes `FactionComponent` register cleanly **and** gives a
sensible meaning to "an entity with no declared faction": neutral, hostile to
nobody. This was verified with a full `Entity#to_hash` → `Entity.from_hash`
round-trip preserving the faction.

### New Module: `Vanilla::Factions`

Canonical faction ids and the hostility/ally queries
(`lib/vanilla/factions.rb`):

```ruby
Vanilla::Factions::HERO      # => :hero
Vanilla::Factions::MONSTER   # => :monster
Vanilla::Factions::NEUTRAL   # => :neutral

Vanilla::Factions.hostile?(attacker, target) # => Boolean
Vanilla::Factions.allies?(entity, other)     # => Boolean
```

Both queries are **nil-safe** and treat an entity with no `FactionComponent` as
neutral (hostile to nobody, allied with nobody), so partially-migrated content
never raises.

### Entity wiring (`EntityFactory`)

| Entity   | `faction_id` | `hostile_to` |
|----------|--------------|--------------|
| Player   | `:hero`      | `[:monster]` |
| Monster  | `:monster`   | `[:hero]`    |

### Combat routing (`AttackCommand`)

Before:

```ruby
if @attacker.has_tag?(:player) && @target.has_tag?(:monster)
  combat_system.process_turn_based_combat(@attacker, @target)
else
  combat_system.process_attack(@attacker, @target)
end
```

After:

```ruby
if player_initiated_against_hostile?   # has_tag?(:player) && Factions.hostile?(attacker, target)
  combat_system.process_turn_based_combat(@attacker, @target)
else
  combat_system.process_attack(@attacker, @target)
end
```

The `:player` tag is deliberately retained for the turn-based branch: turn-based
combat is the player's *interactive* UX, which is about **control**, not
**hostility**. Only the "is the target an enemy?" question is delegated to
factions.

## Scope boundaries (what this proposal does **not** touch)

- **`CollisionSystem`** handles player–stairs and player–item interactions.
  Those are not hostility relationships (stairs and items are not combatants), so
  they remain tag-based and are intentionally left unchanged.
- **`CombatSystem`** uses `has_tag?(:player)` for death handling / kill credit —
  that is about player *identity*, not faction, and is left unchanged.
- **`MonsterSystem`** keeps its direct `player:` reference. Removing that belongs
  to Phase 2, where monsters gain real targeting.

## Behaviour preservation

This change is a **refactor with no observable gameplay difference**:

- The only entities that exist today are the player (`:hero`) and monsters
  (`:monster`), and they are mutually hostile.
- `hostile?(player, monster)` is therefore `true` exactly when the old
  `has_tag?(:monster)` check was true, so combat routes identically.
- Entities without a faction are treated as non-hostile, matching the old
  "non-player attacker uses a single attack" fallback.

## Testing

- `spec/lib/vanilla/components/faction_component_spec.rb` — initialization,
  defaults, `type`, registry registration, and `to_hash`/`from_hash` round-trip.
- `spec/lib/vanilla/factions_spec.rb` — `hostile?`/`allies?` including reciprocity,
  same-faction, neutral, missing-component, and nil cases.
- `spec/lib/vanilla/commands/attack_command_spec.rb` — new cases proving the
  player-vs-hostile path starts turn-based combat while non-hostile and
  non-player attacks fall back to a single attack.

## Known limitations

- **Registry gap (pre-existing):** `Component.register` swallows the
  `ArgumentError` from required-keyword initializers, so several components with
  required kwargs are not actually registered. `FactionComponent` sidesteps this
  with a default. A broader fix to `register` is out of scope for this proposal.

## Future Work (Phase 2)

The payoff of factions arrives when something *queries* them for targeting. None
of this is implemented yet:

1. **Monster targeting/AI** — replace `MonsterSystem`'s direct `player:`
   reference with `Factions.hostile?`-based target selection
   (`find_nearest_hostile`), so monsters pursue any enemy, not just "the player".
2. **Allied NPCs / companions** — entities sharing the `:hero` faction.
3. **Additional factions** — e.g. `:undead` hostile to everyone, enabling
   three-way fights for free.
4. **Dynamic relationships** — mutate `hostile_to` at runtime for diplomacy,
   betrayal, or "faction disguise" effects.
5. **Performance** — if hostile-entity queries become hot, add spatial
   partitioning or a per-faction hostility cache invalidated on spawn/death.
