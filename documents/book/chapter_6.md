# Chapter 6: Events and Input Handling

Our roguelike now has a moving player and a rendered grid, but the input handling is still tied directly to the `World` class, limiting flexibility. In this chapter, we’ll introduce an event-driven architecture to decouple input from game logic. We’ll add an `Event` class and an `EventManager` to the `World`, create an `InputComponent` and `InputSystem` for processing player commands, map keys to actions like `MoveCommand`, and handle events such as `entity_moved`. By the end, you’ll have a responsive, modular input system that makes controlling the game feel seamless and sets the stage for future features.

## Introducing Event and an EventManager in World

Events are messages that signal something has happened—like a key press or an entity moving. The `EventManager` will queue and distribute these events to systems that care about them.

Create `lib/event.rb`:

```ruby
# lib/event.rb
class Event
  attr_reader :type, :data

  def initialize(type, data = {})
    @type = type     # e.g., :key_pressed, :entity_moved
    @data = data     # Additional info, like { key: "w" } or { entity_id: 1 }
  end
end
```

Update `lib/world.rb` to include an `EventManager`:

```ruby
# lib/world.rb
require_relative "event"

class World
  attr_reader :entities, :event_manager

  def initialize(width: 10, height: 5)
    @entities = {}
    @systems = []
    @next_id = 0
    @width = width
    @height = height
    @running = true
    @event_manager = EventManager.new
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
    while @running
      @systems.each { |system| system.process(@entities.values) }
      handle_input
      @event_manager.clear   # Clear events after each turn
    end
    puts "Goodbye!"
  end

  private

  def handle_input
    input = gets.chomp.downcase   # Wait for user input
    @event_manager.queue(Event.new(:key_pressed, { key: input }))
    @running = false if input == "q"   # Quit still handled here for simplicity
  end
end

class EventManager
  def initialize
    @queue = []
  end

  def queue(event)
    @queue << event
  end

  def process
    @queue.dup.each { |event| yield(event) }   # Pass events to systems
  end

  def clear
    @queue.clear
  end
end
```

- `Event`: A simple class with a `type` (symbol) and `data` (hash).
- `EventManager`: Queues events and lets systems process them. `clear` resets the queue each turn.
- `World`: Now creates an `EventManager` and queues `:key_pressed` events from input.

## Creating InputComponent and InputSystem

The `InputComponent` will define which entity responds to input, and the `InputSystem` will map keys to commands.

Create `lib/components/input.rb`:

```ruby
# lib/components/input.rb
module Components
  class Input
    # No data needed yet; just marks an entity as input-responsive
    def to_h
      {}
    end

    def self.from_h(_hash)
      new
    end
  end
end
```

Create `lib/systems/input_system.rb`:

```ruby
# lib/systems/input_system.rb
require_relative "../event"

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

        case key
        when "w" then issue_move_command(player, 0, -1)   # Up
        when "s" then issue_move_command(player, 0, 1)    # Down
        when "a" then issue_move_command(player, -1, 0)   # Left
        when "d" then issue_move_command(player, 1, 0)    # Right
        end
      end
    end

    private

    def issue_move_command(entity, dx, dy)
      if entity.has_component?(Components::Movement)
        movement = entity.get_component(Components::Movement)
        movement.dx = dx
        movement.dy = dy
        @event_manager.queue(Event.new(:entity_moved, { entity_id: entity.id }))
      end
    end
  end
end
```

- `InputComponent`: A marker component to identify input-responsive entities (like the player).
- `InputSystem`: Listens for `:key_pressed` events, maps keys to movement commands, and queues an `:entity_moved` event.

## Mapping Keys to Commands (e.g., MoveCommand)

We’re implicitly creating a "command" pattern here by translating key presses into actions via the `InputSystem`. The `issue_move_command` method updates the `MovementComponent` and fires an event. This decouples input from movement logic—later, we could formalize commands as classes (e.g., `MoveCommand`), but for now, this keeps it simple.

## Processing Events (e.g., entity_moved)

The `:entity_moved` event is queued but not yet processed by other systems. For now, it’s a placeholder—we’ll use it in future chapters (e.g., for collision detection). The `MovementSystem` still handles the actual position update, but it could later listen for `:entity_moved` to react to movement.

Update `game.rb` to integrate the new components and systems:

```ruby
# game.rb
require_relative "lib/components/position"
require_relative "lib/components/movement"
require_relative "lib/components/render"
require_relative "lib/components/input"
require_relative "lib/entity"
require_relative "lib/systems/movement_system"
require_relative "lib/systems/render_system"
require_relative "lib/systems/input_system"
require_relative "lib/world"

world = World.new(width: 10, height: 5)

# Create player entity
player = world.create_entity
player.add_component(Components::Position.new(0, 0))   # Start at top-left
player.add_component(Components::Movement.new)       # Add movement capability
player.add_component(Components::Render.new("@"))     # Render as "@"
player.add_component(Components::Input.new)         # Make input-responsive

# Add systems (order: input -> movement -> render)
world.add_system(Systems::InputSystem.new(world.event_manager))
world.add_system(Systems::MovementSystem.new)
world.add_system(Systems::RenderSystem.new(10, 5))

# Start the game
world.run
```

Run `ruby game.rb`, and you’ll see the familiar 10x5 grid with an `@` at (0, 0). Type `w`, `a`, `s`, or `d` and press Enter to move, or `q` to quit. The input now flows through events, making it more modular.

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
│   │   └── input.rb  (new)
│   ├── systems/
│   │   ├── movement_system.rb
│   │   ├── render_system.rb
│   │   └── input_system.rb  (new)
│   ├── entity.rb
│   ├── event.rb  (new)
│   └── world.rb
├── spec/
│   ├── components/
│   │   ├── position_spec.rb
│   │   ├── movement_spec.rb
│   │   ├── render_spec.rb
│   │   └── input_spec.rb  (new, below)
│   ├── systems/
│   │   ├── movement_system_spec.rb
│   │   ├── render_system_spec.rb
│   │   └── input_system_spec.rb  (new, below)
│   ├── entity_spec.rb
│   ├── event_spec.rb  (new, below)
│   ├── world_spec.rb
│   └── game_spec.rb
└── README.md
```

New tests:

- `spec/components/input_spec.rb`:
```ruby
# spec/components/input_spec.rb
require_relative "../../lib/components/input"

RSpec.describe Components::Input do
  it "serializes and deserializes" do
    input = Components::Input.new
    expect(Components::Input.from_h(input.to_h)).to be_a(Components::Input)
  end
end
```

- `spec/event_spec.rb`:
```ruby
# spec/event_spec.rb
require_relative "../lib/event"

RSpec.describe Event do
  it "stores type and data" do
    event = Event.new(:key_pressed, { key: "w" })
    expect(event.type).to eq(:key_pressed)
    expect(event.data[:key]).to eq("w")
  end
end
```

- `spec/systems/input_system_spec.rb`:
```ruby
# spec/systems/input_system_spec.rb
require_relative "../../lib/systems/input_system"
require_relative "../../lib/entity"
require_relative "../../lib/components/input"
require_relative "../../lib/components/movement"
require_relative "../../lib/world"

RSpec.describe Systems::InputSystem do
  it "updates movement component on key press" do
    world = World.new
    entity = Entity.new(1)
      .add_component(Components::Input.new)
      .add_component(Components::Movement.new)
    system = Systems::InputSystem.new(world.event_manager)
    world.event_manager.queue(Event.new(:key_pressed, { key: "d" }))
    system.process([entity])
    expect(entity.get_component(Components::Movement).dx).to eq(1)
  end
end
```

Run `bundle exec rspec` to confirm everything works.

## Outcome

By the end of this chapter, you’ve:
- Introduced `Event` and `EventManager` in `World`.
- Created `InputComponent` and `InputSystem`.
- Mapped keys (`w`, `a`, `s`, `d`) to movement commands.
- Processed events like `:entity_moved`.

You can now control the game with a responsive, event-driven input system! The player moves turn-by-turn, and the architecture is ready for more events (e.g., collisions, item pickups). In the next chapter, we’ll add walls and collision detection to shape the maze. Run `ruby game.rb`, enjoy the smoother input flow, and let’s keep building!

---

### Notes on Changes

- The game remains turn-based, waiting for input with `gets.chomp`.
- The `InputSystem` processes `:key_pressed` events before `MovementSystem` updates positions, ensuring proper order.
- `:entity_moved` is queued but unused for now—future systems (e.g., collision) can listen for it.

This event-driven approach makes the game more extensible while keeping the ECS pattern clean.