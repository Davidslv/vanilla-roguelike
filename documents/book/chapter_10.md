# Chapter 10: Items and Inventory

Our roguelike now spans multiple levels with stairs, but there’s little to do beyond wandering. Let’s add some loot! In this chapter, we’ll create an `ItemComponent` to define collectible items, an `InventoryComponent` to store them, an `InventorySystem` to manage adding and removing items, and an `ItemInteractionSystem` to handle picking them up. We’ll also render items on the grid so players can spot them. By the end, you’ll be collecting treasures scattered throughout the maze, turning your dungeon crawl into a rewarding adventure. Let’s fill those levels with goodies!

## Creating ItemComponent (Name, Weight) and InventoryComponent

Items need properties to identify them, and the player needs a way to carry them. The `ItemComponent` will define an item’s name and weight, while the `InventoryComponent` will act as the player’s backpack.

### ItemComponent

Create `lib/components/item.rb`:

```ruby
# lib/components/item.rb
module Components
  class Item
    attr_reader :name, :weight

    def initialize(name, weight)
      @name = name      # e.g., "Gold Coin", "Potion"
      @weight = weight  # e.g., 1, 5 (could limit inventory later)
    end

    def to_h
      { name: @name, weight: @weight }
    end

    def self.from_h(hash)
      new(hash[:name], hash[:weight])
    end
  end
end
```

- **name**: A string to identify the item (e.g., "Gold Coin").
- **weight**: An integer for potential future mechanics (e.g., carry limits). For now, it’s just descriptive.

### InventoryComponent

Create `lib/components/inventory.rb`:

```ruby
# lib/components/inventory.rb
module Components
  class Inventory
    attr_reader :items

    def initialize
      @items = []  # Array of entity IDs
    end

    def add_item(entity_id)
      @items << entity_id unless @items.include?(entity_id)
    end

    def remove_item(entity_id)
      @items.delete(entity_id)
    end

    def to_h
      { items: @items.dup }
    end

    def self.from_h(hash)
      inventory = new
      hash[:items].each { |id| inventory.add_item(id) }
      inventory
    end
  end
end
```

- **items**: An array of entity IDs (not the items themselves) to reference items in the `World`. This keeps the component lightweight and leverages ECS’s entity system.
- **add_item/remove_item**: Basic methods to manage the inventory, with a check to avoid duplicates.

## Building InventorySystem for Adding/Removing Items

The `InventorySystem` will process events like `:item_picked_up` to update the player’s inventory and remove items from the grid.

Create `lib/systems/inventory_system.rb`:

```ruby
# lib/systems/inventory_system.rb
require_relative "../event"

module Systems
  class InventorySystem
    def initialize(world, event_manager)
      @world = world
      @event_manager = event_manager
    end

    def process(entities)
      @event_manager.process do |event|
        next unless event.type == :item_picked_up

        player_id = event.data[:player_id]
        item_id = event.data[:item_id]

        player = @world.entities[player_id]
        item = @world.entities[item_id]
        next unless player && item && player.has_component?(Components::Inventory)

        inventory = player.get_component(Components::Inventory)
        inventory.add_item(item_id)

        # Remove item from the world (hide it, keep entity for reference)
        item.remove_component(Components::Position) if item.has_component?(Components::Position)
        item.remove_component(Components::Render) if item.has_component?(Components::Render)

        puts "Picked up #{item.get_component(Components::Item).name}!"
      end
    end
  end
end
```

### Explanation

- **Event Handling**: Listens for `:item_picked_up` events with `player_id` and `item_id`.
- **Adding to Inventory**: Adds the item’s ID to the player’s `InventoryComponent`.
- **Removing from Grid**: Strips `Position` and `Render` components so the item disappears from the maze but remains in the `World` (for inventory reference).
- **Feedback**: Prints a message—later, we could enhance this with a UI system.

## Adding ItemInteractionSystem for Picking Up Items

The `ItemInteractionSystem` will detect when the player moves onto an item’s position and queue the pickup event.

Create `lib/systems/item_interaction_system.rb`:

```ruby
# lib/systems/item_interaction_system.rb
require_relative "../event"

module Systems
  class ItemInteractionSystem
    def initialize(world, event_manager)
      @world = world
      @event_manager = event_manager
    end

    def process(entities)
      @event_manager.process do |event|
        next unless event.type == :entity_moved

        player_id = event.data[:entity_id]
        player = @world.entities[player_id]
        next unless player && player.has_component?(Components::Position) &&
                    player.has_component?(Components::Inventory)

        pos = player.get_component(Components::Position)
        item = item_at?(pos.x, pos.y)
        if item
          @event_manager.queue(Event.new(:item_picked_up, { player_id: player_id, item_id: item.id }))
        end
      end
    end

    private

    def item_at?(x, y)
      @world.entities.values.find do |entity|
        pos = entity.get_component(Components::Position)
        pos && pos.x == x && pos.y == y && entity.has_component?(Components::Item)
      end
    end
  end
end
```

- **Trigger**: Checks `:entity_moved` events (from `InputSystem`) for the player.
- **Detection**: Finds an item at the player’s new position using `item_at?`.
- **Event**: Queues `:item_picked_up` with both player and item IDs.

## Rendering Items on the Grid

Items will use the existing `RenderSystem` with a `$` symbol for treasure. We’ll add them in `MazeSystem`.

Update `lib/systems/maze_system.rb`:

```ruby
# lib/systems/maze_system.rb
require_relative "../grid"
require_relative "../binary_tree_generator"

module Systems
  class MazeSystem
    def initialize(world, generator_class = BinaryTreeGenerator)
      @world = world
      @generator_class = generator_class
      @generated = false
    end

    def process(_entities)
      return if @generated

      grid = Grid.new(@world.width, @world.height)
      grid.generate_maze(@generator_class)

      # Create wall entities
      grid.cells.each_with_index do |row, y|
        row.each_with_index do |cell, x|
          if cell.is_wall
            wall = @world.create_entity
            wall.add_component(Components::Position.new(x, y))
            wall.add_component(Components::Render.new("#"))
          end
        end
      end

      # Add stairs and items
      add_stairs_and_items(grid)

      @generated = true
    end

    private

    def add_stairs_and_items(grid)
      path_cells = []
      grid.cells.each_with_index { |row, y| row.each_with_index { |cell, x| path_cells << [x, y] unless cell.is_wall } }

      # Stairs down
      down_x, down_y = path_cells.sample
      stairs_down = @world.create_entity
      stairs_down.add_component(Components::Position.new(down_x, down_y))
      stairs_down.add_component(Components::Render.new("%"))
      stairs_down.add_component(Components::Stairs.new(1))

      # Stairs up (if not level 0)
      if @world.instance_variable_get(:@current_level) > 0
        up_x, up_y = path_cells.sample
        while up_x == down_x && up_y == down_y
          up_x, up_y = path_cells.sample
        end
        stairs_up = @world.create_entity
        stairs_up.add_component(Components::Position.new(up_x, up_y))
        stairs_up.add_component(Components::Render.new("%"))
        stairs_up.add_component(Components::Stairs.new(-1))
      end

      # Add 3 random items
      3.times do
        item_x, item_y = path_cells.sample
        next if grid.at(item_x, item_y).is_wall || @world.entities.values.any? { |e| pos = e.get_component(Components::Position); pos && pos.x == item_x && pos.y == item_y }
        item = @world.create_entity
        item.add_component(Components::Position.new(item_x, item_y))
        item.add_component(Components::Render.new("$"))
        item.add_component(Components::Item.new("Gold Coin", 1))
      end
    end
  end
end
```

- **add_stairs_and_items**: Adds stairs (as before) and 3 random "Gold Coin" items on path cells, ensuring no overlap with walls or other entities.
- **Render**: Uses `$`—`RenderSystem` will display it automatically.

### Integrating Everything

Update `game.rb`:

```ruby
# game.rb
require_relative "lib/components/position"
require_relative "lib/components/movement"
require_relative "lib/components/render"
require_relative "lib/components/input"
require_relative "lib/components/stairs"
require_relative "lib/components/item"
require_relative "lib/components/inventory"
require_relative "lib/entity"
require_relative "lib/systems/movement_system"
require_relative "lib/systems/render_system"
require_relative "lib/systems/input_system"
require_relative "lib/systems/maze_system"
require_relative "lib/systems/collision_system"
require_relative "lib/systems/inventory_system"
require_relative "lib/systems/item_interaction_system"
require_relative "lib/world"

world = World.new(width: 10, height: 5)

# Create player entity
player = world.create_entity
player.add_component(Components::Position.new(1, 1))
player.add_component(Components::Movement.new)
player.add_component(Components::Render.new("@"))
player.add_component(Components::Input.new)
player.add_component(Components::Inventory.new)

# Add systems
world.add_system(Systems::MazeSystem.new(world))
world.add_system(Systems::InputSystem.new(world.event_manager))
world.add_system(Systems::MovementSystem.new(world))
world.add_system(Systems::CollisionSystem.new(world, world.event_manager))
world.add_system(Systems::ItemInteractionSystem.new(world, world.event_manager))
world.add_system(Systems::InventorySystem.new(world, world.event_manager))
world.add_system(Systems::RenderSystem.new(10, 5))

# Start the game
world.run
```

Run `ruby game.rb`, and you’ll see a maze with `#` walls, `%` stairs, and `$` items. Move `@` onto `$` to pick up "Gold Coin" (check the terminal for pickup messages), or `%` to switch levels. Each level has new items!

### Updated Project Structure

```
roguelike/
├── Gemfile
├── game.rb
├── lib/
│   ├── components/
│   │   ├── position.rb
│   │   ├── movement.rb
│   │   ├── render.rb
│   │   ├── input.rb
│   │   ├── stairs.rb
│   │   ├── item.rb  (new)
│   │   └── inventory.rb  (new)
│   ├── systems/
│   │   ├── movement_system.rb
│   │   ├── render_system.rb
│   │   ├── input_system.rb
│   │   ├── maze_system.rb
│   │   ├── collision_system.rb
│   │   ├── inventory_system.rb  (new)
│   │   └── item_interaction_system.rb  (new)
│   ├── binary_tree_generator.rb
│   ├── entity.rb
│   ├── event.rb
│   ├── grid.rb
│   ├── maze_generator.rb
│   └── world.rb
├── spec/
│   ├── components/
│   │   ├── position_spec.rb
│   │   ├── movement_spec.rb
│   │   ├── render_spec.rb
│   │   ├── input_spec.rb
│   │   ├── stairs_spec.rb
│   │   ├── item_spec.rb  (new, below)
│   │   └── inventory_spec.rb  (new, below)
│   ├── systems/
│   │   ├── movement_system_spec.rb
│   │   ├── render_system_spec.rb
│   │   ├── input_system_spec.rb
│   │   ├── maze_system_spec.rb
│   │   ├── collision_system_spec.rb
│   │   ├── inventory_system_spec.rb  (new, below)
│   │   └── item_interaction_system_spec.rb  (new, below)
│   ├── binary_tree_generator_spec.rb
│   ├── entity_spec.rb
│   ├── event_spec.rb
│   ├── grid_spec.rb
│   ├── maze_generator_spec.rb
│   ├── world_spec.rb
│   └── game_spec.rb
└── README.md
```

### New Tests

- `spec/components/item_spec.rb`:
```ruby
# spec/components/item_spec.rb
require_relative "../../lib/components/item"

RSpec.describe Components::Item do
  it "stores name and weight" do
    item = Components::Item.new("Gold Coin", 1)
    expect(item.name).to eq("Gold Coin")
    expect(item.weight).to eq(1)
    expect(Components::Item.from_h(item.to_h).name).to eq("Gold Coin")
  end
end
```

- `spec/components/inventory_spec.rb`:
```ruby
# spec/components/inventory_spec.rb
require_relative "../../lib/components/inventory"

RSpec.describe Components::Inventory do
  it "adds and removes items" do
    inventory = Components::Inventory.new
    inventory.add_item(1)
    expect(inventory.items).to eq([1])
    inventory.remove_item(1)
    expect(inventory.items).to be_empty
  end
end
```

- `spec/systems/inventory_system_spec.rb`:
```ruby
# spec/systems/inventory_system_spec.rb
require_relative "../../lib/systems/inventory_system"
require_relative "../../lib/world"
require_relative "../../lib/entity"
require_relative "../../lib/components/inventory"
require_relative "../../lib/components/item"

RSpec.describe Systems::InventorySystem do
  it "adds item to inventory and removes from grid" do
    world = World.new
    player = world.create_entity.add_component(Components::Inventory.new)
    item = world.create_entity
      .add_component(Components::Item.new("Gold Coin", 1))
      .add_component(Components::Position.new(1, 1))
      .add_component(Components::Render.new("$"))
    system = Systems::InventorySystem.new(world, world.event_manager)
    world.event_manager.queue(Event.new(:item_picked_up, { player_id: player.id, item_id: item.id }))
    system.process([player, item])
    expect(player.get_component(Components::Inventory).items).to eq([item.id])
    expect(item.has_component?(Components::Position)).to be false
  end
end
```

- `spec/systems/item_interaction_system_spec.rb`:
```ruby
# spec/systems/item_interaction_system_spec.rb
require_relative "../../lib/systems/item_interaction_system"
require_relative "../../lib/world"
require_relative "../../lib/entity"
require_relative "../../lib/components/position"
require_relative "../../lib/components/inventory"
require_relative "../../lib/components/item"

RSpec.describe Systems::ItemInteractionSystem do
  it "queues pickup event when player moves onto item" do
    world = World.new
    player = world.create_entity
      .add_component(Components::Position.new(1, 1))
      .add_component(Components::Inventory.new)
    item = world.create_entity
      .add_component(Components::Position.new(1, 1))
      .add_component(Components::Item.new("Gold Coin", 1))
    system = Systems::ItemInteractionSystem.new(world, world.event_manager)
    world.event_manager.queue(Event.new(:entity_moved, { entity_id: player.id }))
    system.process([player, item])
    expect(world.event_manager.instance_variable_get(:@queue)).to include(
      an_object_having_attributes(type: :item_picked_up, data: { player_id: player.id, item_id: item.id })
    )
  end
end
```

Run `bundle exec rspec` to verify.

## Outcome

By the end of this chapter, you’ve:
- Created `ItemComponent` (name, weight) and `InventoryComponent`.
- Built `InventorySystem` for adding/removing items.
- Added `ItemInteractionSystem` for picking up items.
- Rendered items on the grid as `$`.

You can now collect items scattered in the maze! Run `ruby game.rb`, find `$` symbols, move `@` onto them to pick up "Gold Coin"s, and watch them disappear with a message. Stairs (`%`) still take you between levels, each with new items. Next, we could add item effects or an inventory display. Explore your loot-filled dungeon and let’s keep the treasure hunt going!

---

### In-Depth Details for New Engineers

- **Why Entity IDs in Inventory?**: Storing IDs instead of full entities keeps `InventoryComponent` lean and avoids duplicating data. The `World` retains the actual entities, and we can reference them as needed.
- **Item Removal**: Removing `Position` and `Render` hides items without deleting them, preserving them for inventory use. Full deletion (`@world.entities.delete`) would break references.
- **Overlap Handling**: `MazeSystem` checks for occupied spots, but multiple items could still overlap in rare cases—future chapters could prioritize rendering or add stacking.
- **Event Flow**: `:entity_moved` → `:item_picked_up` shows ECS’s power—systems communicate via events, keeping logic modular.

This adds a rewarding layer to the game!