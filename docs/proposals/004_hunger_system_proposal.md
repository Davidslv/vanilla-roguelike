# Hunger System - Proposal 004

## Overview

Implement a hunger system where the player's hunger increases over time, and when hungry, the player loses HP if they don't eat. This adds a survival element to the game, making food items (like apples from loot) more valuable.

## Requirements

### Hunger Mechanics
- **Hunger State**: Player has a hunger level that increases over time
- **Hunger Threshold**: When hunger reaches a certain level, player is considered "hungry"
- **HP Loss**: When hungry and player doesn't eat, lose 1 HP every 5 movements
- **Feeding**: Eating food items (e.g., apples) reduces hunger
- **Hunger Display**: Show hunger status in game UI (optional, can be added later)

### Hunger Progression
- Hunger increases by 1 every N movements (configurable, e.g., every 10 movements)
- Hunger levels:
  - 0-30: Not Hungry (normal state)
  - 31-60: Hungry (warning state, no HP loss yet)
  - 61-100: Starving (lose 1 HP every 5 movements)
- Maximum hunger: 100 (player dies if HP reaches 0)

### Food Consumption
- Apples restore hunger by 20 points
- Other food items can be added later with different hunger restoration values

## Architecture

### New Components
- **HungerComponent**: Tracks hunger level (0-100), hunger increase rate, movement counter

### New Systems
- **HungerSystem**: 
  - Increases hunger over time (based on movement)
  - Checks if player is hungry/starving
  - Triggers HP loss when starving and player moves

### Modified Systems
- **MovementSystem**: Emit hunger-related events on movement
- **ItemUseSystem**: Reduce hunger when food items are consumed
- **MessageSystem**: Display hunger warnings and starvation messages
- **RenderSystem**: Display hunger status (optional, Phase 2)

## TDD Plan

### Phase 1: Hunger Component (TDD)
**Tests:**
- `spec/lib/vanilla/components/hunger_component_spec.rb`
  - Test initialization with default values
  - Test hunger level bounds (0-100)
  - Test hunger increase/decrease methods
  - Test hunger state checks (not_hungry?, hungry?, starving?)
  - Test movement counter increment
  - Test serialization

**Implementation:**
- Create `HungerComponent` with:
  - `hunger_level` (0-100)
  - `movement_counter` (tracks movements for HP loss)
  - `hunger_increase_rate` (movements before hunger increases)
  - `hp_loss_interval` (movements before HP loss when starving)

### Phase 2: Hunger System (TDD)
**Tests:**
- `spec/lib/vanilla/systems/hunger_system_spec.rb`
  - Test hunger increases after N movements
  - Test hunger doesn't increase when already at max
  - Test movement counter increments
  - Test HP loss when starving (every 5 movements)
  - Test HP loss doesn't occur when not starving
  - Test HP loss doesn't reduce HP below 0
  - Test hunger state transitions

**Implementation:**
- Create `HungerSystem`
- Subscribe to `:entity_moved` events
- Track movement count per entity with hunger component
- Increase hunger after N movements
- Check if entity is starving and trigger HP loss every 5 movements
- Emit `:hunger_increased`, `:hunger_starving`, `:hunger_hp_lost` events

### Phase 3: Food Consumption Integration (TDD)
**Tests:**
- `spec/lib/vanilla/systems/item_use_system_hunger_spec.rb`
  - Test eating apple reduces hunger by 20
  - Test hunger doesn't go below 0
  - Test eating food when not hungry still works
  - Test eating food stops starvation

**Implementation:**
- Modify `ItemUseSystem` or `ConsumableComponent` effects
- Add `:reduce_hunger` effect type
- Apply hunger reduction when food items are consumed
- Emit `:hunger_reduced` event

### Phase 4: Message System Integration (TDD)
**Tests:**
- `spec/lib/vanilla/systems/message_system_hunger_spec.rb`
  - Test hunger warning message when becoming hungry
  - Test starvation warning message
  - Test HP loss message when starving
  - Test hunger reduced message when eating

**Implementation:**
- Subscribe to hunger events in `MessageSystem`
- Add messages for:
  - Hunger warnings
  - Starvation warnings
  - HP loss from starvation
  - Hunger restored from eating

### Phase 5: Integration Tests
**Tests:**
- `spec/integration/hunger_spec.rb`
  - Test full flow: movement -> hunger increase -> starvation -> HP loss
  - Test eating food stops starvation
  - Test player death from starvation
  - Test hunger resets after eating

## Message System Integration

### New Messages
```yaml
hunger:
  increased: "You feel a bit hungry..."
  hungry: "You are getting hungry!"
  starving: "You are starving! Find food soon!"
  hp_lost: "You lose 1 HP from starvation!"
  restored: "You feel less hungry after eating."
  full: "You are no longer hungry."
```

### Hunger States
- **Not Hungry** (0-30): No messages
- **Hungry** (31-60): Warning message when crossing threshold
- **Starving** (61-100): Warning message + HP loss messages

## Implementation Details

### HungerComponent Structure
```ruby
class HungerComponent
  attr_accessor :hunger_level, :movement_counter
  attr_reader :hunger_increase_rate, :hp_loss_interval
  
  def initialize(
    hunger_level: 0,
    hunger_increase_rate: 10,  # Increase hunger every 10 movements
    hp_loss_interval: 5         # Lose HP every 5 movements when starving
  )
    @hunger_level = hunger_level.clamp(0, 100)
    @movement_counter = 0
    @hunger_increase_rate = hunger_increase_rate
    @hp_loss_interval = hp_loss_interval
  end
  
  def not_hungry?
    @hunger_level <= 30
  end
  
  def hungry?
    @hunger_level > 30 && @hunger_level <= 60
  end
  
  def starving?
    @hunger_level > 60
  end
  
  def increase(amount = 1)
    @hunger_level = [@hunger_level + amount, 100].min
  end
  
  def decrease(amount = 1)
    @hunger_level = [@hunger_level - amount, 0].max
  end
end
```

### HungerSystem Logic
```ruby
def update(_dt)
  # Process movement events for entities with hunger component
  # Increase hunger after N movements
  # Check starvation and trigger HP loss
end

def handle_entity_moved(event)
  entity = @world.get_entity(event[:entity_id])
  return unless entity&.has_component?(:hunger)
  
  hunger = entity.get_component(:hunger)
  hunger.movement_counter += 1
  
  # Increase hunger every N movements
  if hunger.movement_counter >= hunger.hunger_increase_rate
    old_level = hunger.hunger_level
    hunger.increase(1)
    hunger.movement_counter = 0
    
    # Check state transitions
    check_hunger_state_transition(entity, old_level, hunger.hunger_level)
  end
  
  # Check HP loss when starving
  if hunger.starving?
    check_starvation_hp_loss(entity, hunger)
  end
end

def check_starvation_hp_loss(entity, hunger)
  # Lose HP every 5 movements when starving
  if hunger.movement_counter >= hunger.hp_loss_interval
    health = entity.get_component(:health)
    return unless health
    
    old_hp = health.current_health
    health.current_health = [health.current_health - 1, 0].max
    hunger.movement_counter = 0  # Reset counter after HP loss
    
    if health.current_health < old_hp
      @world.emit_event(:hunger_hp_lost, {
        entity_id: entity.id,
        hp_lost: 1,
        current_hp: health.current_health
      })
    end
  end
end
```

### Food Item Integration
```ruby
# In LootSystem or ItemUseSystem
# When apple is consumed, add hunger reduction effect:
effects: [
  { type: :heal, amount: 20 },
  { type: :reduce_hunger, amount: 20 }  # New effect type
]
```

## Testing Strategy

1. **Unit Tests**: Test hunger component logic, state checks, bounds
2. **System Tests**: Test hunger system movement tracking, HP loss timing
3. **Integration Tests**: Test full hunger cycle with food consumption
4. **Edge Cases**:
   - Hunger at max (100)
   - Hunger at 0
   - HP at 1 (shouldn't go below 0)
   - Eating when not hungry
   - Multiple movements in quick succession

## Implementation Phases

### Phase 1: Core Hunger Component (TDD)
- Create `HungerComponent` with all state management
- Add to player in `EntityFactory`
- Write comprehensive tests

### Phase 2: Hunger System (TDD)
- Create `HungerSystem`
- Implement movement tracking
- Implement hunger increase logic
- Implement starvation HP loss
- Write tests for all scenarios

### Phase 3: Food Integration (TDD)
- Add hunger reduction to food items
- Update `ItemUseSystem` to handle hunger effects
- Test food consumption reduces hunger

### Phase 4: Messages (TDD)
- Add hunger event handlers to `MessageSystem`
- Add translation keys
- Test message display

### Phase 5: Integration & Polish
- Full integration tests
- Balance hunger rates
- Optional: Add hunger display to UI

## Configuration

Hunger system should be configurable:
- `hunger_increase_rate`: Movements before hunger increases (default: 10)
- `hp_loss_interval`: Movements before HP loss when starving (default: 5)
- `hunger_thresholds`: When player becomes hungry/starving (default: 30/60)
- `food_hunger_restore`: How much hunger food restores (apple: 20)

## Future Enhancements

- Different food types with different hunger restoration
- Hunger display in game UI (status bar)
- Hunger-based debuffs (slower movement when starving)
- Food spoilage system
- Cooking system to create better food

