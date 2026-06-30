# Monster AI Targeting (Faction-Driven Pursuit) - Proposal 011

## Status

**Planned (Phase 2).** Design/exploration complete; not yet implemented. Builds
directly on the faction foundation from
[Proposal 010](010_faction_system_proposal.md).

## Overview

Phase 1 gave entities factions and made combat ask *"are these two hostile?"*.
But nothing yet *consumes* that question: monsters spawn and sit still, and the
only way a fight starts is the player walking into a monster.

Phase 2 makes monsters **hunt**. Each turn, a monster that can *see* a hostile
target paths toward it and takes a step. When it reaches the player, the existing
combat menu fires. Targeting is expressed in terms of `Factions.hostile?`, so the
same code generalises to monster-vs-monster and allied NPCs later — but this
slice deliberately ships **player-hunting only**.

## Design decisions (confirmed)

| Decision | Choice | Consequence |
|---|---|---|
| **Detection** | **FOV / line-of-sight** | Monsters must actually see the target. Requires giving monsters a `VisibilityComponent` so `FOVSystem` computes their view. Walls/corners break pursuit — more tactical, more realistic. |
| **Contact** | **Reuse the Fight/Run menu** | When a monster steps onto the player, the existing collision → menu → combat path fires ("A goblin lunges! [1] Fight [2] Run"). Minimal new wiring; consistent with today's to-the-death duel. |
| **First slice** | **Player-hunting only** | Monsters target the player specifically (the only hostile that exists today). The targeting query still routes through `Factions.hostile?`, so faction-generic targeting is a later, small extension. |

## Background: the turn model (from code exploration)

The game is strictly turn-based: **one keypress = one full system cycle**.
Systems run in priority order, then queued commands and events are processed:

```
Input(1) → Movement(2) → FOV(2.5) → Combat(3) / Collision(3) / Loot(3)
        → Monster(4) → Message(5) → Render(10)
```

Two facts drive the whole design:

1. **`MonsterSystem` runs at priority 4 — *after* `CollisionSystem`(3).** If
   monster movement happened there, a monster stepping onto the player would not
   be seen by collision detection until the *next* keypress. Monster movement
   must therefore run **before** Collision(3).
2. **Combat is entirely player-initiated today.** Player moves →
   `:entity_moved` → `CollisionSystem` → `:entities_collided` → `MessageSystem`
   pops the Attack/Run menu → `AttackCommand` → `process_turn_based_combat`
   resolves the duel to the death. There is no path for a monster to *trigger*
   that chain; the only thing missing is that the trigger is currently reached
   only when the *player* is the mover.

## What already exists and is reused

- **Pathfinding:** `Vanilla::Algorithms::Dijkstra.shortest_path(grid, start:, goal:)`
  returns an ordered array of `Cell`s. (`lib/vanilla/algorithms/dijkstra.rb`)
- **Movement execution:** `MovementSystem#move(entity, direction)` is public,
  validates `cell.linked?` + tile walkability, updates the grid, and emits
  `:entity_moved`. (`lib/vanilla/systems/movement_system.rb`)
- **Targeting predicate:** `Vanilla::Factions.hostile?(monster, target)` (Phase 1).
- **Visibility:** `FOVSystem` computes `visible_tiles` for *any* entity with a
  `VisibilityComponent`; `VisibilityComponent#tile_visible?(row, col)` answers
  line-of-sight. (`lib/vanilla/systems/fov_system.rb`)

## Architecture

### New system: `MonsterAISystem` (priority ~2.6)

Slotted **after `FOVSystem`(2.5)** (so monster sight lines are fresh) and
**before `CollisionSystem`(3)** (so a monster reaching the player is detected the
same turn).

Per turn, for each living monster:

```ruby
def update(_delta_time = nil)
  target = player_target            # the player entity (Phase 2 scope)
  return unless target

  target_pos = target.get_component(:position)
  monsters.each do |monster|
    next unless Vanilla::Factions.hostile?(monster, target)
    next unless can_see?(monster, target_pos)        # FOV / line-of-sight gate
    step_toward(monster, target_pos)                 # Dijkstra + one move
  end
end
```

- **`can_see?`** — `monster.get_component(:visibility).tile_visible?(target.row, target.column)`.
- **`step_toward`** — Dijkstra from the monster's cell to the target's cell, take
  the first cell of the path, translate it to a cardinal direction, and call
  `MovementSystem#move(monster, direction)` (looked up via `world.systems`, the
  same pattern `AttackCommand` uses to find `CombatSystem`).

Movement is executed by calling `MovementSystem#move` **directly** rather than
setting an `InputComponent` direction, because `MovementSystem` runs at priority
2 — *before* this system — so a direction set at 2.6 wouldn't be consumed until
the next turn.

### Entity changes (`EntityFactory.create_monster`)

Monsters gain two components they currently lack:

- **`MovementComponent.new(active: true)`** — required; `MovementSystem#move`
  refuses to move an entity without an active movement component.
- **`VisibilityComponent.new(vision_radius: …)`** — so `FOVSystem` computes the
  monster's line of sight for the detection gate.

### Combat wiring (one small change)

When a monster moves onto the player, `MovementSystem` emits `:entity_moved` for
the monster; `CollisionSystem` then emits `:entities_collided`. The only thing to
verify/adjust is that `MessageSystem`'s collision handler raises the Fight/Run
menu — and resolves the *monster* as the attack target — regardless of which
entity was the mover. If it currently keys on "the player moved", it needs to
key on "the player is one of the colliding pair" instead. No new command or
combat path is introduced.

## Risks / things to verify during implementation

1. **Fog of war must stay player-only.** `RenderSystem` uses a `VisibilityComponent`
   for fog of war. Giving monsters visibility must NOT change what the player
   sees — confirm `RenderSystem` reads the *player's* visibility specifically,
   not "any visibility component". **(Highest-risk item.)**
2. **Tile bookkeeping in `MovementSystem#move`.** Confirm it updates cell tiles
   generically (clears the old cell, marks the new one) rather than hard-coding
   the player's tile, so a moving monster leaves the floor behind it correctly.
3. **`MessageSystem` collision handler** — confirm mover-agnostic menu triggering
   and correct target resolution (attack the monster, not the player).
4. **Grid access** — confirm how a system reaches the active grid
   (`world.current_level.grid` or similar) so `MonsterAISystem` and Dijkstra get
   the right grid after level transitions.
5. **Monster-on-monster blocking** — a monster whose next path cell is occupied
   by another monster (non-walkable `MONSTER` tile) simply doesn't move that turn.
   Acceptable for this slice; no stacking.
6. **Performance** — FOV + Dijkstra per monster per turn. Fine at current counts
   (≤8 monsters); note it and revisit only if profiling says so.

## Testing plan

- **`MonsterAISystem` unit specs:** moves one step toward a visible player; does
  **not** move when the player is out of line of sight; does not move when no
  hostile target exists; picks a path-correct direction; ignores non-hostile
  entities (faction-generic readiness).
- **`EntityFactory` specs:** monsters now carry `:movement` and `:visibility`.
- **Integration:** a monster adjacent-with-line-of-sight closes the gap and the
  resulting collision raises the combat menu; a monster behind a wall does not
  pursue.
- **Regression:** full suite stays green; fog-of-war render behaviour for the
  player is unchanged (guards risk #1).

## Out of scope (future phases)

- Faction-generic targeting (monster-vs-monster, allied NPCs) — a small extension
  of `player_target` into "nearest hostile".
- Memory / last-known-position (continue toward where the player was last seen).
- Aggro de-escalation, fleeing at low health, pack behaviour.
- Removing `MonsterSystem`'s direct `@player` reference (spawn-distance logic).
