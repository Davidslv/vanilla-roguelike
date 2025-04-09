# Chapter 3: The Core ECS Architecture

With our environment set up and a basic game loop under our belt, it's time to dive into the heart of our game: the Entity-Component-System (ECS) architecture. In this chapter, we'll define the building blocks of ECS—Components, Entities, Systems, and the World—and put them together in a minimal example: an entity with a position that moves across the screen. By the end, you'll have a working ECS loop that demonstrates the pattern's power and flexibility.

## Defining Component (Data Container with Serialization)

Components are the raw data of our game—simple containers that hold an entity's properties, like position or health. They don't contain logic; they're just bags of values. To make our game state easy to inspect or save, we'll add serialization, letting us convert components to and from a format like JSON.

Here's a `Position` component in `lib/components/position.rb`:

```ruby
# lib/components/position.rb
module Components
  class Position
    attr_accessor :x, :y

    def initialize(x, y)
      @x = x
      @y = y
    end

    # Serialize to a hash for JSON or debugging
    def to_h
      { x: @x, y: @y }
    end

    # Deserialize from a hash
    def self.from_h(hash)
      new(hash[:x], hash[:y])
    end
  end
end
```

This component has `x` and `y` coordinates, and we can serialize it to a hash (e.g., `{ x: 5, y: 3 }`) or recreate it from one. We'll store all components in `lib/components/` as we add more.

## Creating Entity (Component Bag with ID)

An entity is just a unique identifier that holds a collection of components—like a bag with a label. It doesn't do anything on its own; it's defined by the components attached to it.

Here's an `Entity` class in `lib/entity.rb`:

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
end
```

An entity has an `id` (e.g., 1) and a hash of components. We can add a component (e.g., a `Position`), retrieve it, or check if it exists. For example, `entity.get_component(Components::Position)` fetches the entity's position.

## Building System (Logic Processor)

Systems are where the magic happens—they process entities based on their components. A system defines what components it cares about and updates entities that match.

Here's a `MovementSystem` in `lib/systems/movement_system.rb` that moves entities with a `Position` component:

```ruby
# lib/systems/movement_system.rb
module Systems
  class MovementSystem
    def initialize(speed)
      @speed = speed  # Pixels per frame
    end

    def process(entities)
      entities.each do |entity|
        if entity.has_component?(Components::Position)
          position = entity.get_component(Components::Position)
          position.x += @speed  # Move right
        end
      end
    end
  end
end
```

This system loops through entities, checks for a `Position` component, and increments the `x` coordinate. Later, we'll add input or velocity, but for now, it's a simple demo.

## Introducing World (Manager of Entities and Systems)

The `World` ties everything together. It manages entities, assigns IDs, and runs systems in a loop. Think of it as the game's conductor.

Here's the `World` class in `lib/world.rb`:

```ruby
# lib/world.rb
class World
  def initialize
    @entities = {}
    @systems = []
    @next_id = 0
  end

  def create_entity
    entity = Entity.new(@next_id)
    @entities[@next_id] = entity
    @next_id += 1
    entity
  end

  def add_system(system)
    @systems << system
    self
  end

  def run
    loop do
      @systems.each { |system| system.process(@entities.values) }
      render
      sleep(0.1)  # Slow it down for visibility
    end
  end

  private

  def render
    system("clear") || system("cls")
    @entities.values.each do |entity|
      if entity.has_component?(Components::Position)
        pos = entity.get_component(Components::Position)
        puts "Entity #{entity.id} at (#{pos.x}, #{pos.y})"
      end
    end
  end
end
```

The `World`:
- Creates entities with unique IDs.
- Stores systems in an array.
- Runs a loop that processes systems and renders the state (for now, just printing positions).

## Serialization in ECS

Serialization is a crucial aspect of game development that allows us to save and load game state. In an ECS architecture, serialization takes on a special importance because we need to preserve the relationships between entities, their components, and the world state. Let's explore how serialization works in our ECS framework.

### What is Serialization?

Serialization is the process of converting complex data structures (like our game state) into a format that can be easily stored or transmitted. In Ruby, this often means converting objects into JSON, YAML, or another format that can be written to a file or sent over a network.

### Why Serialization Matters in Games

Games need serialization for several important reasons:

1. **Save Games:** Players expect to be able to save their progress and continue later.
2. **State Persistence:** Maintaining game state between sessions.
3. **Debugging:** Saving game state for debugging purposes.
4. **Network Play:** Transmitting game state between players in multiplayer games.

### Serializing ECS Components

In our ECS architecture, serialization needs to handle:

1. **Entity IDs:** Preserving the unique identifiers of entities
2. **Component Data:** Converting component data into a serializable format
3. **Relationships:** Maintaining the connections between entities and their components
4. **World State:** Preserving the overall game state

Here's how we can implement serialization in our ECS:

```ruby
class World
  def serialize
    {
      entities: entities.map { |id, entity| serialize_entity(id, entity) },
      next_entity_id: @next_entity_id
    }
  end

  def serialize_entity(id, entity)
    {
      id: id,
      components: entity.components.transform_values { |component|
        serialize_component(component)
      }
    }
  end

  def serialize_component(component)
    # Each component type needs to implement its own serialization
    component.serialize
  end

  def deserialize(data)
    @next_entity_id = data[:next_entity_id]

    data[:entities].each do |entity_data|
      id = entity_data[:id]
      entity = Entity.new

      entity_data[:components].each do |component_type, component_data|
        component = deserialize_component(component_type, component_data)
        entity.add_component(component_type, component)
      end

      @entities[id] = entity
    end
  end

  def deserialize_component(type, data)
    # Each component type needs to implement its own deserialization
    component_class = type.to_s.classify.constantize
    component_class.deserialize(data)
  end
end
```

### Component Serialization

Each component needs to implement its own serialization logic. Here's an example with our Position component:

```ruby
class Position
  attr_accessor :x, :y

  def initialize(x = 0, y = 0)
    @x = x
    @y = y
  end

  def serialize
    {
      x: @x,
      y: @y
    }
  end

  def self.deserialize(data)
    new(data[:x], data[:y])
  end
end
```

### Saving and Loading

To save the game state to a file:

```ruby
def save_game(world, filename)
  data = world.serialize
  File.write(filename, JSON.pretty_generate(data))
end

def load_game(filename)
  data = JSON.parse(File.read(filename), symbolize_names: true)
  world = World.new
  world.deserialize(data)
  world
end
```

### Best Practices for ECS Serialization

1. **Keep Components Pure Data:** Components should be simple data containers without complex behavior, making them easier to serialize.

2. **Version Your Save Format:** Include a version number in your serialized data to handle format changes over time.

3. **Handle References Carefully:** If components reference other entities, use entity IDs instead of direct references.

4. **Validate Data:** Always validate serialized data when loading to prevent corruption.

5. **Consider Performance:** For large games, you might need to implement incremental saving or compression.

### Example Usage

```ruby
# Creating and saving a game state
world = World.new
player = world.create_entity
player.add_component(:position, Position.new(10, 10))
player.add_component(:health, Health.new(100))

save_game(world, 'save_game.json')

# Loading a game state
loaded_world = load_game('save_game.json')
```

This serialization system allows us to save the entire game state, including all entities and their components, and restore it exactly as it was. This is essential for features like save games, checkpoints, and debugging.

## Writing a Minimal Example: An Entity with a Position That Moves

Let's put it all together in `game.rb`:

```ruby
# game.rb
require_relative "lib/components/position"
require_relative "lib/entity"
require_relative "lib/systems/movement_system"
require_relative "lib/world"

world = World.new

# Create an entity with a Position component
player = world.create_entity
player.add_component(Components::Position.new(0, 0))

# Add a MovementSystem
world.add_system(Systems::MovementSystem.new(1))

# Start the game
world.run
```

Run this with `ruby game.rb`, and you'll see "Entity 0 at (x, 0)" where `x` increases every 0.1 seconds. It's basic, but it's ECS in action: an entity with a position component being processed by a movement system!

### Updated Project Structure

Here's how the project looks now:

```
roguelike/
├── Gemfile
├── game.rb
├── lib/
│   ├── components/
│   │   └── position.rb
│   ├── systems/
│   │   └── movement_system.rb
│   ├── entity.rb
│   └── world.rb
├── spec/
│   ├── components/
│   │   └── position_spec.rb  (added below)
│   ├── systems/
│   │   └── movement_system_spec.rb  (added below)
│   ├── entity_spec.rb  (added below)
│   ├── world_spec.rb   (added below)
│   └── game_spec.rb
└── README.md
```

Let's add some RSpec tests to verify our ECS pieces:

- `spec/components/position_spec.rb`:
```ruby
# spec/components/position_spec.rb
require_relative "../../lib/components/position"

RSpec.describe Components::Position do
  it "serializes and deserializes correctly" do
    pos = Components::Position.new(5, 3)
    expect(Components::Position.from_h(pos.to_h).x).to eq(5)
  end
end
```

- `spec/entity_spec.rb`:
```ruby
# spec/entity_spec.rb
require_relative "../lib/entity"
require_relative "../lib/components/position"

RSpec.describe Entity do
  it "adds and retrieves components" do
    entity = Entity.new(1)
    pos = Components::Position.new(2, 4)
    entity.add_component(pos)
    expect(entity.get_component(Components::Position)).to eq(pos)
  end
end
```

- `spec/systems/movement_system_spec.rb`:
```ruby
# spec/systems/movement_system_spec.rb
require_relative "../../lib/systems/movement_system"
require_relative "../../lib/entity"
require_relative "../../lib/components/position"

RSpec.describe Systems::MovementSystem do
  it "moves entities with Position" do
    entity = Entity.new(1).add_component(Components::Position.new(0, 0))
    system = Systems::MovementSystem.new(2)
    system.process([entity])
    expect(entity.get_component(Components::Position).x).to eq(2)
  end
end
```

- `spec/world_spec.rb`:
```ruby
# spec/world_spec.rb
require_relative "../lib/world"
require_relative "../lib/components/position"

RSpec.describe World do
  it "creates entities with unique IDs" do
    world = World.new
    e1 = world.create_entity
    e2 = world.create_entity
    expect(e1.id).to eq(0)
    expect(e2.id).to eq(1)
  end
end
```

Run `bundle exec rspec` to confirm everything works.

## Outcome

By the end of this chapter, you've:
- Defined a `Position` component with serialization.
- Created an `Entity` class to hold components.
- Built a `MovementSystem` to process entities.
- Introduced a `World` to manage the ECS loop.
- Implemented a minimal example of a moving entity.

You now have a basic ECS architecture running in Ruby! In the next chapter, we'll expand this into our roguelike, adding input handling, rendering, and more components like walls and items. Run `ruby game.rb` to see your entity move, and let's keep the momentum going!
