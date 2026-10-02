# Loot System - Proposal 003

## Overview

When a player kills a monster, there's a chance for loot to drop. The player can choose to pick it up or leave it. Loot includes gold coins and consumable items like apples.

## Requirements

### Loot Generation
- **Gold Coins**: 90% chance, amount between 1-10 coins
- **Apple**: 1 apple (or nothing)
- **Nothing**: Possible outcome

### Loot Drop Rules
- Loot is generated when a monster dies
- Loot appears at the monster's death location
- Player sees a message with options to pick up or ignore

### Apple Mechanics
- Apple is a consumable item
- When eaten, restores HP (up to max HP)
- Can be stored in inventory

### User Flow
1. Player kills monster
2. If loot drops, show message: "Loot dropped! Pick up? [1] Yes [2] No"
3. If player picks up:
   - Add gold to player (if any)
   - Add apple to inventory (if any)
   - Show message: "You picked up: X gold, Y apple(s)"
4. If player ignores, loot remains on ground

## Architecture

### New Components
- **LootComponent**: Stores loot data (gold amount, items)
- **CurrencyComponent**: Tracks player gold (already exists)

### New Systems
- **LootSystem**: Generates loot when monster dies
- **LootPickupSystem**: Handles loot pickup logic

### Modified Systems
- **CombatSystem**: Emit loot event when monster dies
- **MessageSystem**: Handle loot drop messages and pickup menu

## TDD Plan

### Phase 1: Loot Generation (TDD)
**Tests:**
- `spec/lib/vanilla/systems/loot_system_spec.rb`
  - Test gold generation (90% chance, 1-10 coins)
  - Test apple generation
  - Test nothing drops
  - Test loot generation probabilities

**Implementation:**
- Create `LootSystem`
- Implement `generate_loot` method
- Integrate with `CombatSystem` death event

### Phase 2: Loot Drop Event (TDD)
**Tests:**
- `spec/lib/vanilla/systems/message_system_loot_spec.rb`
  - Test loot drop message appears
  - Test pickup menu options
  - Test ignore option

**Implementation:**
- Add loot drop event handling in `MessageSystem`
- Create loot pickup menu
- Handle pickup/ignore callbacks

### Phase 3: Loot Pickup (TDD)
**Tests:**
- `spec/lib/vanilla/systems/loot_pickup_system_spec.rb`
  - Test gold is added to player
  - Test apple is added to inventory
  - Test pickup message shows correct items

**Implementation:**
- Create `LootPickupSystem`
- Implement pickup logic
- Add gold to player currency
- Add items to inventory

### Phase 4: Apple Consumption (TDD)
**Tests:**
- `spec/lib/vanilla/components/consumable_component_spec.rb` (if needed)
- `spec/lib/vanilla/systems/item_use_system_spec.rb`
  - Test apple restores HP
  - Test HP doesn't exceed max
  - Test apple is consumed after use

**Implementation:**
- Ensure apple has consumable component
- Implement HP restoration effect
- Test apple use in inventory

### Phase 5: Integration Tests
**Tests:**
- `spec/integration/loot_spec.rb`
  - Test full flow: kill monster -> loot drops -> pick up -> use apple
  - Test loot appears at monster position
  - Test multiple loot items

## Message System Integration

### New Messages
```yaml
loot:
  dropped: "Loot dropped! Pick up?"
  picked_up: "You picked up: %{items}"
  ignored: "You leave the loot behind."
  gold: "%{amount} gold"
  apple: "%{count} apple(s)"
```

### Menu Options
```ruby
options: [
  { key: '1', content: "Pick up loot [1]", callback: :pickup_loot },
  { key: '2', content: "Leave loot [2]", callback: :ignore_loot }
]
```

## Implementation Details

### Loot Generation Algorithm
```ruby
def generate_loot
  loot = { gold: 0, items: [] }
  
  # 90% chance for gold (1-10 coins)
  if rand < 0.9
    loot[:gold] = rand(1..10)
  end
  
  # Small chance for apple
  if rand < 0.3  # 30% chance
    loot[:items] << create_apple
  end
  
  loot
end
```

### Loot Drop Location
- Loot appears at monster's death position
- Player must be at that position to pick up (or auto-pickup on collision)

## Testing Strategy

1. **Unit Tests**: Test loot generation probabilities
2. **Integration Tests**: Test full loot flow
3. **Edge Cases**: 
   - No loot drops
   - Only gold drops
   - Only apple drops
   - Both drop
   - Inventory full when picking up apple

