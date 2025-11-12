# Critical Review: Item Usage and Effects System Proposal 006

## Executive Summary

**Status: NOT READY FOR IMPLEMENTATION**

While the codebase has a solid foundation with existing inventory, item, and equipment systems, there are **significant architectural mismatches** between the current implementation and the proposal. The proposal appears to have been written without full knowledge of the existing codebase structure.

**Estimated Pre-Implementation Work: 2-3 days**
**Risk Level: HIGH** - Many breaking changes required

---

## Critical Issues

### 1. Component Architecture Mismatch

#### ItemComponent
**Current State:**
- Has: `name`, `description`, `item_type`, `weight`, `value`, `stackable`, `stack_size`
- Missing: `identified`, `cursed`, `display_name`, `unknown_name`
- Different: Uses `item_type` instead of `type`

**Proposal Expects:**
- `name`, `type`, `identified`, `cursed`, `quantity`
- `display_name` method that returns `identified ? name : unknown_name`
- `stackable?` method based on type

**Required Work:**
- Add `identified` and `cursed` attributes (default false)
- Add `display_name` method with identification logic
- Add `unknown_name` generation logic (color-based for potions, random labels for scrolls)
- Rename `item_type` to `type` OR maintain both for backward compatibility
- Change `stack_size` to `quantity` OR maintain both

#### ConsumableComponent
**Current State:**
- Has: `charges`, `effects` (Array of hashes), `auto_identify`
- Structure: `effects = [{ type: :heal, amount: 20, duration: 0 }]`

**Proposal Expects:**
- `effect_type` (single symbol), `effect_magnitude` (single value), `target_type`
- Structure: Single effect per consumable

**Required Work:**
- **DECISION NEEDED**: Keep array-based effects (more flexible) OR switch to single effect (simpler)
- If keeping array: Add adapter methods `effect_type`, `effect_magnitude`, `target_type` that read from first effect
- If switching: Breaking change - refactor all existing consumables
- Add `target_type` support (`:self`, `:monster`, `:area`)

#### EquippableComponent vs EquipmentComponent
**Current State:**
- Component name: `EquippableComponent`
- Slots: `[:head, :body, :left_hand, :right_hand, :both_hands, :neck, :feet, :ring, :hands]`
- Has: `slot`, `stat_modifiers`, `equipped`
- Missing: `bonus` (enchantment level)

**Proposal Expects:**
- Component name: `EquipmentComponent`
- Slots: `[:weapon, :armor, :ring_left, :ring_right]`
- Has: `slot`, `bonus`, `equipped`, `stat_modifiers`

**Required Work:**
- **MAJOR DECISION**: Rename component OR create new one?
- **MAJOR DECISION**: Slot system redesign - current system is more flexible (multiple slots) but proposal wants simpler 4-slot system
- Add `bonus` attribute for enchantment levels
- Map existing slots to new system OR support both

### 2. Missing Components

#### EquippedItemsComponent
**Status: DOES NOT EXIST**

**Proposal Requires:**
- Component to track equipped items separately from inventory
- Methods: `equip(item, slot)`, `unequip(slot)`, `slot_occupied?(slot)`
- Attributes: `weapon`, `armor`, `ring_left`, `ring_right`

**Current Workaround:**
- EquipmentSystem searches inventory for equipped items
- No centralized tracking of equipped items

**Required Work:**
- Create new `EquippedItemsComponent`
- Add to player entity on creation
- Refactor EquipmentSystem to use it
- Update InventorySystem to check equipped items

#### WandComponent
**Status: DOES NOT EXIST**

**Proposal Requires:**
- `effect_type`, `charges`, `max_charges`, `damage`
- `use_charge`, `depleted?` methods

**Required Work:**
- Create new component
- Implement charge management
- Integrate with ItemUseSystem

#### StatusEffectComponent vs EffectComponent
**Current State:**
- `EffectComponent` exists with different API
- Has: `active_effects` (array), `add_effect(type, value, duration, source, metadata)`
- Has: `get_stat_modifier(stat)`, `remove_expired_effects`, `update`

**Proposal Expects:**
- `StatusEffectComponent` with `effects` array
- `add_effect(type, magnitude, duration)`
- `tick` method
- `active?(effect_type)` method

**Required Work:**
- **DECISION**: Rename `EffectComponent` to `StatusEffectComponent` OR create new one
- Align API differences (current is more feature-rich)
- Ensure backward compatibility if renaming

#### ItemIdentificationComponent
**Status: DOES NOT EXIST**

**Proposal Requires:**
- Global state tracking of identified item types
- `identified_items` (Set)
- `identify(item_type)`, `identified?(item_type)`

**Required Work:**
- Create new component
- Attach to game state entity (may need to create if doesn't exist)
- Implement identification persistence

### 3. System Architecture Mismatch

#### ItemUseSystem vs ItemEffectSystem
**Current State:**
- `ItemUseSystem` processes `:use_item` commands from queue
- Handles consumables with effects array
- Removes item when charges depleted

**Proposal Expects:**
- `ItemEffectSystem` (different name)
- Processes `UseItemCommand` objects
- Handles single effect_type per consumable
- More comprehensive effect handling (teleport, confuse, etc.)

**Required Work:**
- **DECISION**: Rename system OR create new one
- Extend effect handling to support all proposal effects
- Add support for target selection (monsters, areas)
- Integrate with teleportation system

#### EquipmentSystem
**Current State:**
- Processes `:toggle_equip` commands from queue
- Only toggles `equipped` flag
- Does NOT apply/remove stat modifiers
- Does NOT check for cursed items
- Does NOT use EquippedItemsComponent

**Proposal Expects:**
- Processes `EquipItemCommand` and `UnequipItemCommand`
- Applies/removes stat modifiers to CombatComponent
- Checks for cursed items on unequip
- Uses EquippedItemsComponent for slot management

**Required Work:**
- Refactor to process command objects instead of symbols
- Add stat modifier application/removal logic
- Add cursed item checking
- Integrate with EquippedItemsComponent
- Add slot conflict resolution

#### StatusEffectSystem
**Status: DOES NOT EXIST**

**Proposal Requires:**
- System to tick status effects each turn
- Process regeneration, poison, buffs
- Priority 2 (runs early in update cycle)

**Current State:**
- `EffectComponent` has `update` method but no system calls it
- Effects expire based on turn count but no active processing

**Required Work:**
- Create new system
- Call `update` on all entities with EffectComponent
- Implement per-turn effect processing (regeneration, poison)
- Register with appropriate priority

#### ItemIdentificationSystem
**Status: DOES NOT EXIST**

**Proposal Requires:**
- System to handle item identification
- Priority 10 (runs late)
- Manages global identification state

**Required Work:**
- Create new system
- Implement identification logic
- Handle identification events
- Persist identification state

### 4. Command Pattern Mismatch

**Current State:**
- Commands are queued as `[command_type, params]` tuples
- Examples: `[:use_item, { entity_id: ..., item_id: ... }]`
- Systems process command queue directly

**Proposal Expects:**
- Command objects (classes inheriting from `Command`)
- Examples: `UseItemCommand.new(item)`, `EquipItemCommand.new(item)`
- Commands have `execute(world)` method

**Required Work:**
- **MAJOR DECISION**: Refactor entire command system OR create adapter layer
- Create command classes: `UseItemCommand`, `EquipItemCommand`, `UnequipItemCommand`, `DropItemCommand`, `IdentifyItemCommand`
- Update World to handle command objects
- Update systems to work with command objects
- OR: Create adapter that converts command objects to queue format

### 5. Combat System Integration

**Current State:**
- `CombatSystem` reads stats directly from `CombatComponent`
- Does NOT read equipment stats
- Does NOT apply equipment modifiers

**Proposal Expects:**
- CombatSystem reads weapon bonuses from equipped weapon
- Reads armor AC from equipped armor
- Applies ring bonuses
- Handles cursed weapon effects

**Required Work:**
- Refactor `calculate_damage` to check equipped weapon
- Refactor to check equipped armor for defense
- Add ring bonus calculation
- Add cursed item effect handling
- Create helper methods to get effective stats (base + equipment)

### 6. Missing Features

#### Item Identification System
- No identification state tracking
- No unknown item names
- No identification methods (use, scroll, merchant)

#### Cursed Items
- No `cursed` attribute on items
- No curse checking on unequip
- No remove curse scroll handling

#### Equipment Stat Application
- Equipment has `stat_modifiers` but they're never applied
- No integration between equipment and combat stats

#### Status Effect Processing
- Effects exist but aren't processed each turn
- No regeneration, poison, or buff processing

---

## Required Pre-Implementation Work

### Phase 1: Component Alignment (1 day)

1. **Extend ItemComponent**
   - Add `identified` and `cursed` attributes
   - Add `display_name` method
   - Add `unknown_name` generation logic
   - Decide on `item_type` vs `type` naming

2. **Align ConsumableComponent**
   - Decide: array-based or single effect?
   - Add `target_type` support
   - Add adapter methods if keeping array

3. **Create Missing Components**
   - `EquippedItemsComponent` - NEW
   - `WandComponent` - NEW
   - `ItemIdentificationComponent` - NEW
   - Decide on `StatusEffectComponent` vs `EffectComponent`

4. **Align EquippableComponent**
   - Add `bonus` attribute
   - Decide on slot system (current vs proposal)

### Phase 2: System Refactoring (1 day)

1. **Command System Decision**
   - Evaluate: Refactor to command objects OR create adapter
   - If refactor: Update World, all systems, all command creation
   - If adapter: Create command object wrappers

2. **EquipmentSystem Enhancement**
   - Add stat modifier application/removal
   - Add cursed item checking
   - Integrate EquippedItemsComponent
   - Add slot conflict resolution

3. **Create Missing Systems**
   - `StatusEffectSystem` - NEW
   - `ItemIdentificationSystem` - NEW
   - Extend `ItemUseSystem` or create `ItemEffectSystem`

4. **CombatSystem Integration**
   - Add equipment stat reading
   - Add effective stat calculation
   - Add cursed item effects

### Phase 3: Testing & Validation (0.5-1 day)

1. **Update Existing Tests**
   - Fix tests broken by component changes
   - Update mocks and stubs

2. **Write Integration Tests**
   - Test equipment stat application
   - Test identification system
   - Test cursed items
   - Test status effects

---

## Recommendations

### Option 1: Align Proposal with Existing Codebase (RECOMMENDED)
**Effort: Low, Risk: Low**

- Keep existing component names (`EquippableComponent`, `EffectComponent`)
- Keep existing slot system (more flexible)
- Keep command queue format (simpler)
- Extend existing systems rather than creating new ones
- Add missing features incrementally

**Pros:**
- Minimal breaking changes
- Leverages existing work
- Faster implementation

**Cons:**
- Proposal needs significant revision
- Some features may be less "pure" than proposal

### Option 2: Implement Proposal As-Is
**Effort: High, Risk: High**

- Rename all components to match proposal
- Refactor command system to use objects
- Create all new systems
- Redesign slot system

**Pros:**
- Matches proposal exactly
- Cleaner architecture (arguable)

**Cons:**
- Many breaking changes
- Significant refactoring required
- Higher risk of bugs
- Longer implementation time

### Option 3: Hybrid Approach
**Effort: Medium, Risk: Medium**

- Keep existing components but add proposal features
- Create adapter layer for commands
- Extend systems incrementally
- Support both slot systems temporarily

**Pros:**
- Balanced approach
- Gradual migration path

**Cons:**
- More complex codebase
- Technical debt

---

## Specific Technical Decisions Needed

1. **Component Naming**: Keep `EquippableComponent` or rename to `EquipmentComponent`?
2. **Slot System**: Keep flexible multi-slot system or simplify to 4 slots?
3. **Command Pattern**: Refactor to objects or keep queue format?
4. **Effect System**: Keep array-based effects or switch to single effect?
5. **Status Effects**: Rename `EffectComponent` or create new `StatusEffectComponent`?
6. **Identification**: Where to store global identification state? (Game state entity?)

---

## Conclusion

The proposal is **well-designed but misaligned** with the existing codebase. The existing inventory system is functional but needs significant extension to match proposal requirements.

**Recommendation: NOT READY** - Complete Phase 1 and Phase 2 work first, then proceed with implementation.

**Alternative: Revise proposal** to align with existing architecture, then implement incrementally.

