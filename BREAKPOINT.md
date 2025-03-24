# Game Development Report: Post-BREAKINGPOINT Fixes

## BREAKINGPOINT

**Commit:** `bcbe5c5f640c9e5345317c17dcf9bfb3d17be179`

From this commit onwards, we began removing non-ECS (Entity-Component-System) code to streamline the architecture. Key goals included:
- Identifying why the game stopped working.
- Cleaning up a significant amount of legacy code.

## FIX UPDATE

After over 9 hours of debugging, cleanup, and fixes, we restored the game to a playable state. Extensive refactoring addressed critical issues, though some minor bugs were introduced:

- **Monsters**: No longer spawn consistently at the same location with a fixed seed.
- **Stairs**: Positioning shifted from using `LongestPath` (maximizing distance from the player for an immersive, IKEA-like path) to less optimal spots due to rushed fixes.
- **Entangled Responsibilities**: Core functionality repairs mixed concerns across components, setting a risky precedent for bad practices unless addressed as a priority.

### Commit Log
Below are all commits from the BREAKINGPOINT to HEAD, detailing the 9+ hour effort:

$ git log bcbe5c5f640c9e5345317c17dcf9bfb3d17be179..HEAD --format="[%ad] %h %s" --date=format:"%Y-%m-%d %H:%M:%S"

```
[2025-03-23 23:13:28] ed385f1 fix: logging and stair positioning
[2025-03-23 22:49:38] d3d66ab fix: spawn monsters on newer levels
[2025-03-23 22:46:14] 0f96368 Exit on CTRL+C; bring back Logger to files
[2025-03-23 22:40:48] f455e33 SUCCESS: Movement + Level Transition
[2025-03-23 22:21:44] 1fe22c7 WIP: We have movement! But no Level transition
[2025-03-23 21:37:55] f9b9100 WIP: better rendering of the map, still no movement
[2025-03-23 21:31:14] 3bc6033 WIP: rendered screen, no movement, broken map
[2025-03-23 21:22:45] d64d694 wip: getting somewhere visually
[2025-03-23 21:04:52] b817506 WIP: no misalignment but no walkable map
[2025-03-23 20:14:36] 7ca17ee add script to combine all files into a single file
[2025-03-23 18:25:55] d931d07 fix: remove monkey patching, we do not use arrows
[2025-03-23 18:12:56] a33929b WIP: 3rd attempt
[2025-03-23 17:55:25] f9883c0 WIP: second attempt
[2025-03-23 17:41:35] cdf17e2 WIP: render
[2025-03-23 17:04:42] e45a205 Refactor game loop to restore turn-based mechanics and fix input/rendering issues
[2025-03-23 15:30:37] 1096d51 refactor: move keyboard away from World class
[2025-03-23 14:43:04] 6d08051 BREAKINGPOINT: Game renders but stays in a loop, prevents input
[2025-03-23 14:38:02] 8fe0658 cleanup: make sure that stairs character uses is %
[2025-03-23 14:37:10] 646067b cleanup: wrong type of characters, just M for Monster
[2025-03-23 14:29:47] 9cae322 cleanup: [Duplication] remove Game class from inside Vanilla module
[2025-03-23 14:13:22] fd929a7 BREAKINGPOINT: working game
```

## Key Challenges

### Stability Issues
- **Problem**: Frequent crashes disrupted gameplay and development (e.g., infinite recursion in movement logic).
- **Root Cause**: Tight coupling between components led to unpredictable failures when modifying code.

### Core Feature Failures
- **Problem**: Player couldn’t move, stairs didn’t transition levels, and new levels lacked monsters.
- **Impact**: Blocked user experience and feature expansion.

### Design Drift
- **Problem**: Deviations from pure ECS introduced complexity, reducing maintainability.
- **Example**: Logic embedded in `LevelGenerator` and `Game` classes.

## Resolutions Implemented

### Stabilization
- Fixed crashes by replacing recursive logging with explicit data (e.g., movement coordinates).
- Added error handling and fallbacks (e.g., random stairs placement if path calculation failed).

### Feature Restoration
- Restored player movement with single-key responsiveness and `Ctrl+C` exit.
- Enabled immediate level transitions via event-driven commands.
- Reintroduced monster spawning on new levels, tied to difficulty.

### Code Refactoring
- Rewrote ~500 lines across key files (`Game`, `LevelGenerator`, `MovementSystem`, etc.) for robustness.
- Adjusted `BinaryTree` algorithm for better maze connectivity.

## Outcomes

### Current State
- **Gameplay**: Playable—player moves, transitions levels, encounters monsters.

### Metrics
- Resolved >10 critical bugs.
- Reduced crash frequency from 100% to 0% with seed `84620216499580564730520055512755805833`.
- Restored core features in ~20 iterative fixes.

### Remaining Gaps
- **Monster Positions**: Vary despite a fixed seed (fix in progress).
- **Event Logging**: JSONL logging disabled, impacting analytics.


## Overview and Recommendations

### Overview
The game has progressed from a broken state at the BREAKINGPOINT commit (`bcbe5c5f6`) to a playable version through extensive debugging and refactoring over 9+ hours. Core functionality—movement, level transitions, and monster spawning—has been restored, with crashes eliminated. However, two key gaps remain: inconsistent monster spawning positions despite a fixed seed and the disabling of JSONL event logging. These issues, alongside lingering entangled responsibilities from rushed fixes, pose risks to reproducibility, analytics, and long-term maintainability.

### Known Issues and Recommendations
1. **Monster Position Inconsistency**
   - **Issue**: Monsters no longer spawn at predictable locations when using a fixed seed, undermining procedural generation reliability.
   - **Impact**: Breaks reproducibility, affecting testing and player experience consistency.
   - **Recommendation**: Audit the `LevelGenerator` and monster spawning logic to ensure the random number generator (RNG) is properly seeded and isolated from external state changes. Implement unit tests with the known seed (`84620216499580564730520055512755805833`) to verify consistent outputs. Prioritize this fix to restore deterministic behavior.

2. **Disabled Event Logging (JSONL)**
   - **Issue**: JSONL logging, critical for analytics and debugging, was disabled during stabilization efforts (e.g., commit `ed385f1`).
   - **Impact**: Limits insight into gameplay events, hindering future optimization and bug tracking.
   - **Recommendation**: Re-enable JSONL logging by integrating it into the `Logger` system (restored in `0f96368`). Ensure it’s lightweight (e.g., append-only writes) to avoid performance hits. Test with high event volumes to confirm stability, then reintroduce analytics hooks for key actions (e.g., movement, level transitions).

3. **Entangled Responsibilities**
   - **Issue**: Rushed fixes mixed concerns across components (e.g., `Game`, `MovementSystem`), deviating from ECS principles.
   - **Impact**: Increases technical debt, risking a spread of bad practices.
   - **Recommendation**: Schedule a follow-up refactoring sprint to disentangle logic. Move non-ECS code into dedicated systems (e.g., `StairPlacementSystem`, `MonsterSpawnSystem`) and enforce strict component boundaries. Document ECS guidelines to prevent future drift.

### Next Steps
Prioritize the monster position fix within the next development cycle due to its impact on core gameplay consistency. Re-enable event logging concurrently, as it’s a low-effort, high-value addition. Address entangled responsibilities as a medium-term goal post-stabilization to ensure scalable growth. These actions will solidify the game’s foundation, enabling confident feature expansion.

