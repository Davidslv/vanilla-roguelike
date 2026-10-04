# Hunger System - Proposal 004

## Status

**Accepted, not implemented.** Rewritten 2026-10-03 after a design discussion. The original draft (2025-11-12) is in git history. Delivery is three steps, each its own issue and PR, in this order:

1. Game over on player death, with the cause shown (#159).
2. A real turn: one `turn_ended` event per player action that takes time (#160).
3. Hunger, built on 1 and 2 (#161).

## Goal

Make food matter. The player has a food supply that runs down one unit per turn. When it runs low the HUD warns them. When it runs out they lose health, and they can die of starvation. Apples, which monsters sometimes drop, restore food.

Hunger gives a run a natural limit. Going straight for the stairs is the cheapest route; fighting costs turns and health but is the only way to find food.

## Decisions

| Question | Decision |
|---|---|
| Can hunger kill? | Yes. The death screen says so: "You collapse from hunger, too weak to go on." (`death.starvation`, already in `config/locales/en.yml`) |
| What does the clock count? | Turns, not moves. A turn is a player action that takes time (step 2). Menu keys, toggles and unknown keys are free |
| Where does the state live? | `NutritionComponent` on the player: `food_left` and `max_food`, nothing else |
| Where do the rules live? | `HungerSystem` (ticking, penalties, events) and `Vanilla::Hunger` (thresholds and the status for a given `food_left`), shared by the system and the HUD |
| Is the clock random? | No. It is deterministic, so it does not shift other rolls |

### Why a small component

State that belongs to one entity goes in a component; systems hold none (AGENTS.md). The component also works as the switch: only entities that have it get hungry. `HealthComponent` (current and max, no logic) is the model.

What the original draft put in the component, and where it goes now:

| Original draft | Now |
|---|---|
| `starving?`, `increase`, `decrease` | `HungerSystem`. Behaviour in a component fails the `ECS/ComponentBehavior` cop |
| Hunger bands (not hungry / hungry / starving) | Derived from `food_left` by `Vanilla::Hunger.status`. Never stored |
| Thresholds and rates | Constants in `Vanilla::Hunger`. Game rules, not per-entity data |
| `movement_counter` | Not needed: the clock counts `turn_ended` |

The name is about what is stored. `food_left` counts down, so `NutritionComponent` reads correctly where "hunger: 150" would read as very hungry.

## Measured baseline

Measured on 2026-10-03 with the stairs bot (`spec/support/stairs_bot.rb`) over seeds 1 to 40, playing to level 6. The bot walks straight to the stairs and fights whatever blocks it.

| Measure | Value |
|---|---|
| Key presses per level, median | 10 to 14 (range 2 to 25) |
| Kills per 5-level run | about 1.3 |
| Apple drops per 5-level run | about 0.5 (30% chance per kill, `loot_system.rb`) |

Levels are short, so Rogue's food clock (about 1,300 turns before "Hungry") would last around 100 levels here and never matter. The numbers below are scaled to this game.

## Rules

Starting values. Tune them in step 3 with the same bot measurement, and record the result here.

| Constant | Value | Meaning |
|---|---|---|
| `START_FOOD` | 150 | About 11 levels for a direct player (150 / ~13 turns) |
| `MAX_FOOD` | 200 | Eating cannot store more than this |
| `HUNGRY_AT` | 50 | HUD shows `Hungry`, about 4 levels of warning |
| `WEAK_AT` | 20 | HUD shows `Weak`, about 1.5 levels left |
| `STARVING_AT` | 0 | HUD shows `Starving` and damage starts |
| `STARVE_DAMAGE` | 2 | HP lost per turn while starving: from 100 HP, death in 50 turns, about 4 levels |
| `APPLE_FOOD` | 60 | About 4.5 levels of food. Apples keep their existing `heal: 20` |

A gentler first version (1 HP every 5 turns) would let a starving player with 100 HP walk about 38 more levels, so starvation would almost never decide a run.

### Tuning result (2026-10-04, #161)

Measured with hunger implemented: the stairs bot over seeds 1 to 40, playing for depth. It picks up apples but never eats, so this is the worst case for food.

| Outcome | Seeds | Depth reached, median (range) |
|---|---|---|
| Starved | 9 | 13 (12 to 17), at about 168 turns |
| Killed in combat | 8 | 13 (9 to 15) |
| Bot stuck in a menu (a bot limitation, not the game) | 23 | 8 (3 to 14) |

A player who never eats starves at about the depth where monsters start winning anyway. Hunger ends runs without dominating them. The starting values above are kept.

Each `turn_ended`:

1. `food_left` goes down by 1, never below 0.
2. If the status changed (for example `:ok` to `:hungry`), emit `hunger_status_changed`.
3. If starving, lower `current_health` by `STARVE_DAMAGE` and emit `starvation_damage`. At 0 HP the player dies with cause `:starvation`, through the death path from step 1.

Eating an apple raises `food_left` by `APPLE_FOOD`, up to `MAX_FOOD`, and can move the status back to `:ok`.

## Step 1: Game over on player death (#159)

Today the player's death is not handled: `CombatSystem#check_death` removes the player entity, `MessageSystem` prints `death.player_dies`, and the loop keeps running without a player.

- One death path for the player, whatever the cause. It carries the cause (`:combat` with the killer, or `:starvation`).
- The death screen shows the cause message, the floor reached, and the seed, then waits for a key and exits through `Game#cleanup`.
- `death.stats_summary` (kills, items) can come later; it needs counters the game does not keep yet.
- Specs: a headless run where the player dies in combat ends the loop and shows the cause.

## Step 2: A real turn (#160)

`turn_started` and `turn_ended` are defined in `events/types.rb` but never emitted. `Game#turn` counts loop passes outside menus, so `f` and unknown keys advance it, and menu actions do not. `Vanilla.game_turn` reads it for the message log and `EffectComponent` durations.

- The world owns the turn counter.
- `turn_ended { turn: }` is emitted once after each player action that takes time: a successful move, an attack, a run-away attempt, using or dropping an item.
- These take no time: opening or closing a menu, menu navigation, `f`, unknown keys, walking into a wall.
- `Vanilla.game_turn` reads the world's counter.
- Replay tapes are re-recorded: the new event appears in every stream.

## Step 3: Hunger (#161)

| Piece | Change |
|---|---|
| `lib/vanilla/components/nutrition_component.rb` | New. `food_left`, `max_food`, defaults for both (so `Component.register` works, see #147) |
| `lib/vanilla/hunger.rb` | New. Constants and `Hunger.status(food_left)` |
| `lib/vanilla/systems/hunger_system.rb` | New. Subscribes to `turn_ended` |
| `EntityFactory` | Player gets `NutritionComponent` |
| Apple (`loot_system.rb`) | Add `{ type: :nourish, amount: APPLE_FOOD }` |
| `ItemUseSystem` | Handle `:nourish` |
| `events/types.rb` | `hunger_status_changed`, `starvation_damage`; regenerate `docs/events.md` |
| `config/locales/en.yml`, `MessageSystem` | "You are getting hungry.", "You feel weak with hunger.", "You are starving!", "That apple hit the spot." |
| `TerminalRenderer` | Status on the HP line when not `:ok`: `HP: 80/100 (80%) \| Level: 3 \| Hungry` |
| `game.rb`, `headless_game.rb`, AGENTS.md, `docs/architecture.md` | Register `HungerSystem` (the doc spec checks the tables) |
| Replay tapes | Re-record |

### Tests

- `Vanilla::Hunger.status` at each threshold boundary.
- `HungerSystem`: one `turn_ended` costs one food; no change without `turn_ended`; status events fire once per crossing; starvation damage of `STARVE_DAMAGE` per turn at 0 food; food never below 0.
- `ItemUseSystem`: `:nourish` raises food, capped at `MAX_FOOD`.
- Integration (headless): starting at `food_left: 1` and 1 HP, walking until death ends the game with the starvation message.
- Integration: menu keys and `f` cost no food.
- `NutritionComponent` round-trips through `to_hash` / `from_hash`.

## Not in scope

- Other foods, spoilage, cooking.
- Penalties at `Weak` beyond the HUD warning (a later option: an `EffectComponent` strength penalty).
- Fainting (Rogue's lost turns at zero food).
