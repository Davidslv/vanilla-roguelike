# Chapter 11: Enemies and Combat

Our roguelike is a treasure-filled, multi-level maze with items to collect, but it’s still too peaceful. It’s time to add some threats! In this chapter, we’ll design a `HealthComponent` to track hit points for both the player and enemies, create stationary monster entities with a `MonsterSystem` to populate the maze, and build a `BattleSystem` for turn-based combat when the player moves onto an enemy’s position. By the end, you’ll be fighting simple enemies lurking in the dungeon, making every step a potential battle. Let’s arm ourselves and face the foes!

## Designing HealthComponent for Entities

The `HealthComponent` will track health for any entity—player or monster—enabling combat by allowing damage to be dealt and received. We’ve already introduced it in Chapter 10 for item usage, so we’ll refine it here to ensure it supports death detection.

Update `lib/components/health.rb`:

```ruby
# lib/components/health.rb
module Components
  class Health
    attr_accessor :current, :max

    def initialize(max)
      @max = max
      @current = max  # Start at full health
    end

    def heal(amount)
      @current = [@current + amount, @max].min
    end

    def damage(amount)
      @current = [@current - amount, 0].max
    end

    def alive?
      @current > 0
    end

    def to_h
      { current: @current, max: @max }
    end

    def self.from_h(hash)
      health = new(hash[:max])
      health.current = hash[:current]
      health
    end
  end
end
```

### Explanation

- **current/max**: Tracks health (e.g., 50/50 for the player, 20/20 for a monster).
- **damage**: Reduces `current`, stopping at 0.
- **alive?**: Returns `true` if the entity has health left, simplifying death checks.
- **heal**: Already added for items, reused here.

This component will be attached to both the player and monsters, forming the foundation for combat.

## Creating Monster Entities and a MonsterSystem

Monsters will be stationary entities placed in the maze, waiting for the player to encounter them. The `MonsterSystem` will spawn them during maze generation, similar to items and stairs, but they won’t move—combat will trigger when the player steps into their space.

### MonsterComponent

Create `lib/components/monster.rb` to mark entities as monsters:

```ruby
# lib/components/monster.rb
module Components
  class Monster
    attr_reader :name, :damage

    def initialize(name, damage)
      @name = name      # e.g., "Goblin"
      @damage = damage  # e.g., 5 (damage dealt per attack)
    end

    def to_h
      { name: @name, damage: @damage }
    end

    def self.from_h(hash)
      new(hash[:name], hash[:damage])
    end
  end
end
```

- **name**: Identifies the monster (e.g., "Goblin").
- **damage**: How much health it removes from the player per attack.

### MonsterSystem

Create `lib/systems/monster_system.rb` to spawn monsters:

```ruby
# lib/systems/monster_system.rb
module Systems
  class MonsterSystem
    def initialize(world)
      @world = world
      @generated = false
    end

    def process(_entities)
      return if @generated

      # Spawn monsters during maze generation (called by MazeSystem)
      @generated = true
    end

    def spawn_monsters(grid)
      path_cells = []
      grid.cells.each_with_index { |row, y| row.each_with_index { |cell, x| path_cells << [x, y] unless cell.is_wall } }

      # Add 2 monsters
      monsters = [
        { name: "Goblin", damage: 5, health: 20 },
        { name: "Skeleton", damage: 3, health: 15 }
      ]
      2.times do
        x, y = path_cells.sample
        next if @world.entities.values.any? { |e| pos = e.get_component(Components::Position); pos && pos.x == x && pos.y == y }
        monster_data = monsters.sample
        monster = @world.create_entity
        monster.add_component(Components::Position.new(x, y))
        monster.add_component(Components::Render.new("M"))
        monster.add_component(Components::Monster.new(monster_data[:name], monster_data[:damage]))
        monster.add_component(Components::Health.new(monster_data[:health]))
      end
    end
  end
end
```

- **spawn_monsters**: Called by `MazeSystem`, places 2 random monsters ("Goblin" or "Skeleton") on path cells, avoiding overlap.
- **Components**: Monsters get `Position`, `Render` ("M"), `Monster`, and `Health`.

Update `MazeSystem` to integrate monsters:

```ruby
# lib/systems/maze_system.rb
require_relative "../grid"
require_relative "../binary_tree_generator"

module Systems
  class MazeSystem
    def initialize(world, generator_class = BinaryTreeGenerator)
      @world = world
      @generator_class = generator_class
      @monster_system = Systems::MonsterSystem.new(world)  # Add MonsterSystem
      @generated = false
    end

    def process(_entities)
      return if @generated

      grid = Grid.new(@world.width, @world.height)
      grid.generate_maze(@generator_class)

      grid.cells.each_with_index do |row, y|
        row.each_with_index do |cell, x|
          if cell.is_wall
            wall = @world.create_entity
            wall.add_component(Components::Position.new(x, y))
            wall.add_component(Components::Render.new("#"))
          end
        end
      end

      add_stairs_and_items(grid)
      @monster_system.spawn_monsters(grid)  # Spawn monsters
      @generated = true
    end

    private

    def add_stairs_and_items(grid)
      path_cells = []
      grid.cells.each_with_index { |row, y| row.each_with_index { |cell, x| path_cells << [x, y] unless cell.is_wall } }

      down_x, down_y = path_cells.sample
      stairs_down = @world.create_entity
      stairs_down.add_component(Components::Position.new(down_x, down_y))
      stairs_down.add_component(Components::Render.new("%"))
      stairs_down.add_component(Components::Stairs.new(1))

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

      items = [
        { name: "Gold Coin", weight: 1, effect: nil },
        { name: "Healing Potion", weight: 2, effect: { type: :heal, value: 10 } }
      ]
      3.times do
        item_x, item_y = path_cells.sample
        next if grid.at(item_x, item_y).is_wall || @world.entities.values.any? { |e| pos = e.get_component(Components::Position); pos && pos.x == item_x && pos.y == item_y }
        item_data = items.sample
        item = @world.create_entity
        item.add_component(Components::Position.new(item_x, item_y))
        item.add_component(Components::Render.new("$"))
        item.add_component(Components::Item.new(item_data[:name], item_data[:weight], item_data[:effect]))
      end
    end
  end
end
```

- **Integration**: `MazeSystem` now spawns monsters alongside stairs and items.

## Adding BattleSystem

The `BattleSystem` will trigger combat when the player moves onto a monster’s position, dealing damage both ways in a turn-based exchange. Combat ends when either the player or monster’s health hits 0.

Create `lib/systems/battle_system.rb`:

```ruby
# lib/systems/battle_system.rb
require_relative "../event"

module Systems
  class BattleSystem
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
                    player.has_component?(Components::Health)

        pos = player.get_component(Components::Position)
        monster = monster_at?(pos.x, pos.y)
        next unless monster

        # Player attacks monster
        player_damage = 5  # Fixed player damage for now
        monster_health = monster.get_component(Components::Health)
        monster_health.damage(player_damage)
        monster_comp = monster.get_component(Components::Monster)
        puts "You hit the #{monster_comp.name} for #{player_damage} damage!"

        if monster_health.alive?
          # Monster retaliates
          player_health = player.get_component(Components::Health)
          player_health.damage(monster_comp.damage)
          puts "The #{monster_comp.name} hits you for #{monster_comp.damage} damage!"
          if !player_health.alive?
            puts "You have been defeated!"
            @event_manager.queue(Event.new(:player_died))
          end
        else
          # Monster defeated
          puts "You defeated the #{monster_comp.name}!"
          monster.remove_component(Components::Position)
          monster.remove_component(Components::Render)
        end
      end
    end

    private

    def monster_at?(x, y)
      @world.entities.values.find do |entity|
        pos = entity.get_component(Components::Position)
        pos && pos.x == x && pos.y == y && entity.has_component?(Components::Monster)
      end
    end
  end
end
```

### Explanation

- **Trigger**: Listens for `:entity_moved` (from `InputSystem`) when the player moves.
- **Combat**:
  1. Player deals 5 damage to the monster (fixed for simplicity).
  2. If the monster survives, it deals its `damage` to the player.
  3. If either dies, they’re removed (monster) or the game signals defeat (player).
- **Death**: Monsters lose `Position` and `Render` to disappear; player death queues `:player_died` (handled in `World`).

Update `World` to handle player death:

```ruby
# lib/world.rb (snippet)
  def run
    while @running
      @systems.each { |system| system.process(@entities.values) }
      handle_input
      handle_level_change
      handle_player_death
      @event_manager.clear
    end
    puts "Goodbye!"
  end

  # Add this method
  def handle_player_death
    @event_manager.process do |event|
      @running = false if event.type == :player_died
    end
  end
```

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
require_relative "lib/world"

world = World.new(width: 10, height: 5)

# Create player entity
player = world.create_entity
player.add_component(Components::Position.new(1, 1))
player.add_component(Components::Movement.new)
player.add_component(Components::Render.new("@"))
player.add_component(Components::Input.new)
player.add_component(Components::Inventory.new)
player.add_component(Components::Health.new(50))

# Add systems
world.add_system(Systems::MazeSystem.new(world))
world.add_system(Systems::InputSystem.new(world.event_manager))
world.add_system(Systems::MovementSystem.new(world))
world.add_system(Systems::CollisionSystem.new(world, world.event_manager))
world.add_system(Systems::ItemInteractionSystem.new(world, world.event_manager))
world.add_system(Systems::InventorySystem.new(world, world.event_manager))
world.add_system(Systems::BattleSystem.new(world, world.event_manager))
world.add_system(Systems::RenderSystem.new(10, 5))

# Start the game
world.run
```

Run `ruby game.rb`, and you’ll see a maze with `#` walls, `%` stairs, `$` items, and `M` monsters. Move `@` onto `M` to fight—each turn, you deal 5 damage, and the monster hits back until one dies!

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
│   │   ├── item.rb
│   │   ├── inventory.rb
│   │   ├── health.rb
│   │   └── monster.rb  (new)
│   ├── systems/
│   │   ├── movement_system.rb
│   │   ├── render_system.rb
│   │   ├── input_system.rb
│   │   ├── maze_system.rb
│   │   ├── collision_system.rb
│   │   ├── inventory_system.rb
│   │   ├── item_interaction_system.rb
│   │   ├── monster_system.rb  (new)
│   │   └── battle_system.rb  (new)
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
│   │   ├── item_spec.rb
│   │   ├── inventory_spec.rb
│   │   ├── health_spec.rb
│   │   └── monster_spec.rb  (new, below)
│   ├── systems/
│   │   ├── movement_system_spec.rb
│   │   ├── render_system_spec.rb
│   │   ├── input_system_spec.rb
│   │   ├── maze_system_spec.rb
│   │   ├── collision_system_spec.rb
│   │   ├── inventory_system_spec.rb
│   │   ├── item_interaction_system_spec.rb
│   │   ├── monster_system_spec.rb  (new, below)
│   │   └── battle_system_spec.rb  (new, below)
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

- `spec/components/monster_spec.rb`:
```ruby
# spec/components/monster_spec.rb
require_relative "../../lib/components/monster"

RSpec.describe Components::Monster do
  it "stores name and damage" do
    monster = Components::Monster.new("Goblin", 5)
    expect(monster.name).to eq("Goblin")
    expect(monster.damage).to eq(5)
  end
end
```

- `spec/systems/monster_system_spec.rb`:
```ruby
# spec/systems/monster_system_spec.rb
require_relative "../../lib/systems/monster_system"
require_relative "../../lib/world"
require_relative "../../lib/grid"

RSpec.describe Systems::MonsterSystem do
  it "spawns monsters" do
    world = World.new(width: 3, height: 3)
    system = Systems::MonsterSystem.new(world)
    grid = Grid.new(3, 3)
    grid.generate_maze(BinaryTreeGenerator)
    system.spawn_monsters(grid)
    monsters = world.entities.values.select { |e| e.has_component?(Components::Monster) }
    expect(monsters.size).to eq(2)
  end
end
```

- `spec/systems/battle_system_spec.rb`:
```ruby
# spec/systems/battle_system_spec.rb
require_relative "../../lib/systems/battle_system"
require_relative "../../lib/world"
require_relative "../../lib/entity"
require_relative "../../lib/components/position"
require_relative "../../lib/components/health"
require_relative "../../lib/components/monster"

RSpec.describe Systems::BattleSystem do
  it "handles combat" do
    world = World.new
    player = world.create_entity
      .add_component(Components::Position.new(1, 1))
      .add_component(Components::Health.new(50))
    monster = world.create_entity
      .add_component(Components::Position.new(1, 1))
      .add_component(Components::Health.new(20))
      .add_component(Components::Monster.new("Goblin", 5))
    system = Systems::BattleSystem.new(world, world.event_manager)
    world.event_manager.queue(Event.new(:entity_moved, { entity_id: player.id }))
    system.process([player, monster])
    expect(monster.get_component(Components::Health).current).to eq(15)
    expect(player.get_component(Components::Health).current).to eq(45)
  end
end
```

Run `bundle exec rspec` to verify.

## Outcome

By the end of this chapter, you’ve:
- Designed `HealthComponent` for entities with damage and death detection.
- Created stationary monster entities and a `MonsterSystem` to spawn them.
- Added a `BattleSystem` for turn-based combat on collision.

You can now fight simple enemies in the maze! Run `ruby game.rb`, move `@` onto `M` to battle Goblins or Skeletons—deal 5 damage, take their retaliation, and defeat them or fall. Items (`$`) and stairs (`%`) remain, adding strategy to your survival. Next, we could add moving enemies or an inventory UI. Face the foes and let’s keep the combat thrilling!

---

### In-Depth Details for New Engineers

- **Stationary Monsters**: Keeping them immobile simplifies AI for now—combat triggers on contact, fitting the turn-based flow. Moving monsters would need a separate AI system, which we can save for later.
- **Combat Simplicity**: Fixed 5 damage from the player keeps it straightforward. Future chapters could add a `DamageComponent` or stats like strength.
- **Death Handling**: Monsters disappear by losing `Position` and `Render`; player death ends the game via `:player_died`. This is basic but effective for a first combat system.
- **Event-Driven**: Reusing `:entity_moved` ties combat to movement, keeping ECS modular—`BattleSystem` reacts rather than initiates.

This adds danger to the dungeon!