# Debugging Tools for Monster Movement

This document outlines the proposed tools and systems for effectively debugging monster movement in the Vanilla game.

## 1. Enhanced Logging System

### Objective
Provide detailed, filterable logs that track monster behavior for analysis.

### Implementation
- **Dedicated Debug Level**: Add a `MONSTER_DEBUG` log level to isolate monster-related logging
- **Position Tracking**: Log all position changes with before/after coordinates
- **Movement Decisions**: Log decision-making process (why a monster chose a particular direction)
- **Collision Detection**: Record when movement is blocked and why (wall, other monster, etc.)
- **Log Rotation**: Ensure logs are properly rotated to prevent massive files

### Example Usage
```ruby
@logger.monster_debug("Monster #{id} at [#{old_x},#{old_y}] attempting move to [#{new_x},#{new_y}]")
@logger.monster_debug("Movement blocked: encountered wall at [#{wall_x},#{wall_y}]")
```

## 2. Visual Debugging Tools

### Objective
Provide visual feedback within the game UI to observe monster behavior.

### Implementation
- **Debug Mode Toggle**: Add a debug mode that can be activated with a keypress (e.g., F12)
- **Highlighted Cells**: Highlight cells that monsters are targeting
- **Movement Visualization**:
  - Green arrows for valid moves
  - Red markers for blocked moves
  - Yellow highlighting for monster detection radius
- **Cell State Display**: Tooltip showing detailed cell information on hover

### Example UI
```
  0 1 2 3 4
0 # # # # #
1 #   M→⚠ #
2 # #⬆# @ #
3 #   ⬆   #
4 # # # # #
```
*(M: monster, @: player, →: attempted move, ⚠: blocked)*

## 3. Step-by-Step Execution

### Objective
Allow fine-grained control over game execution for isolated testing.

### Implementation
- **Single-Step Mode**: Advance game one turn at a time (space bar)
- **System Isolation**: Enable/disable specific systems (toggle monster movement only)
- **Monster Commands**:
  - Force a specific monster to attempt movement (`/move monster_id direction`)
  - Reset monster positions (`/reset_monsters`)

### Example Commands
```
/step                    - Advance one game turn
/toggle_system monster   - Disable/enable monster system
/move monster_1 north    - Force monster_1 to move north
```

## 4. State Inspection

### Objective
Provide tools to examine the game state at any point during execution.

### Implementation
- **Debug Console**: In-game console activated with a keypress (e.g., ~ key)
- **State Queries**:
  - List all monsters with positions (`/list_monsters`)
  - Show cell information (`/cell 3,4`)
  - Show entity details (`/entity monster_2`)
- **State Snapshots**:
  - Capture grid state before/after movement
  - Compare snapshots to identify changes

### Example Console Output
```
> /cell 3,4
Cell [3,4]:
- Tile: EMPTY
- Linked to: [3,3], [3,5], [2,4]
- Entities: none

> /entity monster_2
Monster 2:
- Type: Goblin
- Position: [1,3]
- Health: 12/12
- Target: Player (distance: 3)
- Last move: East (2 turns ago)
```

## 5. Automated Testing

### Objective
Create a comprehensive test suite to verify movement logic works correctly.

### Implementation
- **Unit Tests**:
  - Test `valid_move?` with various cell conditions
  - Test monster AI decision making with mocked player positions
- **Integration Tests**:
  - Test movement on predefined maze configurations
  - Test interactions between multiple monsters
- **Regression Tests**:
  - Create specific tests for bugs that were fixed
  - Ensure edge cases are covered

### Example Test Cases
```ruby
describe "Monster movement" do
  it "cannot move through walls" do
    # Setup a grid with walls
    # Place monster adjacent to wall
    # Attempt to move through wall
    # Verify position unchanged
  end

  it "moves towards player when in sight" do
    # Setup grid with clear path
    # Place monster and player within sight
    # Update monster
    # Verify monster moved towards player
  end
end
```

## 6. Performance Monitoring

### Objective
Ensure monster movement algorithms are efficient, especially at scale.

### Implementation
- **CPU Profiling**:
  - Track time spent in monster system update
  - Identify hotspots in the movement algorithm
- **Memory Tracking**:
  - Monitor object allocations during monster updates
  - Check for memory leaks with repeated movements
- **Scaling Tests**:
  - Benchmark performance with increasing monster counts
  - Test movement algorithms with different grid sizes

### Example Metrics
```
Monster System Performance:
- Avg update time: 3.2ms
- Monster count: 25
- Updates per second: 312
- Memory allocated per update: 128KB
```

## 7. Implementation Plan

### Phase 1: Foundation
1. Enhance logging system with monster-specific levels
2. Implement basic state inspection via console commands
3. Add simple step-by-step execution mode

### Phase 2: Visual Tools
1. Develop debug rendering mode
2. Implement cell highlighting and movement visualization
3. Create monster path visualization

### Phase 3: Testing & Optimization
1. Build comprehensive test suite
2. Implement performance monitoring
3. Create regression tests for known issues

## Conclusion

These debugging tools will provide comprehensive visibility into monster movement logic, making it easier to identify and fix issues. The most important initial steps are enhancing the logging system and implementing the step-by-step execution mode, as these will provide immediate benefits with relatively low implementation effort.