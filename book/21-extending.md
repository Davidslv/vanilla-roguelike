# Chapter 21: Extending Your Game

## Adding New Features: The ECS Advantage

ECS makes adding features easy. You add components and systems, not new classes with inheritance hierarchies.

### Adding a New Feature: Flying

Want flying monsters? Just add a component and modify a system:

```ruby
# New component
class FlyingComponent < Component
  def type
    :flying
  end
end

# Modify MovementSystem
def can_move_to?(cell, entity)
  return true if entity.has_component?(:flying)  # Flying entities ignore walls
  return false if cell.links.empty?
  true
end

# Create flying monster
monster = Entity.new
monster.add_component(PositionComponent.new(row: 5, column: 5))
monster.add_component(MovementComponent.new)
monster.add_component(FlyingComponent.new)  # Just add the component
```

No new classes. No inheritance. Just composition.

## New Components: Defining New Capabilities

Adding new capabilities is as simple as creating components:

**Example: Magic System**
```ruby
class ManaComponent < Component
  attr_reader :max_mana, :current_mana

  def initialize(max_mana:)
    @max_mana = max_mana
    @current_mana = max_mana
  end
end

class SpellComponent < Component
  attr_reader :spell_name, :mana_cost, :effect

  def initialize(spell_name:, mana_cost:, effect:)
    @spell_name = spell_name
    @mana_cost = mana_cost
    @effect = effect
  end
end
```

Entities with these components can cast spells. No changes to existing code needed.

## New Systems: Implementing New Behaviors

New behaviors are new systems:

**Example: SpellSystem**
```ruby
class SpellSystem < System
  def cast_spell(caster, spell_name)
    return false unless caster.has_component?(:mana)
    return false unless caster.has_component?(:spell)

    spell = caster.get_component(:spell)
    mana = caster.get_component(:mana)

    return false if mana.current_mana < spell.mana_cost

    mana.current_mana -= spell.mana_cost
    apply_effect(spell.effect)
    true
  end
end
```

Add the system to the world, and it works. No modifications to existing systems.

## Extension Patterns

### Pattern 1: Component + System

Most features follow this pattern:
1. Create component(s) for data
2. Create system for behavior
3. Add system to world
4. Attach components to entities

### Pattern 2: Event-Driven Extension

Extend through events:
1. Subscribe to relevant events
2. React in your system
3. Emit new events if needed

### Pattern 3: Composition

Combine existing components:
- Flying + Combat = Flying warrior
- Item + Consumable = Usable item
- Position + Render = Visible entity

## Real Example: Adding Loot

Vanilla's loot system demonstrates extension:

```ruby
# Component (if needed)
class LootComponent < Component
  attr_reader :gold, :items
end

# System
class LootSystem < System
  def generate_loot
    { gold: rand(10..50), items: [] }
  end
end

# Integration: CombatSystem emits death event
# LootSystem subscribes and generates loot
```

The loot system:
- Doesn't modify combat code
- Subscribes to death events
- Generates loot when monsters die
- Works with existing systems

## Good Architecture Enables Rapid Feature Development

With good architecture:
- **Features are independent**: Add without breaking existing code
- **Systems are reusable**: Use in different contexts
- **Components are composable**: Mix and match capabilities
- **Events enable integration**: Systems work together automatically

## Key Takeaway

ECS makes extending your game easy. Add components for data, systems for behavior. Compose entities from components. Use events for integration. Good architecture enables rapid feature development without breaking existing code.

## Exercises

1. **Design a feature**: Pick a new feature (like magic or crafting). What components and systems would you create?

2. **Extend combat**: How would you add status effects (poison, burning)? What would you add?

3. **Composition challenge**: Design an entity that's a monster, an item, and can cast spells. What components would it have?

4. **Event integration**: How would you add a "statistics" feature that tracks everything? What events would it subscribe to?

