# BUG: 0001 Inventory Menu Display Needs Improvement

## Status
**Open** - Needs Investigation

## Priority
**Medium** - UI/UX issue affecting user experience

## Description

The inventory menu display in the Messages screen has several formatting issues that create unnecessary noise and confusion for players.

## Current Behavior

### Initial Inventory View

```
+-------------------------------------------------------+
| Messages (Turn 81):                                   |
| - Inventory Items:                                     |
| - Inventory                                            |
| Options:                                               |
| 1) 1) Apple                                            |
| i) Inventory (1 items) [i]                             |
| m) Close Menu                                          |
+-------------------------------------------------------+
```

### After Selecting Item (e.g., pressing "1" for Apple)

```
+-------------------------------------------------------+
| Messages (Turn 81):                                   |
| - What would you like to do with Apple?                |
| - Inventory Items:                                     |
| Options:                                               |
| 1) 1) Use Apple                                        |
| 2) 2) Drop Apple                                       |
| b) b) Back to inventory                                |
| m) Close Menu                                          |
+-------------------------------------------------------+
```

## Expected Behavior

### Initial Inventory View

```
+-------------------------------------------------------+
| Messages (Turn 81):                                   |
|                                                              |
| Options:                                               |
| [1] Apple                                            |
| [i] Inventory (1 items)                             |
| [m] Close Menu                                          |
+-------------------------------------------------------+
```

### After Selecting Item

```
+-------------------------------------------------------+
| [Inventory]                                   |
| What would you like to do with Apple?                |
|                                                                |
| Options:                                               |
| [1] Use Apple                                        |
| [2] Drop Apple                                       |
| [b] Back to inventory                                |
| [m] Close Menu                                          |
+-------------------------------------------------------+
```

## Issues Identified

1. **Redundant Numbering**: Options show "1) 1) Apple" instead of "[1] Apple"
2. **Unnecessary Headers**: "- Inventory Items:" and "- Inventory" add visual noise
3. **Inconsistent Formatting**: Mix of parentheses `1)` and brackets `[i]`
4. **Title Context**: Should show "[Inventory]" when viewing item actions, not "Messages"
5. **Cluttered Display**: Too much redundant information makes it harder to scan options

## Improvements Needed

1. Change title to "[Inventory]" when viewing item actions (not "Messages")
2. Remove redundant numbering (use `[1]` not `1) 1)`)
3. Remove unnecessary section headers ("- Inventory Items:", "- Inventory")
4. Use consistent bracket formatting for all options: `[key]`
5. Cleaner, less cluttered display with better visual hierarchy

## Files to Investigate

- `lib/vanilla/systems/inventory_render_system.rb`
- Message system rendering code
- Inventory menu state management

## Related Systems

- Inventory System
- Message System
- Render System

## Notes

This is a UI/UX polish issue that affects the clarity of the inventory interface. The current implementation works functionally but creates unnecessary visual noise that makes it harder for players to understand their options.

