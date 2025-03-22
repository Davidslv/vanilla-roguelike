# Component and System Inventory

This document catalogs all existing components, systems, and entities in the Vanilla roguelike game, along with notes on their current state and what needs to be refactored according to our ECS standards.

## Components

| Component | Current State | Issues | Refactoring Needed |
|-----------|--------------|--------|-------------------|
| Component (Base) | Base class for all components | - May not enforce pure data pattern<br>- Might allow behavior | - Ensure it enforces data-only pattern<br>- Add proper type registration |
| ConsumableComponent | Represents consumable items | - May contain behavior<br>- Might directly modify other components | - Remove behavior<br>- Use event system for effects |
| CurrencyComponent | Represents money/currency | - Limited information available | - Ensure it's pure data<br>- Add proper accessors |
| DurabilityComponent | Represents item durability | - Limited information available | - Ensure it's pure data<br>- Add proper accessors |
| EffectComponent | Represents effects/buffs | - May contain behavior<br>- Might directly modify other components | - Remove behavior<br>- Use event system for applying effects |
| Entity | Entity implementation | - Located in components folder<br>- May contain game logic | - Move to proper location<br>- Remove any game logic<br>- Make pure component container |
| EquippableComponent | Represents equippable items | - May contain behavior<br>- Might directly modify other components | - Remove behavior<br>- Use event system for equip/unequip effects |
| InventoryComponent | Represents inventory storage | - May contain behavior<br>- Might directly modify state | - Remove behavior<br>- Add proper accessors<br>- Use events for changes |
| ItemComponent | Represents items | - May contain behavior | - Remove behavior<br>- Add proper accessors |
| KeyComponent | Represents keys (for doors?) | - Limited information available | - Ensure it's pure data<br>- Add proper accessors |
| MovementComponent | Represents movement capabilities | - May contain behavior | - Remove behavior<br>- Add proper accessors |
| PositionComponent | Represents entity position | - Missing `set_position` method<br>- May contain behavior | - Add proper encapsulation<br>- Add accessors like `set_position` |
| RenderComponent | Represents visual appearance | - May contain rendering behavior | - Remove behavior<br>- Keep only appearance data |
| StairsComponent | Represents stairs state | - May contain behavior | - Remove behavior<br>- Add proper accessors |
| TileComponent | Represents tile types | - May contain behavior | - Remove behavior<br>- Add proper accessors |

## Systems

| System | Current State | Issues | Refactoring Needed |
|--------|--------------|--------|-------------------|
| InventoryRenderSystem | Renders inventory UI | - May directly call other systems<br>- May bypass component interface | - Use event system<br>- Access components properly |
| InventorySystem | Manages inventory operations | - May directly call other systems<br>- May bypass component interface | - Use event system<br>- Access components properly |
| ItemInteractionSystem | Handles item pickups/usage | - May directly call other systems<br>- May bypass component interface | - Use event system<br>- Access components properly |
| MonsterSystem | Manages monsters | - May directly call other systems<br>- May bypass component interface | - Use event system<br>- Access components properly |
| MovementSystem | Handles entity movement | - May directly call other systems<br>- May bypass component interface | - Use event system<br>- Access components properly |
| RenderSystem | Renders game state | - May have parameter inconsistencies<br>- May bypass component interface | - Fix parameter handling<br>- Access components properly |
| RenderSystemFactory | Creates render systems | - Factory pattern is good | - Ensure it follows standards |

## Entities

| Entity | Current State | Issues | Refactoring Needed |
|--------|--------------|--------|-------------------|
| Monster | Monster entity | - May contain game logic<br>- May bypass component interface | - Remove behavior<br>- Convert to factory pattern<br>- Make pure component container |
| Player | Player entity | - May contain game logic<br>- May bypass component interface | - Remove behavior<br>- Convert to factory pattern<br>- Make pure component container |
| Stairs | Stairs entity | - May contain game logic<br>- May bypass component interface | - Remove behavior<br>- Convert to factory pattern<br>- Make pure component container |

## Missing Components

Based on our standards, the following components may be needed:

1. **HealthComponent** - To store entity health data
2. **CombatComponent** - To store attack/defense attributes
3. **AIComponent** - To store AI state and behavior parameters
4. **InputComponent** - To store pending input actions

## Missing Systems

Based on our standards, the following systems may be needed:

1. **InputSystem** - To process user input
2. **CombatSystem** - To handle combat mechanics
3. **AISystem** - To control non-player entity behavior
4. **CollisionSystem** - To detect and respond to collisions
5. **LevelSystem** - To manage level generation and transitions
6. **MessageSystem** - To handle game message logging (may exist elsewhere)
7. **WorldSystem** - To manage the overall world state

## World Implementation

The central World class that would manage entities and systems appears to be missing or is implemented differently. This is a critical component for proper ECS and needs to be implemented as specified in our standards.

## Game Class

The Game class needs to be examined to ensure it:
1. Creates and maintains the World instance
2. Exposes access to key elements like current level, player, etc.
3. Manages the main game loop
4. Handles initialization and cleanup

## Next Steps

1. Start by implementing proper access methods for the Game class
2. Refactor the PositionComponent to add `set_position` method
3. Address parameter inconsistencies in the MessageSystem and RenderSystem
4. Work on removing behavior from components
5. Implement the World class with proper event handling
6. Convert entity classes to factory functions
7. Implement missing systems and components
8. Update tests to verify compliance with standards