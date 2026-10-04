# Proposals

Larger features are designed here before they are built. Each proposal is numbered. Once a proposal is implemented it moves to [`archive/`](archive/) and keeps its number. See [CONTRIBUTING.md](../../CONTRIBUTING.md) for when a proposal is needed.

> [!NOTE]
> Archived proposals are design records. They describe what was planned at the time; the code may have moved on since. The code and [architecture.md](../architecture.md) are the current truth.

## Open

Not implemented yet.

| # | Proposal | Notes |
|---|---|---|
| 006 | [Item usage and effects](006_item_usage_effects_system_proposal.md) | [Review](006_item_usage_effects_system_proposal_REVIEW.md): not ready, conflicts with the existing inventory and equipment code. Basic item use exists: `UseItemCommand` and `ItemUseSystem` handle `:heal` and `:nourish` (#166) |
| 007 | [Ruby2D integration](007_ruby2d_integration_proposal.md) | Graphical renderer; nothing built |
| 008 | [Game controller support](008_game_controller_support_proposal.md) | Nothing built |

## Implemented

| # | Proposal | Where |
|---|---|---|
| 001 | [Combat system](archive/001_combat_system_proposals.md) | Option 1 (attack command). PR #118: `CombatSystem`, `CombatComponent`, `AttackCommand` |
| 002 | [Enhanced combat menu](archive/002_enhanced_combat_menu_proposal.md) | PR #118: attack / run away menu, `RunAwayCommand`. Run away does not yet move the player (#149) |
| 003 | [Loot system](archive/003_loot_system_proposal.md) | PR #118: `LootSystem`, apples |
| 004 | [Hunger system](archive/004_hunger_system_proposal.md) | PRs #163, #165, #166, #167: game over, turns, item use, `HungerSystem` |
| 005 | [Field of view](archive/005_field_of_view_system_proposal.md) | `FOVSystem`, `VisibilityComponent` |
| 010 | [Faction system](archive/010_faction_system_proposal.md) | PR #123: `FactionComponent`, `Vanilla::Factions` (Phase 1) |
| 011 | [Monster AI targeting](archive/011_monster_ai_targeting_proposal.md) | PR #124: `MonsterAISystem` (010's Phase 2) |
| 012 | [End-to-end playability testing](archive/012_end_to_end_playability_testing_proposal.md) | PRs #136 to #140: headless harness, determinism spec, certifier bot, fuzzer, replay tapes |

009 (Web API layer and browser interface) and its implementation summary were removed from the repo in `7d39c24`; they are in git history.
