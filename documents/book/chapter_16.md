# Chapter 16: Saving and Loading

Greetings, dungeon delvers! Your roguelike is a thrilling gauntlet of mazes, treasures, and foes, but every time you quit, it’s back to square one. In true roguelike fashion, permadeath rules—when you fall, that’s it, no do-overs. It’s a brutal charm that keeps us on edge! However, for this chapter, we’re taking a detour from tradition—not because we’re soft, but because mastering save and load mechanics is a must-know skill for any game developer. We’ll serialize entities and components to JSON with `to_hash` and `from_hash`, save the game state to a file with a single keystroke, and load it back to pick up where you left off. This is all about learning—permadeath purists, don’t worry, you can ditch this later! By the end, you’ll have the power to persist your progress (for educational purposes), fully equipped to debug or tweak your game’s flow. Let’s dive into the deep end of saving and loading!

## Serializing Entities and Components to JSON (to_hash, from_hash)

To save your game, we need to capture its state—entities, their components, and `World` details—in a format we can store and reload. JSON is our hero here: it’s structured, readable, and Ruby handles it like a champ. Most components already have `to_h` (to hash) and `from_h` (from hash) methods—we’ve been sneaky about setting that up! Now, we’ll ensure they’re all ready, extend them to `Entity`, and build serialization into `World`. Serialization turns objects into storable data; deserialization brings them back to life.

### Ensuring Components Are Serializable

Let’s double-check and complete the serialization for all components. Each needs `to_h` to export its data and `from_h` to rebuild it. Here’s `Position` as an example—most follow this pattern:

```ruby
# lib/components/position.rb
module Components
  class Position
    attr_accessor :x, :y

    def initialize(x, y)
      @x = x
      @y = y
    end

    def to_h
      { x: @x, y: @y }
    end

    def self.from_h(hash)
      new(hash[:x], hash[:y])
    end
  end
end
```

- **`to_h`**: Exports attributes as a hash (e.g., `{ x: 1, y: 2 }`).
- **`from_h`**: Creates a new instance from that hash, matching keys to parameters.

For `Inventory`, which stores entity IDs:

```ruby
# lib/components/inventory.rb
module Components
  class Inventory
    attr_reader :items

    def initialize
      @items = []
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

- **IDs**: Saves a list of entity IDs, rebuilt on load by re-adding them.

Verify all components (`Movement`, `Render`, `Input`, `Stairs`, `Item`, `Health`, `Monster`) have these methods—they should! If you’ve added custom ones, follow this template: `to_h` exports data, `from_h` reconstructs it.

### Serializing Entities

`Entity` needs to package its ID and components into a hash and rebuild from it.

Update `lib/entity.rb`:

```ruby
# lib/entity.rb
class Entity
  attr_reader :id, :components

  def initialize(id)
    @id = id
    @components = {}
  end

  def add_component(component)
    @components[component.class] = component
    self
  end

  def get_component(component_class)
    @components[component_class]
  end

  def has_component?(component_class)
    @components.key?(component_class)
  end

  def remove_component(component_class)
    @components.delete(component_class)
  end

  def to_h
    {
      id: @id,
      components: @components.transform_keys { |k| k.name.split("::").last }.transform_values(&:to_h)
    }
  end

  def self.from_h(hash, component_map)
    entity = new(hash[:id])
    hash[:components].each do |comp_name, comp_data|
      component_class = component_map[comp_name]
      entity.add_component(component_class.from_h(comp_data)) if component_class
    end
    entity
  end
end
```

- **`to_h`**: Exports the ID and a hash of components, simplifying class names (e.g., `Position` not `Components::Position`).
- **`from_h`**: Uses a `component_map` to look up classes (e.g., `"Position" => Components::Position`), ensuring IDs persist.

### Serializing World

`World` ties everything together—dimensions, level, entities, and systems. We’ll serialize it all.

Update `lib/world.rb`:

```ruby
# lib/world.rb (partial update for brevity)
require "json"

class World
  attr_reader :entities, :event_manager, :width, :height, :systems

  def initialize(width: 10, height: 5)
    @width = width
    @height = height
    @current_level = 0
    @entities = {}
    @systems = []
    @next_id = 0
    @running = true
    @event_manager = EventManager.instance
    generate_level
  end

  def to_h
    {
      width: @width,
      height: @height,
      current_level: @current_level,
      next_id: @next_id,
      entities: @entities.values.map(&:to_h),
      systems: @systems.map { |s| s.class.name.split("::").last }
    }
  end

  def self.from_h(hash)
    world = new(width: hash[:width], height: hash[:height])
    world.instance_variable_set(:@current_level, hash[:current_level])
    world.instance_variable_set(:@next_id, hash[:next_id])

    component_map = {
      "Position" => Components::Position,
      "Movement" => Components::Movement,
      "Render" => Components::Render,
      "Input" => Components::Input,
      "Stairs" => Components::Stairs,
      "Item" => Components::Item,
      "Inventory" => Components::Inventory,
      "Health" => Components::Health,
      "Monster" => Components::Monster
    }

    system_map = {
      "MazeSystem" => Systems::MazeSystem,
      "InputSystem" => Systems::InputSystem,
      "MovementSystem" => Systems::MovementSystem,
      "CollisionSystem" => Systems::CollisionSystem,
      "ItemInteractionSystem" => Systems::ItemInteractionSystem,
      "InventorySystem" => Systems::InventorySystem,
      "BattleSystem" => Systems::BattleSystem,
      "MessageSystem" => Systems::MessageSystem,
      "InventoryRenderSystem" => Systems::InventoryRenderSystem,
      "HudSystem" => Systems::HudSystem,
      "RenderSystem" => Systems::RenderSystem
    }

    hash[:entities].each do |entity_hash|
      entity = Entity.from_h(entity_hash, component_map)
      world.instance_variable_set(:@entities, world.entities.merge(entity.id => entity))
    end

    hash[:systems].each do |system_name|
      system_class = system_map[system_name]
      if system_class
        args = system_class == Systems::InputSystem || system_class == Systems::MessageSystem ? [world.event_manager] : [world]
        args = [world, world.event_manager] if system_class == Systems::InventoryRenderSystem || system_class == Systems::CollisionSystem || system_class == Systems::ItemInteractionSystem || system_class == Systems::InventorySystem || system_class == Systems::BattleSystem
        world.add_system(system_class.new(*args))
      end
    end

    world
  end

  def save_game(file_path = "savegame.json")
    File.write(file_path, JSON.pretty_generate(to_h))
    Logger.instance.info("Game saved to #{file_path}")
  end

  def self.load_game(file_path = "savegame.json")
    return nil unless File.exist?(file_path)
    hash = JSON.parse(File.read(file_path), symbolize_names: true)
    world = from_h(hash)
    Logger.instance.info("Game loaded from #{file_path}")
    world
  end

  # ... other methods (create_entity, add_system, run, etc.) unchanged ...
end
```

- **`to_h`**: Saves core attributes, entities, and system class names.
- **`from_h`**: Rebuilds `World`, entities, and systems, bypassing initial generation.

## Saving the Game State to a File

Saving dumps the `World`’s JSON to a file. We’ll use `v` (for "save") as a single-key command, fitting our one-character input style.

Update `InputSystem`:

```ruby
# lib/systems/input_system.rb (snippet)
module Systems
  class InputSystem
    def initialize(event_manager)
      @event_manager = event_manager
    end

    def process(entities)
      @event_manager.process do |event|
        next unless event.type == :key_pressed
        key = event.data[:key]
        player = entities.find { |e| e.has_component?(Components::Input) }
        next unless player

        inventory_system = @event_manager.instance_variable_get(:@world).systems.find { |s| s.is_a?(Systems::InventoryRenderSystem) }
        next if inventory_system&.showing? && key != "i"

        case key
        when "w" then issue_move_command(player, 0, -1)
        when "s" then issue_move_command(player, 0, 1)
        when "a" then issue_move_command(player, -1, 0)
        when "d" then issue_move_command(player, 1, 0)
        when "i"  # Inventory toggle
        when "v"  # Save game
          world = @event_manager.instance_variable_get(:@world)
          world.save_game
          EventManager.instance.queue(Event.new(:message, { text: "Game saved!" }))
        end
      end
    end

    # ... issue_move_command unchanged ...
  end
end
```

- **`v`**: Triggers `save_game`, adding a confirmation message via `MessageSystem`.

Update `MessageSystem` to handle `:message`:

```ruby
# lib/systems/message_system.rb (snippet)
    def process(_entities)
      @event_manager.process do |event|
        case event.type
        when :item_picked_up
          item_id = event.data[:item_id]
          item = @event_manager.instance_variable_get(:@world).entities[item_id]
          @messages << "You picked up a #{item.get_component(Components::Item).name}"
        when :entity_moved
          player_id = event.data[:entity_id]
          player = @event_manager.instance_variable_get(:@world).entities[player_id]
          pos = player.get_component(Components::Position)
          @messages << "Moved to (#{pos.x}, #{pos.y})" if player.has_component?(Components::Input)
        when :player_died
          @messages << "You have been defeated!"
        when :message
          @messages << event.data[:text]
          @messages.shift if @messages.size > @max_messages
        end
      end
    end
```

## Loading and Resuming a Game

Loading reads the JSON file and reconstructs the `World`. We’ll prompt at startup for new or loaded games.

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
require_relative "lib/components/health"
require_relative "lib/components/monster"
require_relative "lib/entity"
require_relative "lib/systems/movement_system"
require_relative "lib/systems/render_system"
require_relative "lib/systems/input_system"
require_relative "lib/systems/maze_system"
require_relative "lib/systems/collision_system"
require_relative "lib/systems/inventory_system"
require_relative "lib/systems/item_interaction_system"
require_relative "lib/systems/battle_system"
require_relative "lib/systems/monster_system"
require_relative "lib/systems/message_system"
require_relative "lib/systems/inventory_render_system"
require_relative "lib/systems/hud_system"
require_relative "lib/logger"
require_relative "lib/event"
require_relative "lib/world"

puts "Start new game (n) or load saved game (l)?"
choice = gets.chomp.downcase

world = if choice == "l" && File.exist?("savegame.json")
          World.load_game("savegame.json") || World.new(width: 10, height: 5)
        else
          World.new(width: 10, height: 5)
        end

# Initialize player and systems only for new game
if choice != "l" || !File.exist?("savegame.json")
  player = world.create_entity
  player.add_component(Components::Position.new(1, 1))
  player.add_component(Components::Movement.new)
  player.add_component(Components::Render.new("@"))
  player.add_component(Components::Input.new)
  player.add_component(Components::Inventory.new)
  player.add_component(Components::Health.new(50))

  world.add_system(Systems::MazeSystem.new(world))
  world.add_system(Systems::InputSystem.new(world.event_manager))
  world.add_system(Systems::MovementSystem.new(world))
  world.add_system(Systems::CollisionSystem.new(world, world.event_manager))
  world.add_system(Systems::ItemInteractionSystem.new(world, world.event_manager))
  world.add_system(Systems::InventorySystem.new(world, world.event_manager))
  world.add_system(Systems::BattleSystem.new(world, world.event_manager))
  world.add_system(Systems::MessageSystem.new(world.event_manager))
  world.add_system(Systems::InventoryRenderSystem.new(world, world.event_manager))
  world.add_system(Systems::HudSystem.new(world))
  world.add_system(Systems::RenderSystem.new(world))
end

world.run
```

- **Prompt**: `n` for new, `l` to load—falls back to new if no save exists.
- **Systems**: Added only for new games; loaded `World` retains them from serialization.

## Outcome

You’ve:
- Serialized entities and components to JSON with `to_hash` and `from_hash`, covering IDs, attributes, and systems.
- Saved the game state to `savegame.json` with the `v` key, keeping input consistent.
- Loaded and resumed progress with a startup choice (`n` or `l`).

You can now persist your game—for learning, not tradition! Run `ruby game.rb`, pick `n` to start fresh or `l` to load, press `v` to save mid-game, and reload later—your position, inventory, and health stay put. Permadeath is the roguelike soul, but this chapter’s taught you how to bend the rules for education. Want the true experience? Skip `v` and embrace the reset! Next, maybe a win condition or combat polish? Save your progress and master the craft!

---

### Notes for Readers

- **Permadeath Note**: Real roguelikes thrive on no saves—use this for debugging or learning, then ditch it for authenticity!
- **JSON Insight**: Peek at `savegame.json`—it’s your game in text form, readable with `JSON.pretty_generate`.
- **System Limits**: Systems are recreated stateless—add state serialization (e.g., `@messages`) if you need it.
- **Expandability**: New components or systems? Update `component_map` and `system_map` in `World.from_h`.

