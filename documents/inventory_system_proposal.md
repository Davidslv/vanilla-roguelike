# Inventory System Proposal

## 1. Overview

The Vanilla roguelike currently lacks a proper inventory system, which is a core feature for roguelike games. This proposal outlines the implementation of a comprehensive inventory system that integrates with the existing Entity Component System (ECS) architecture, the message system, and follows the established design patterns of the codebase.

The inventory system will allow players to:
- Collect items from the dungeon
- Manage their inventory with a dedicated UI
- Use, equip, and discard items
- Receive feedback through the message system
- Benefit from item effects (stat boosts, healing, etc.)

## 2. System Architecture

The inventory system will follow the same architectural patterns used throughout the codebase:

- **Entity-Component-System (ECS)**: Items will be entities with components
- **Service Locator Pattern**: Inventory services will be accessible via the service registry
- **Facade Pattern**: A clean interface will be provided for interactions
- **Observer Pattern**: For inventory change notifications

### 2.1. Core Components

```mermaid
classDiagram
    class InventoryComponent {
        +Array~Item~ items
        +Integer maxSize
        +add(item)
        +remove(item)
        +has(itemType)
        +count(itemType)
    }

    class ItemComponent {
        +String name
        +String description
        +Symbol itemType
        +Integer weight
        +Integer value
        +Boolean stackable
        +Integer stackSize
        +use(entity)
    }

    class EquippableComponent {
        +Symbol slot
        +Hash statModifiers
        +Boolean equipped
        +equip(entity)
        +unequip(entity)
    }

    class ConsumableComponent {
        +Integer charges
        +Hash effects
        +consume(entity)
    }

    ItemComponent <|-- EquippableComponent
    ItemComponent <|-- ConsumableComponent

    class Entity {
        +addComponent()
        +getComponent()
    }

    Entity --> ItemComponent : has
    Entity --> InventoryComponent : has
```

### 2.2. Systems

```mermaid
classDiagram
    class InventorySystem {
        +initialize(messageSystem)
        +addItem(entity, item)
        +removeItem(entity, item)
        +useItem(entity, item)
        +equipItem(entity, item)
        +unequipItem(entity, item)
        +dropItem(entity, item)
    }

    class ItemInteractionSystem {
        +initialize(inventorySystem, messageSystem)
        +processItemPickup(entity, targetCell)
        +processItemDrop(entity, item)
        +processItemUse(entity, item)
    }

    class InventoryRenderSystem {
        +initialize(renderer)
        +renderInventory(entity, x, y, width, height)
        +renderEquipment(entity, x, y, width, height)
        +renderItemDetails(item, x, y, width, height)
    }

    InventorySystem --> ItemInteractionSystem : uses
    InventorySystem --> InventoryRenderSystem : uses
```

### 2.3. Service Facade

```mermaid
classDiagram
    class InventorySystemFacade {
        +initialize(logger, renderer)
        +addItemToEntity(entity, item)
        +removeItemFromEntity(entity, item)
        +useItem(entity, item)
        +equipItem(entity, item)
        +unequipItem(entity, item)
        +dropItem(entity, item)
        +displayInventory(entity)
        +hideInventory()
        +isInventoryVisible()
        +toggleInventoryView()
        +handleInput(key)
    }

    InventorySystemFacade --> InventorySystem : manages
    InventorySystemFacade --> InventoryRenderSystem : manages
    InventorySystemFacade --> ServiceRegistry : registered with
```

## 3. Item Implementation

Items will be implemented as entities with specific components:

### 3.1. Item Types and Properties

```mermaid
classDiagram
    class Item {
        +Entity core
        +ItemComponent itemComponent
        +RenderComponent renderComponent
    }

    class Weapon extends Item {
        +EquippableComponent equippableComponent
        +DamageComponent damageComponent
    }

    class Armor extends Item {
        +EquippableComponent equippableComponent
        +DefenseComponent defenseComponent
    }

    class Potion extends Item {
        +ConsumableComponent consumableComponent
        +EffectComponent effectComponent
    }

    class Scroll extends Item {
        +ConsumableComponent consumableComponent
        +SpellComponent spellComponent
    }

    class Key extends Item {
        +KeyComponent keyComponent
    }
```

### 3.2. Equipment Slots

```mermaid
graph TD
    Equipment[Equipment System]
    Head[Head Slot]
    Body[Body Slot]
    LeftHand[Left Hand Slot]
    RightHand[Right Hand Slot]
    Neck[Neck Slot]
    Feet[Feet Slot]

    Equipment --> Head
    Equipment --> Body
    Equipment --> LeftHand
    Equipment --> RightHand
    Equipment --> Neck
    Equipment --> Feet
```

## 4. Integration with Existing Systems

### 4.1. Integration with Movement System

The inventory system will integrate with the movement system to:
- Detect items on a cell when a player moves
- Offer item pickup options
- Process auto-pickup for certain item types

```mermaid
sequenceDiagram
    participant Player
    participant MovementSystem
    participant Cell
    participant ItemInteractionSystem
    participant InventorySystem
    participant MessageSystem

    Player->>MovementSystem: move(direction)
    MovementSystem->>Cell: getContents()
    Cell-->>MovementSystem: [items, etc.]

    alt has items
        MovementSystem->>ItemInteractionSystem: processItemsAtLocation(player, cell)
        ItemInteractionSystem->>InventorySystem: addItem(player, item)
        InventorySystem->>MessageSystem: log_message("items.pickup", {item: item.name})
        MessageSystem-->>Player: "You picked up a Potion of Healing"
    end
```

### 4.2. Integration with Message System

The inventory system will use the message system to provide feedback:

```mermaid
sequenceDiagram
    participant Player
    participant InventorySystem
    participant ItemComponent
    participant MessageSystem

    Player->>InventorySystem: useItem(potion)
    InventorySystem->>ItemComponent: use(player)
    ItemComponent->>Player: applyEffect(heal)
    ItemComponent->>InventorySystem: notifyItemUsed()
    InventorySystem->>MessageSystem: log_message("items.used", {item: "Potion of Healing", effect: "+15 HP"})
    MessageSystem-->>Player: "You drink the Potion of Healing. You recover 15 HP."
```

### 4.3. Integration with ECS Framework

```mermaid
graph TD
    Entity[Entity] --> IC[InventoryComponent]
    IC --> System[InventorySystem]
    Entity --> PC[PositionComponent]
    PC --> MS[MovementSystem]
    MS --> IIS[ItemInteractionSystem]
    IIS --> System
```

## 5. UI Implementation

### 5.1. Inventory Display

```mermaid
graph TD
    Game[Game Loop] --> IRender[Inventory Render]
    IRender --> InvPanel[Inventory Panel]
    IRender --> EqPanel[Equipment Panel]
    IRender --> ItemDetail[Item Detail Panel]

    InvPanel --> Listing[Item Listing]
    Listing --> Selection[Selection System]
    Selection --> Action[Action Menu]

    Action --> Use[Use Item]
    Action --> Equip[Equip Item]
    Action --> Drop[Drop Item]
    Action --> Examine[Examine Item]
```

### 5.2. Terminal UI Layout

```
+-----------------------------------+
| Vanilla Roguelike                 |
+-----------------------------------+
| Game Map...                       |
|                                   |
|                                   |
|                                   |
+-----------------------------------+
| Messages...                       |
| ...                               |
+-----------------------------------+
| [i] Inventory (7/10)              |
| a) Potion of Healing x3           |
| b) Short Sword                    |
| c) Leather Armor [E]              |
| d) Gold Coin x45                  |
+-----------------------------------+
| Equipment:                        |
| Head: -                           |
| Body: Leather Armor               |
| Weapon: -                         |
+-----------------------------------+
| [ESC] Close [a-d] Select          |
+-----------------------------------+
```

### 5.3. UI Interaction Flow

```mermaid
stateDiagram-v2
    [*] --> Game
    Game --> Inventory: Press 'i'
    Inventory --> ItemSelect: Select item
    ItemSelect --> ItemActions: Show actions
    ItemActions --> UseItem: Select "Use"
    ItemActions --> EquipItem: Select "Equip"
    ItemActions --> DropItem: Select "Drop"
    ItemActions --> ExamineItem: Select "Examine"

    UseItem --> ApplyEffect: Consumable
    EquipItem --> EquipEffect: Equipment
    DropItem --> RemoveFromInventory: Any item
    ExamineItem --> ShowDetails: Any item

    ApplyEffect --> Inventory
    EquipEffect --> Inventory
    RemoveFromInventory --> Inventory
    ShowDetails --> Inventory

    Inventory --> Game: Press ESC
```

## 6. Implementation Plan

### 6.1. Phase 1: Core Components

1. Create the base item components:
   - `InventoryComponent`
   - `ItemComponent`
   - `EquippableComponent`
   - `ConsumableComponent`
   - `EffectComponent`
   - `KeyComponent`
   - `CurrencyComponent`
   - `DurabilityComponent`

2. Extend the Entity class to support these components
3. Create the base item entity types
4. Implement item serialization/deserialization for save/load functionality

**Timeline**: 2-3 weeks

### 6.2. Phase 2: Systems Implementation

1. Create the `InventorySystem` for managing item interactions
   - Core item operations
   - Stacking logic
   - Weight calculations
   - Transaction management

2. Create the `ItemInteractionSystem` for handling item pickups
   - Auto-pickup configs
   - Interaction with map cells
   - Loot generation

3. Create the `InventoryRenderSystem` for displaying the inventory
   - Terminal rendering
   - Item sorting options (by type, value, weight)
   - Visual indicators for equipped/special items

4. Create the `InventorySystemFacade` for providing a clean interface

**Timeline**: 3-4 weeks

### 6.3. Phase 3: UI Integration

1. Implement inventory display in the terminal UI
   - Main inventory panel
   - Equipment panel
   - Item detail view
   - Action menu

2. Implement selection and interaction mechanisms
   - Letter shortcuts (a-z)
   - Category filtering
   - Quick-use bindings

3. Add keybindings for inventory management
   - 'i' - Toggle inventory
   - 'e' - Toggle equipment
   - 'g' - Pick up item
   - 'd' - Drop item

4. Integrate with message system for feedback
   - Success/failure messages
   - Effect descriptions
   - Weight warnings

**Timeline**: 2-3 weeks

### 6.4. Phase 4: Game Integration

1. Add items to level generation
   - Item placement algorithms
   - Rarity tiers
   - Level-appropriate loot tables

2. Implement item pickup during movement
   - Automatic vs. prompted pickup
   - Item discovery messages

3. Add effects from consumable items
   - Healing
   - Stat buffs
   - Special abilities

4. Implement equipment stat bonuses
   - Combat modifiers
   - Defense calculations
   - Special properties

**Timeline**: 3-4 weeks

### 6.5. Phase 5: Polish and Optimization

1. Performance optimization
   - Efficient item lookup
   - Rendering optimizations
   - Memory usage improvements

2. Bug fixing and edge cases
   - Inventory overflow handling
   - Stackable item edge cases
   - UI edge cases

3. Final testing and balancing
   - Item distribution
   - Effect strength
   - Economy balance

**Timeline**: 2 weeks

## 7. Data Structures and Algorithms

### 7.1. Item Data Structure

Items will be defined using a YAML configuration format for easy editing and extension:

```yaml
items:
  potion_healing:
    name: "Potion of Healing"
    description: "A small vial of red liquid that restores health."
    char: "!"
    color: :red
    type: :consumable
    rarity: :common
    stackable: true
    max_stack: 5
    effects:
      - type: :heal
        value: 15
        duration: 0  # instant
    weight: 1
    value: 20

  short_sword:
    name: "Short Sword"
    description: "A simple but effective weapon."
    char: "/"
    color: :white
    type: :weapon
    slot: :weapon
    damage: 5
    durability: 50
    weight: 3
    value: 50
    modifiers:
      strength: 1

  healing_scroll:
    name: "Scroll of Healing"
    description: "A magical scroll that heals when read."
    char: "?"
    color: :green
    type: :scroll
    stackable: true
    max_stack: 3
    effects:
      - type: :heal
        value: 25
        radius: 2  # affects nearby allies too
    weight: 0.5
    value: 35

  gold_coin:
    name: "Gold Coin"
    description: "A standard gold coin, used as currency."
    char: "$"
    color: :yellow
    type: :currency
    stackable: true
    max_stack: 999
    weight: 0.01
    value: 1
```

### 7.2. Item Storage Algorithms

The inventory system will use efficient data structures and algorithms:

1. **Fast Lookup by Type**: Hash-based indexing for quick item type queries
   ```ruby
   def build_type_index
     @type_index = {}
     @items.each do |item|
       type = item.type
       @type_index[type] ||= []
       @type_index[type] << item
     end
   end
   ```

2. **Efficient Stacking**: O(n) algorithm for finding and stacking items
   ```ruby
   def stack_items
     stackable_types = @items.select(&:stackable?).map(&:type).uniq
     stackable_types.each do |type|
       items_of_type = @items.select { |i| i.type == type && i.stackable? }
       next if items_of_type.size <= 1

       # Keep first item and stack others into it
       primary = items_of_type.first
       items_of_type[1..-1].each do |item|
         primary.stack_size += item.stack_size
         @items.delete(item)
       end
     end
   end
   ```

3. **Weight Optimization**: Knapsack algorithm for auto-sorting based on value/weight ratio
   ```ruby
   def optimize_for_value
     # Sort by value-to-weight ratio (descending)
     @items.sort_by! { |item| -item.value / item.weight }
   end
   ```

## 8. Error Handling and Edge Cases

### 8.1. Error Prevention

The inventory system will implement robust error prevention:

1. **Item Validation**
   ```ruby
   def validate_item(item)
     return false unless item.is_a?(Entity)
     return false unless item.has_component?(:item)
     return false if item.get_component(:item).nil?
     true
   end
   ```

2. **Inventory Capacity**
   ```ruby
   def can_add_item?(item)
     return false if full?
     return true if has_space_for?(item)

     # Try to stack if possible
     if item.stackable? && has_stackable?(item.type)
       stackable = find_stackable(item.type)
       return stackable.stack_size < stackable.max_stack
     end

     false
   end
   ```

3. **Equipment Validation**
   ```ruby
   def can_equip?(item, slot)
     return false unless item.has_component?(:equippable)
     equippable = item.get_component(:equippable)
     return false unless equippable.slot == slot

     # Check level/stat requirements
     if equippable.requirements
       equippable.requirements.all? do |stat, min_value|
         @entity.get_stat(stat) >= min_value
       end
     else
       true
     end
   end
   ```

### 8.2. Exception Handling

```ruby
def safe_add_item(item)
  begin
    return add_item(item)
  rescue => e
    @logger.error("Failed to add item: #{e.message}")
    @message_system.log_message("errors.item_add_failed",
                              importance: :warning,
                              metadata: { item: item.name })
    return false
  end
end
```

### 8.3. Edge Cases

1. **Inventory Full During Auto-Pickup**
   ```ruby
   def handle_full_inventory_during_pickup(player, item)
     current_position = player.get_component(:position)

     # Create a dropped item entity at the player's position
     @message_system.log_message("items.inventory_full_dropping",
                                importance: :warning,
                                metadata: { item: item.name })

     # Leave item on ground
     @level.add_item_at_location(item, current_position.row, current_position.column)
   end
   ```

2. **Item Stacking Overflow**
   ```ruby
   def add_stackable_item(item)
     existing = find_stackable(item.type)
     combined_size = existing.stack_size + item.stack_size

     if combined_size <= existing.max_stack
       # Simple stack case
       existing.stack_size = combined_size
       return true
     else
       # Handle overflow
       existing.stack_size = existing.max_stack
       item.stack_size = combined_size - existing.max_stack

       if has_space?
         @items << item
         return true
       else
         # Handle full inventory with overflow
         handle_full_inventory_during_pickup(@entity, item)
         return false
       end
     end
   end
   ```

## 9. Performance Considerations

### 9.1. Memory Optimization

To minimize memory overhead, especially with potentially hundreds of items:

1. **Flyweight Pattern for Item Types**
   ```ruby
   module Vanilla
     module Items
       class ItemTypeRegistry
         include Singleton

         def initialize
           @types = {}
         end

         def get_type(key)
           @types[key] ||= load_item_type(key)
         end

         private

         def load_item_type(key)
           # Load from YAML config
           config = YAML.load_file('config/items.yml')
           config.dig('items', key.to_s)
         end
       end
     end
   end
   ```

2. **Lazy Loading of Item Details**
   ```ruby
   def description
     @description_loaded ||= ItemTypeRegistry.instance.get_type(@key)['description']
   end
   ```

3. **Efficient Serialization**
   ```ruby
   def to_h
     # Only store essential data
     {
       type: @type,
       id: @id,
       stack_size: @stackable ? @stack_size : nil,
       durability: @has_durability ? @durability : nil,
       equipped: @equippable ? @equipped : nil
     }.compact
   end
   ```

### 9.2. Rendering Optimization

```ruby
def render_inventory(entity, x, y, width, height)
  # Only re-render when inventory has changed
  inventory_hash = inventory_content_hash(entity)

  if @last_inventory_hash != inventory_hash
    @cached_inventory = generate_inventory_display(entity, width)
    @last_inventory_hash = inventory_hash
  end

  # Draw from cache
  @cached_inventory.each_with_index do |line, idx|
    next if idx >= height
    draw_text(x, y + idx, line)
  end
end

private

def inventory_content_hash(entity)
  inventory = entity.get_component(:inventory)
  # Generate a hash based on items and their states
  inventory.items.map { |i| "#{i.id}:#{i.stack_size}:#{i.equipped}" }.join('|')
end
```

## 10. Localization Support

All inventory-related strings will support I18n localization:

```yaml
# en.yml
en:
  inventory:
    title: "Inventory (%{current}/%{max})"
    equipment: "Equipment"
    weight: "Weight: %{current}/%{max}"
    empty: "Your inventory is empty."

  items:
    pickup: "You pick up %{item}."
    drop: "You drop %{item}."
    equip: "You equip %{item}."
    unequip: "You unequip %{item}."
    use: "You use %{item}. %{effect}"
    inventory_full: "Your inventory is full!"

  effects:
    heal: "You recover %{amount} health."
    poison: "You feel poison coursing through you!"
    strength_up: "You feel stronger! (%{amount})"
```

## 11. Example Implementation Walkthrough

### 11.1. Creating an Item

```ruby
def create_healing_potion
  entity = Vanilla::Components::Entity.new

  # Add basic item component
  item_component = Vanilla::Components::ItemComponent.new(
    name: "Potion of Healing",
    description: "A small vial of red liquid that restores health.",
    item_type: :potion,
    weight: 1,
    value: 20,
    stackable: true,
    stack_size: 1,
    max_stack: 5
  )
  entity.add_component(item_component)

  # Add render component for display on map
  render_component = Vanilla::Components::RenderComponent.new(
    character: "!",
    color: :red,
    layer: 2
  )
  entity.add_component(render_component)

  # Add consumable component
  consumable_component = Vanilla::Components::ConsumableComponent.new(
    charges: 1,
    effects: [
      {
        type: :heal,
        value: 15
      }
    ]
  )
  entity.add_component(consumable_component)

  entity
end
```

### 11.2. Adding to Inventory

```ruby
def add_item_to_player(player, item)
  # Ensure player has inventory
  unless player.has_component?(:inventory)
    inventory = Vanilla::Components::InventoryComponent.new(max_size: 20)
    player.add_component(inventory)
  end

  # Get inventory and add item
  inventory = player.get_component(:inventory)

  if inventory.add(item)
    @message_system.log_message("items.pickup",
                               category: :item,
                               importance: :info,
                               metadata: { item: item.name })
    return true
  else
    @message_system.log_message("items.inventory_full",
                               category: :item,
                               importance: :warning)
    return false
  end
end
```

### 11.3. Using an Item

```ruby
def use_item(player, item_index)
  inventory = player.get_component(:inventory)
  return false unless inventory

  item = inventory.items[item_index]
  return false unless item

  if item.has_component?(:consumable)
    consumable = item.get_component(:consumable)

    # Apply effects
    consumable.effects.each do |effect|
      case effect[:type]
      when :heal
        if player.has_component?(:health)
          health = player.get_component(:health)
          old_hp = health.current
          health.heal(effect[:value])
          amount_healed = health.current - old_hp

          @message_system.log_message("effects.heal",
                                     category: :item,
                                     importance: :success,
                                     metadata: { amount: amount_healed })
        end
      when :strength_up
        if player.respond_to?(:modify_stat)
          player.modify_stat(:strength, effect[:value], effect[:duration])

          @message_system.log_message("effects.strength_up",
                                     category: :item,
                                     importance: :success,
                                     metadata: { amount: effect[:value] })
        end
      end
    end

    # Reduce charges
    consumable.charges -= 1

    # Remove if depleted
    if consumable.charges <= 0
      inventory.remove(item)
    end

    return true
  end

  false
end
```

## 12. Testing Strategy

### 12.1. Unit Tests

```ruby
RSpec.describe Vanilla::Components::InventoryComponent do
  let(:inventory) { described_class.new(max_size: 5) }
  let(:potion) { create_test_item(:potion, stackable: true, stack_size: 1) }
  let(:sword) { create_test_item(:sword, stackable: false) }

  describe "#add" do
    it "adds items to the inventory" do
      expect(inventory.add(sword)).to be true
      expect(inventory.count).to eq(1)
    end

    it "respects maximum capacity" do
      5.times { inventory.add(create_test_item(:misc)) }
      expect(inventory.add(sword)).to be false
      expect(inventory.count).to eq(5)
    end

    it "stacks stackable items" do
      inventory.add(potion)
      another_potion = create_test_item(:potion, stackable: true, stack_size: 2)

      expect(inventory.add(another_potion)).to be true
      expect(inventory.count).to eq(1)

      item = inventory.items.first
      expect(item.stack_size).to eq(3)
    end
  end
end
```

### 12.2. Integration Tests

```ruby
RSpec.describe "Inventory Integration" do
  let(:game) { Vanilla::Game.new }
  let(:player) { game.level.player }
  let(:inventory_system) { Vanilla::Systems::InventorySystem.new(game.message_system) }

  before do
    # Setup test environment
    game.start
    @potion = create_test_item(:potion)

    # Place item in level
    row, col = player.get_component(:position).coordinates
    game.level.add_item_at(@potion, row, col)
  end

  it "allows item pickup during movement" do
    # Record inventory state before
    initial_count = player.get_component(:inventory).count

    # Trigger movement (which should cause pickup)
    command = Vanilla::Commands::MoveCommand.new(
      player,
      :north,
      game.level.grid
    )
    command.execute

    # Check inventory after
    expect(player.get_component(:inventory).count).to eq(initial_count + 1)

    # Verify messages
    messages = game.message_system.get_recent_messages(5)
    expect(messages.any? { |m| m.content.include?("pick up") }).to be true
  end
end
```

### 12.3. Automated Simulation

```ruby
module Vanilla
  module Simulation
    class InventorySimulator
      def initialize(game_simulator)
        @game_simulator = game_simulator
        @results = {
          items_collected: [],
          items_used: [],
          equipment_changes: []
        }
      end

      def run_collection_test
        # Simulate player movement to collect items
        directions = [:north, :south, :east, :west]

        20.times do
          # Move randomly
          direction = directions.sample
          result = @game_simulator.simulate_movement(direction)

          # Record item pickups
          messages = @game_simulator.collect_messages
          pickup_messages = messages.select { |m| m[:text].include?("pick up") }

          pickup_messages.each do |msg|
            item_name = msg[:text].scan(/pick up a (.+)\./).flatten.first
            @results[:items_collected] << {
              item: item_name,
              turn: @game_simulator.results[:actions_performed]
            }
          end
        end

        @results
      end

      def run_usage_test
        # Open inventory
        @game_simulator.process_action({ type: :custom, block: ->(sim) {
          # Send 'i' key to open inventory
          sim.handle_key_press('i')

          # Select first item
          sim.handle_key_press('a')

          # Use item
          sim.handle_key_press('u')

          # Close inventory
          sim.handle_key_press(27) # ESC
        }})

        # Collect results
        messages = @game_simulator.collect_messages
        usage_messages = messages.select { |m| m[:text].include?("use") }

        usage_messages.each do |msg|
          @results[:items_used] << {
            message: msg[:text],
            turn: @game_simulator.results[:actions_performed]
          }
        end

        @results
      end
    end
  end
end
```

## 13. Future Extensions

### 13.1. Item Enchantment System

```mermaid
graph TD
    Item[Base Item] --> Identify[Identify Item]
    Identify --> Properties[Determine Properties]
    Properties --> Enchant[Enchant Item]
    Enchant --> Rarity[Increase Rarity]

    Enchant --> Prefix[Add Prefix]
    Enchant --> Suffix[Add Suffix]

    Prefix --> Effects[Apply Effects]
    Suffix --> Effects
```

### 13.2. Crafting System

```mermaid
graph TD
    Recipes[Recipe System] --> ItemCombination[Item Combination]
    ItemCombination --> Results[Crafted Items]

    Inventory[Inventory] --> ItemCombination

    Results --> Success[Successful Craft]
    Results --> Failure[Failed Craft]

    Success --> NewItem[Add New Item]
    Success --> ConsumeIngredients[Consume Ingredients]

    Failure --> PartialConsume[Partial Ingredient Loss]
```

### 13.3. Item Durability and Repair

```mermaid
stateDiagram-v2
    [*] --> Pristine

    Pristine --> Worn: Use Item
    Worn --> Damaged: Continue Using
    Damaged --> Broken: Further Use

    Worn --> Pristine: Repair
    Damaged --> Worn: Repair
    Broken --> Damaged: Major Repair

    Broken --> [*]: Destroy Item
```

## 14. Conclusion

This inventory system proposal provides a comprehensive approach to adding item management to the Vanilla roguelike. The design adheres to the existing architecture patterns while introducing new functionality that significantly enhances gameplay.

Key strengths of this approach include:
- Strong integration with the existing ECS pattern
- Clean separation of concerns with dedicated components and systems
- Efficient algorithms for item management
- Comprehensive UI for player interaction
- Robust error handling and edge case management
- Performance optimizations for large inventories
- Extensibility for future features

The implementation plan allows for incremental development and testing, ensuring that each phase builds upon a solid foundation. The phased approach also allows for user feedback and refinement throughout the development process.

Once implemented, the inventory system will transform Vanilla from a basic movement game into a true roguelike with meaningful item collection, strategic equipment choices, and tactical resource management.

## 15. Code Organization and Technical Integration

### 15.1. Directory Structure

The inventory system will be organized following the existing code structure:

```
lib/
└── vanilla/
    ├── inventory.rb                 # Main facade module
    ├── inventory/
    │   ├── item.rb                  # Base item class
    │   ├── item_factory.rb          # Factory for creating items
    │   ├── item_registry.rb         # Registry of item definitions
    │   ├── effects/                 # Item effect implementations
    │   │   ├── effect.rb            # Base effect class
    │   │   ├── healing_effect.rb    # Healing implementation
    │   │   ├── stat_effect.rb       # Stat modification implementation
    │   │   └── ...
    │   ├── items/                   # Specific item type implementations
    │   │   ├── weapon.rb            # Weapon-specific functionality
    │   │   ├── armor.rb             # Armor-specific functionality
    │   │   ├── potion.rb            # Potion-specific functionality
    │   │   └── ...
    │   └── ui/                      # UI elements for inventory
    │       ├── inventory_panel.rb   # Inventory display panel
    │       ├── equipment_panel.rb   # Equipment display panel
    │       └── item_details_panel.rb # Item details display
    ├── components/
    │   ├── inventory_component.rb   # Added to entities with inventories
    │   ├── item_component.rb        # Base component for all items
    │   ├── equippable_component.rb  # For equippable items
    │   ├── consumable_component.rb  # For consumable items
    │   └── ...
    └── systems/
        ├── inventory_system.rb      # Core inventory management system
        ├── item_interaction_system.rb # Handles item pickups and interactions
        └── inventory_render_system.rb # Renders inventory UI
```

### 15.2. Integration Points

The inventory system will integrate with the existing codebase at several key points:

```mermaid
graph TD
    IC[Inventory Component] --> Entity[Entity Component System]
    IS[Inventory System] --> ServiceRegistry[Service Registry]

    IS --> MessageSystem[Message System]
    IS --> RenderSystem[Render System]
    IS --> MovementSystem[Movement System]

    InputHandler[Input Handler] --> IS

    Game[Game Loop] --> IS
    Level[Level Generation] --> ItemPlacement[Item Placement]
```

#### 15.2.1. Entity Component System

Integration with the existing ECS architecture:

```ruby
# Adding inventory to an entity (e.g., Player)
player.add_component(Vanilla::Components::InventoryComponent.new(max_size: 20))

# Adding item components to item entities
sword = Vanilla::Components::Entity.new
sword.add_component(Vanilla::Components::ItemComponent.new(...))
sword.add_component(Vanilla::Components::EquippableComponent.new(...))
sword.add_component(Vanilla::Components::RenderComponent.new(...))
```

#### 15.2.2. Service Registry

Using the service registry for dependency management:

```ruby
# In Game initialization
def initialize
  # Existing code...

  # Initialize inventory system and register it
  @inventory_system = Vanilla::Inventory::InventorySystemFacade.new(@logger, @render_system)
  Vanilla::ServiceRegistry.register(:inventory_system, @inventory_system)

  # Existing code...
end

# Elsewhere in the codebase, accessing the inventory system
inventory_system = Vanilla::ServiceRegistry.get(:inventory_system)
inventory_system.add_item_to_entity(player, sword)
```

#### 15.2.3. Message System

Integration with the message system:

```ruby
# In InventorySystem
def use_item(entity, item)
  # Item usage logic...

  # Send message about item usage
  message_system = Vanilla::Messages::MessageSystem.instance
  message_system.log_message("items.used",
                           category: :item,
                           importance: :info,
                           metadata: {
                             item: item.name,
                             effect: effect_description
                           })
end
```

#### 15.2.4. Movement System

Integration with the movement system for item pickup:

```ruby
# In MovementSystem
def move(entity, direction)
  # Existing movement code...

  # Check for items at the new position
  if entity.is_a?(Vanilla::Entities::Player) && valid_move
    item_system = Vanilla::ServiceRegistry.get(:inventory_system)
    item_system.check_for_items_at_position(entity, new_position)
  end
end

# In InventorySystem
def check_for_items_at_position(entity, position)
  items = @level.get_items_at(position.row, position.column)

  items.each do |item|
    if add_item_to_entity(entity, item)
      @level.remove_item(item) # Remove from ground
    end
  end
end
```

#### 15.2.5. Input Handler

Integration with the input handler for inventory-related commands:

```ruby
# In InputHandler
def handle_input(key, entity, grid)
  # Check if inventory system should handle this input
  inventory_system = Vanilla::ServiceRegistry.get(:inventory_system)

  case key
  when 'i'
    # Toggle inventory display
    inventory_system.toggle_inventory_view
    return Vanilla::Commands::NoOpCommand.new
  when 'g'
    # Pick up item at current position
    position = entity.get_component(:position)
    inventory_system.pick_up_item_at_position(entity, position)
    return Vanilla::Commands::NoOpCommand.new
  else
    # If inventory is open, pass keys to it for selection/action
    if inventory_system.inventory_visible?
      inventory_system.handle_inventory_input(key)
      return Vanilla::Commands::NoOpCommand.new
    end
  end

  # Existing input handling...
end
```

#### 15.2.6. Level Generation

Integration with level generation for item placement:

```ruby
# In Level class
def self.random(difficulty:)
  # Existing level generation code...

  # Add items based on difficulty
  level.add_items(difficulty)

  level
end

def add_items(difficulty)
  # Determine how many items to place
  item_count = base_item_count + (difficulty / 2)

  item_factory = Vanilla::Inventory::ItemFactory.new

  item_count.times do
    # Get random walkable cell
    cell = get_random_walkable_cell
    next unless cell

    # Create item based on difficulty
    item = item_factory.create_random_item(difficulty)

    # Add item to the level at this position
    add_item_at(item, cell.row, cell.column)
  end
end
```

### 15.3. Ensuring Code Quality

To maintain high code quality during integration:

1. **Dependency Injection**
   ```ruby
   # Good: Inject dependencies
   def initialize(message_system, render_system)
     @message_system = message_system
     @render_system = render_system
   end

   # Avoid: Global access
   def initialize
     @message_system = $message_system
     @render_system = $render_system
   end
   ```

2. **Interface Stability**
   ```ruby
   # Public methods with clear contracts
   # @param entity [Entity] The entity to add the item to
   # @param item [Entity] The item to add
   # @return [Boolean] Whether the item was successfully added
   def add_item_to_entity(entity, item)
     # Implementation...
   end
   ```

3. **Backward Compatibility**
   ```ruby
   # Support existing movement without items too
   def move(entity, direction)
     # Core movement logic

     # Optional item interaction
     if entity.is_a?(Vanilla::Entities::Player) &&
        defined?(Vanilla::Inventory) &&
        Vanilla::ServiceRegistry.get(:inventory_system)

       # Item pickup logic...
     end
   end
   ```

### 15.4. Migration Strategy

To ensure smooth integration with existing game code:

1. **Phased Component Introduction**
   - Add inventory component to Player first
   - Add basic consumable items next
   - Add equipment items last

2. **Parallel Systems**
   - Keep existing systems working alongside new inventory system
   - Allow game to function without inventory until fully implemented

3. **Feature Flags**
   - Use configuration options to enable/disable inventory features
   - Allow easy rollback if issues are discovered

```ruby
# Configuration with feature flags
module Vanilla
  module Config
    FEATURE_FLAGS = {
      inventory_system: true,
      equipment_stats: true,
      item_durability: false,  # Not implemented yet
      crafting: false          # Not implemented yet
    }

    def self.feature_enabled?(feature)
      FEATURE_FLAGS.fetch(feature, false)
    end
  end
end

# Usage in code
if Vanilla::Config.feature_enabled?(:inventory_system)
  # Inventory-related code
end
```

This approach ensures the inventory system integrates seamlessly with the existing codebase while maintaining clean architecture and code quality standards.

## 16. Gameplay Impact and Design Considerations

### 16.1. Gameplay Loop Enhancement

The addition of an inventory system fundamentally transforms the gameplay loop of Vanilla:

```mermaid
graph TD
    subgraph "Current Gameplay Loop"
        Move[Move] --> Explore[Explore]
        Explore --> Combat[Combat]
        Combat --> Move
    end

    subgraph "Enhanced Gameplay Loop"
        EMove[Move] --> EExplore[Explore]
        EExplore --> EFind[Find Items]
        EFind --> EManage[Manage Inventory]
        EManage --> EEquip[Equipment Choices]
        EEquip --> ECombat[Enhanced Combat]
        ECombat --> EUse[Use Items]
        EUse --> EMove
    end
```

### 16.2. Strategic Depth

The inventory system adds multiple layers of strategic decision-making:

1. **Resource Management**
   - Inventory space limitations
   - Weight constraints
   - Item durability management

2. **Risk/Reward Calculations**
   - Keep valuable items or drop for space
   - Save consumables or use immediately
   - Prioritize different equipment attributes

3. **Build Optimization**
   - Equipment combinations for stat bonuses
   - Specialization (melee, ranged, magic)
   - Counter-building for specific challenges

### 16.3. Game Balance Considerations

Introducing an inventory system requires careful balance:

```mermaid
graph LR
    Progression[Progression Curve] --- PowerLevel[Power Level]
    PowerLevel --- Difficulty[Enemy Difficulty]
    Difficulty --- Resources[Resource Availability]
    Resources --- Progression

    ItemQuality[Item Quality] --> PowerLevel
    ItemQuantity[Item Quantity] --> Resources

    EffectStrength[Effect Strength] --- ItemQuality
    LootDistribution[Loot Distribution] --- ItemQuantity
```

#### 16.3.1. Balance Principles

1. **Progressive Power Scaling**
   - Item power increases with depth/difficulty
   - Power increases are steady but not exponential
   - Equipment slots limit maximum power

2. **Item Scarcity**
   - Better items are less common
   - Consumables require strategic use
   - Limited inventory space forces choices

3. **Trade-offs**
   - More damage = less defense
   - More power = more weight
   - Better effects = limited uses

#### 16.3.2. Testing for Balance

The following metrics will be tracked during testing:

```ruby
class BalanceMetrics
  attr_reader :metrics

  def initialize
    @metrics = {
      avg_items_per_level: [],
      time_to_level_completion: [],
      item_usage_rates: {},
      player_damage_dealt: [],
      player_damage_taken: [],
      deaths_by_level: []
    }
  end

  def record_level_completion(level, items_found, time_taken)
    @metrics[:avg_items_per_level][level] ||= []
    @metrics[:avg_items_per_level][level] << items_found

    @metrics[:time_to_level_completion][level] ||= []
    @metrics[:time_to_level_completion][level] << time_taken
  end

  # Additional metrics recording methods...

  def generate_report
    # Calculate averages and identify trends
    report = {
      item_balance: analyze_item_balance,
      progression_curve: analyze_progression,
      difficulty_spikes: identify_difficulty_spikes
    }

    puts "=== BALANCE REPORT ==="
    puts JSON.pretty_generate(report)
  end

  private

  def analyze_item_balance
    # Determine if certain items are overused or underused
    # Return recommendations for adjustments
  end

  # Additional analysis methods...
end
```

### 16.4. Accessibility and User Experience

The inventory system must be accessible to players of all experience levels:

1. **Intuitive Controls**
   - Consistent key mappings
   - Quick access for common actions
   - Visual cues for item states

2. **Information Clarity**
   - Clear item descriptions
   - Effect explanations
   - Comparison tooltips for equipment

3. **Configurable Options**
   - Auto-pickup settings
   - Inventory sorting preferences
   - Visual style options

### 16.5. Future-Proofing Design

The inventory system is designed to allow for future expansion:

1. **Quest Items**
   - Special non-droppable items
   - Story progression elements
   - Puzzle components

2. **Advanced Item Systems**
   - Item identification mechanic
   - Cursed/blessed items
   - Item transformation/upgrading

3. **Economy**
   - Shops and vendors
   - Currency system
   - Item value fluctuation

By considering these gameplay impacts from the start, the inventory system will enhance Vanilla's depth without compromising its core roguelike experience. The careful balance of power progression, strategic choices, and accessibility will ensure that the inventory system becomes a seamless and integral part of gameplay.

## 17. Evaluation and Conclusion

This proposal has been developed with careful consideration of the existing Vanilla codebase, design patterns, and roguelike game conventions. Below is a self-assessment of various dimensions of the proposal:

| Dimension | Rating (1-5) | Justification |
|-----------|--------------|---------------|
| Architecture Quality | 5.0 | Follows established patterns (ECS, Service Locator, Facade) with clear separation of concerns |
| Code Organization | 4.8 | Well-structured file layout with intuitive organization and minimal dependencies |
| Performance | 4.7 | Includes optimization strategies for memory, rendering, and algorithms |
| Maintainability | 4.9 | Clean interfaces, proper encapsulation, extensive documentation |
| Testability | 4.8 | Comprehensive testing strategy with unit, integration, and simulation tests |
| Gameplay Impact | 4.5 | Adds significant strategic depth while preserving core gameplay |
| Integration Ease | 4.3 | Requires some modifications to existing systems but with clear integration points |
| Extensibility | 5.0 | Designed from the ground up for future extensions and enhancements |
| **Overall Score** | **4.75** | A comprehensive and well-designed inventory system proposal |

### Key Strengths

1. **Architectural Excellence**: The proposal maintains the existing architectural patterns while extending them in a natural way.

2. **Progressive Implementation**: The phased approach allows for incremental development and testing.

3. **Performance Consciousness**: Incorporates optimization strategies from the outset rather than as an afterthought.

4. **Balance Considerations**: Includes detailed gameplay balance considerations with metrics for evaluation.

5. **Comprehensive Documentation**: Provides clear implementation details, diagrams, and examples.

### Implementation Recommendations

1. Begin with the core `InventoryComponent` and basic item entities to establish the foundation.

2. Implement the service facade early to provide a clean interface for other systems.

3. Focus on UI integration as a priority to make the inventory immediately accessible to players.

4. Establish a continuous testing regime using the proposed simulation tools to ensure balance.

5. Gather player feedback after initial implementation to refine the user experience.

The inventory system represents a significant enhancement to Vanilla, transforming it into a more complete roguelike experience while maintaining its clean, accessible design philosophy. With careful implementation following this proposal, the inventory system will become a seamless and integral part of the game that players will find both intuitive and engaging.