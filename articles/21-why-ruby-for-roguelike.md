# Why I Chose Ruby to Build a Roguelike Game

I'm not a game developer. Not by training, anyway. I spend most of my days building web applications, APIs, and the occasional data pipeline. So when I decided to build a roguelike game – you know, those dungeon crawlers with ASCII graphics and procedurally generated mazes – choosing Ruby felt both natural and slightly mad.

Ruby for game development? Really?

Let me explain why it turned out to be the right choice for this project, and why the journey has been more enjoyable than I expected.

## The Unconventional Choice

When you tell someone you're building a game in Ruby, you get… looks. Most game developers reach for C++, C#, or perhaps Python. Ruby isn't exactly known for game development. It's not fast, it's not typically used for graphics, and it doesn't have a massive game development ecosystem.

But here's the thing: I wasn't building the next AAA title. I was building a turn-based roguelike that runs in the terminal. Performance wasn't my bottleneck – understanding game architecture was. And for that, Ruby's clarity and expressiveness turned out to be perfect.

## Rapid Iteration Changed Everything

The first thing I noticed was how quickly I could experiment. No compilation step. No waiting. Just change the code and run it. This made an enormous difference when implementing different maze generation algorithms.

I ended up building four different maze algorithms: Binary Tree, Aldous-Broder, Recursive Backtracker, and Recursive Division. Each one creates a different feel to the dungeon. Here's how simple the Binary Tree algorithm looks in Ruby:

```ruby
class BinaryTree < AbstractAlgorithm
  def self.on(grid)
    grid.each_cell do |cell|
      has_north = !cell.north.nil?
      has_east = !cell.east.nil?

      if has_north && has_east
        cell.link(cell: rand(2) == 0 ? cell.north : cell.east, bidirectional: true)
      elsif has_north
        cell.link(cell: cell.north, bidirectional: true)
      elsif has_east
        cell.link(cell: cell.east, bidirectional: true)
      end
    end

    grid
  end
end
```

Look how readable that is. `grid.each_cell` reads like English. The logic is clear: for each cell, randomly connect it either north or east. I could tweak this, run it, see the results immediately, and iterate. No fuss.

When you're learning game architecture – which I was – this feedback loop is invaluable. I could focus on understanding the algorithms rather than fighting with compilation errors or complex toolchains.

## Entity-Component-System Felt Natural in Ruby

The core architecture of my roguelike uses the Entity-Component-System (ECS) pattern. In ECS:
- **Entities** are game objects (player, monsters, items)
- **Components** are data containers (position, health, inventory)
- **Systems** are logic that operates on entities with specific components

Ruby made this architecture feel elegant. Take querying entities, for example. I needed a way to find all entities that have certain components – say, everything that can move and be rendered:

```ruby
def query_entities(component_types)
  return @entities.values if component_types.empty?

  @entities.values.select { |entity|
    component_types.all? { |type| entity.has_component?(type) }
  }
end
```

This is actual code from my `World` class. It's concise, readable, and does exactly what you'd expect. The `select` and `all?` methods chain together beautifully. Duck typing means I don't have to declare types everywhere – if an entity responds to `has_component?`, it works.

In systems, I can write things like:

```ruby
def entities_with(*component_types)
  @world.query_entities(component_types)
end

# Find all entities that can move
movable = entities_with(:position, :movement)

# Find all entities that can be rendered
renderable = entities_with(:position, :render)
```

The splat operator (`*component_types`) lets me pass any number of component types. It reads like a conversation: "Give me entities with these components."

## Components Are Beautifully Simple

Components in ECS should be pure data – no logic, just storage. Ruby makes this trivial. Here's my entire `PositionComponent`:

```ruby
class PositionComponent < Component
  attr_reader :row, :column

  def initialize(row:, column:)
    super()
    @row = row
    @column = column
  end

  def type
    :position
  end

  def set_position(row, column)
    @row = row
    @column = column
  end
end
```

That's it. No boilerplate. No getters and setters cluttering the code. Ruby's `attr_reader` handles that for me. The named parameters (`row:, column:`) make it clear what you're passing when you create a component:

```ruby
position = PositionComponent.new(row: 5, column: 10)
```

Compare this to languages where you need builder patterns or telescoping constructors just to maintain readability. Ruby gets out of your way and lets you express intent.

## The Testing Ecosystem Was a Game-Changer

I'll be honest – I didn't expect testing to matter so much for a game. But procedural generation? That needs testing. How do you test randomness? How do you know your maze algorithm actually creates valid paths?

RSpec made this surprisingly pleasant. Ruby's seeding capability meant I could test the same "random" maze repeatedly:

```ruby
RSpec.describe Vanilla::Components::PositionComponent do
  describe '#initialize' do
    it 'sets row and column' do
      component = described_class.new(row: 5, column: 10)
      expect(component.row).to eq(5)
      expect(component.column).to eq(10)
    end
  end
end
```

The tests read like specifications. When something broke – and believe me, things broke frequently when I was learning ECS – the tests told me exactly what failed and why. RSpec's error messages are clear. The syntax is minimal. I could focus on what I was testing rather than wrestling with testing frameworks.

I ended up with 48 spec files covering components, systems, algorithms, and game logic. Having that test coverage meant I could refactor with confidence. When I restructured the command system from simple hashes to proper Command objects, the tests caught every place I'd broken something.

## The Command Pattern Felt Elegant

Input handling in games can get messy quickly. Different keys do different things. Some actions are valid only in certain states. How do you keep this organised?

The Command pattern helped enormously. Here's a simplified version of my `MoveCommand`:

```ruby
class MoveCommand < Command
  VALID_DIRECTIONS = [:north, :south, :east, :west].freeze

  def initialize(entity, direction)
    raise InvalidDirectionError unless VALID_DIRECTIONS.include?(direction)
    @entity = entity
    @direction = direction
  end

  def execute(world)
    movement_system = world.systems.find { |s, _| s.is_a?(MovementSystem) }&.first
    return unless movement_system

    movement_system.move(@entity, @direction)
  end
end
```

Ruby's constants, symbols, and blocks made this clean. The `freeze` ensures no one modifies valid directions. Symbols (`:north`, `:south`) are lightweight and readable. The safe navigation operator (`&.`) handles the case where the movement system doesn't exist.

Each command is self-contained. It knows what it needs and what it does. Adding new commands is straightforward – just create a new class that inherits from `Command` and implements `execute`.

## Events and Queues Just Worked

My game has an event system for debugging and logging. When things happen – entity moves, combat occurs, level changes – events get published. Ruby's standard library had everything I needed:

```ruby
def initialize
  @event_subscribers = Hash.new { |h, k| h[k] = [] }
  @event_queue = Queue.new
  @command_queue = Queue.new
end

def emit_event(event_type, data = {})
  @event_queue << [event_type, data]
end

def subscribe(event_type, subscriber)
  @event_subscribers[event_type] << subscriber
end
```

`Hash.new` with a block automatically initialises empty arrays for new event types. `Queue` is thread-safe and simple to use. The `<<` operator reads naturally – "push this onto the queue."

No external dependencies needed. No complex event bus library. Ruby's standard library was sufficient, which kept the codebase lean and the dependencies minimal.

## Developer Joy Actually Matters

Here's something I didn't expect to value so much: Ruby made me happy while coding.

When I write `entity.has_component?(:position)`, it reads like a question I'd ask a colleague. When I write `entities_with(:health, :combat)`, it's obvious what I'm asking for. The code communicates intent clearly.

Ruby's blocks made iteration pleasant. Instead of for-loops with indices, I could write:

```ruby
@systems.each do |system, priority|
  system.update(nil)
end
```

The intent is clear. The syntax is minimal. I'm not distracted by ceremony.

This mattered more than I thought it would. When you're learning complex concepts – and game architecture was new to me – having the language stay out of your way is valuable. I could focus on understanding ECS, event systems, and procedural generation rather than fighting with syntax or type systems.

## What About Performance?

Let's address the elephant in the room: Ruby isn't fast.

For my use case, it didn't matter. The game is turn-based. It waits for player input. There's no frantic real-time rendering. The bottleneck is human reaction time, not Ruby's execution speed.

The maze generation? Fast enough. We're talking about grids that are maybe 80×40 cells. Even the slowest algorithm (Aldous-Broder) completes in milliseconds. Entity-component queries? I'm working with dozens of entities, not thousands. Ruby handles this trivially.

If I were building a real-time action game with hundreds of entities updating 60 times per second, Ruby would be the wrong choice. But I wasn't. Context matters. Choose tools appropriate for your problem.

## What I Learned

Building this roguelike taught me that language choice isn't just about performance or ecosystem size. It's about matching the tool to both the problem and your workflow.

Ruby let me:
- **Iterate rapidly** without compilation overhead
- **Express ideas clearly** with minimal syntax
- **Test effectively** with excellent tooling
- **Stay focused** on game design rather than language complexity
- **Enjoy the process** which kept me motivated

That last point might sound soft, but it's real. When you're building something complex in your spare time, enjoyment matters. If I'd chosen a language I found frustrating, I might have abandoned the project. Ruby kept me engaged.

The game now has procedurally generated mazes, multiple algorithms, an Entity-Component-System architecture, event-driven logging, command-based input handling, and a comprehensive test suite. Not bad for a language supposedly "not meant for games."

## The Right Tool for the Job

Would I recommend Ruby for all game development? No. For performance-critical games, you need a faster language. For games requiring specific engines or frameworks, you go where those tools are.

But for learning game architecture? For prototyping game mechanics? For building turn-based games where clarity matters more than speed? Ruby is genuinely excellent.

The readability helped me understand patterns I'd only read about. The testing tools helped me validate complex systems. The lack of compilation overhead kept me in a creative flow. Ruby let me focus on the hard parts – understanding game design – rather than fighting with boilerplate or tooling.

Choose tools that serve your goals. For me, building a roguelike while learning game architecture, Ruby was perfect. Your mileage may vary, and that's fine. The important thing is picking something that lets you build, learn, and grow.

And honestly? I'm still building. There's combat to improve, more monster behaviours to implement, items to add. But Ruby has proven it can handle everything I've thrown at it so far.

If you're curious, the code is on GitHub as "Vanilla" – a roguelike written in Ruby, inspired by the 1980s classic Rogue. Feel free to have a look and see if Ruby's expressiveness works for you as well as it did for me.

Thank you for reading, David Silva

---

*Word count: ~2,100 words*

