# Chapter 14: User Interface Improvements

Welcome back, dungeon crafters! Your roguelike is a thrilling maze of exploration and danger, but the player's experience could use some polish. Right now, feedback is scattered across terminal output, and key info like health or inventory is hard to track. In this chapter, we'll spruce up the interface with a `MessageSystem` to deliver game feedback (like "You picked up a potion"), an `InventoryRenderSystem` for a proper inventory screen, and a basic HUD to show health and level number. We'll also ensure the game immediately responds when the player reaches the stairs, advancing to the next level without delay. By the end, your players will interact with a cleaner, more engaging UI—making every move feel alive. Let's give your game a shiny new face!

## Creating a MessageSystem for Game Feedback

The `MessageSystem` will collect and display feedback messages—like "You hit the Goblin" or "You picked up a potion"—in a consistent spot. It'll listen to events and store messages in a queue, rendering them below the game grid.

Create `lib/systems/message_system.rb`:

```ruby
# lib/systems/message_system.rb
require_relative "../event"

module Systems
  class MessageSystem
    def initialize(event_manager)
      @event_manager = event_manager
      @messages = []  # Queue of recent messages
      @max_messages = 5  # Limit display to 5 lines
    end

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
        when :level_completed
          level_num = event.data[:level]
          @messages << "You completed level #{level_num}!"
        when :player_died
          @messages << "You have been defeated!"
        end
        @messages.shift if @messages.size > @max_messages  # Keep only the latest
      end
    end

    def render
      puts "\nMessages:"
      @messages.each { |msg| puts "  #{msg}" }
    end
  end
end
```

### How It Works

- **Event Listener**: Grabs events from the EventManager and turns them into readable messages.
- **Queue**: Stores up to `@max_messages` (5) entries, dropping the oldest with `shift`.
- **Render**: Prints messages below the grid—called later in the game loop.
- **Level Completion**: Adds a message when the player completes a level.

## Rendering an Inventory Screen with InventoryRenderSystem

The inventory needs its own screen, triggered by a key (e.g., `i`), to list items clearly. The `InventoryRenderSystem` will handle this, pausing the game to show the player's stash.

Create `lib/systems/inventory_render_system.rb`:

```ruby
# lib/systems/inventory_render_system.rb
require_relative "../event"

module Systems
  class InventoryRenderSystem
    def initialize(world, event_manager)
      @world = world
      @event_manager = event_manager
      @showing = false  # Toggle for inventory screen
    end

    def process(_entities)
      @event_manager.process do |event|
        next unless event.type == :key_pressed && event.data[:key] == "i"
        @showing = !@showing  # Toggle on/off
        render if @showing
      end
    end

    def render
      return unless @showing
      system("clear") || system("cls")
      puts "Inventory Screen (Press 'i' to return)"
      puts "------------------------------------"
      player = @world.entities.values.find { |e| e.has_component?(Components::Inventory) }
      if player && player.has_component?(Components::Inventory)
        inventory = player.get_component(Components::Inventory)
        if inventory.items.empty?
          puts "  Empty"
        else
          inventory.items.each_with_index do |item_id, i|
            item = @world.entities[item_id]
            next unless item
            item_comp = item.get_component(Components::Item)
            puts "  #{i + 1}. #{item_comp.name} (#{item_comp.weight} wt)"
          end
        end
      else
        puts "  No inventory found!"
      end
      puts "------------------------------------"
    end

    def showing?
      @showing
    end
  end
end
```

### How It Works

- **Toggle**: Listens for `i` key presses to show/hide the screen.
- **Render**: Clears the terminal and lists inventory items with numbers and weights, pausing the game until `i` is pressed again.
- **State**: `@showing` tracks whether the inventory is active, checked later to pause gameplay.

Update `InputSystem` to avoid movement during inventory display:

```ruby
# lib/systems/input_system.rb (snippet)
    def process(entities)
      @event_manager.process do |event|
        next unless event.type == :key_pressed
        key = event.data[:key]
        player = entities.find { |e| e.has_component?(Components::Input) }
        next unless player

        # Skip movement if inventory is showing
        inventory_system = @event_manager.instance_variable_get(:@world).systems.find { |s| s.is_a?(Systems::InventoryRenderSystem) }
        next if inventory_system&.showing? && key != "i"

        case key
        when "w" then issue_move_command(player, 0, -1)
        when "s" then issue_move_command(player, 0, 1)
        when "a" then issue_move_command(player, -1, 0)
        when "d" then issue_move_command(player, 1, 0)
        end
      end
    end
```

- **Pause**: Skips movement keys unless inventory is hidden or `i` is pressed to toggle.

## Adding a Basic HUD (Health, Level Number)

The HUD will display persistent info—health and level number—above the grid, keeping players informed without clutter.

Create `lib/systems/hud_system.rb`:

```ruby
# lib/systems/hud_system.rb
module Systems
  class HudSystem
    def initialize(world)
      @world = world
    end

    def render
      player = @world.entities.values.find { |e| e.has_component?(Components::Health) }
      health = player&.get_component(Components::Health)
      level = @world.current_level
      puts "Health: #{health ? "#{health.current}/#{health.max}" : "N/A"} | Level: #{level}"
      puts "------------------------------------"
    end
  end
end
```

### How It Works

- **Health**: Fetches the player's `HealthComponent` and shows `current/max`.
- **Level**: Uses the `current_level` attribute from `World` for display.
- **Render**: Prints above the grid, called in the game loop.

## Improving Level Completion Feedback

Let's update how the game handles level completion to provide immediate feedback to the player. We'll modify the `World` class to check for level completion right after processing movement:

```ruby
# lib/world.rb (updated run method)
def run
  setup_level
  Logger.info("Game started")

  while @running
    # Handle input first - this is critical for responsive gameplay
    handle_input

    # Process all systems in order
    @systems.each do |system|
      Logger.debug("Processing system: #{system.class.name}")
      case system
      when Systems::MazeSystem
        system.process(@entities.values)
      when Systems::InputSystem
        system.process(@entities.values)
      when Systems::MovementSystem
        system.process(@entities.values, @width, @height)
        # Check for level completion immediately after movement
        check_level_completion
      when Systems::RenderSystem
        system.process(@entities.values)
      when Systems::HudSystem, Systems::MessageSystem, Systems::InventoryRenderSystem
        system.process(@entities.values)
      end
    end

    # Render UI components if not in inventory
    unless @systems.any? { |s| s.is_a?(Systems::InventoryRenderSystem) && s.showing? }
      @systems.each { |s| s.render if s.respond_to?(:render) && !s.is_a?(Systems::InventoryRenderSystem) }
    end

    # Always render inventory if showing
    @systems.each { |s| s.render if s.respond_to?(:render) && s.is_a?(Systems::InventoryRenderSystem) }

    # Clear events after the turn
    @event_manager.clear
  end

  Logger.info("Game ended")
  puts "Goodbye!"
end
```

We also need to update the `check_level_completion` method to provide visual feedback when a level is completed:

```ruby
# lib/world.rb (updated check_level_completion method)
def check_level_completion
  player = @entities.values.find { |e| e.has_component?(Components::Input) }
  stairs = @entities.values.find { |e| e.get_component(Components::Render)&.character == "%" }

  return unless player && stairs

  player_pos = player.get_component(Components::Position)
  stairs_pos = stairs.get_component(Components::Position)

  return unless player_pos.x == stairs_pos.x && player_pos.y == stairs_pos.y

  # Visual feedback for level completion
  system("clear") || system("cls")
  puts "\n\n"
  puts "  🎉 Level #{@current_level} completed! 🎉"
  puts "  Loading level #{@current_level + 1}..."
  puts "\n\n"
  sleep(1) # Brief pause for effect

  # Queue level completion event
  @event_manager.queue(Event.new(:level_completed, { level: @current_level }))

  Logger.info("Level #{@current_level} completed")
  @current_level += 1
  setup_level
end
```

These changes ensure that:
1. Level completion is checked immediately after movement is processed
2. The player gets immediate visual feedback when completing a level
3. A message is added to the MessageSystem for level completion
4. The game advances to the next level automatically

## Integrating the UI Systems

Update `game.rb` to include the new systems and adjust the render order:

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

world = World.new(width: 20, height: 10)

player = world.create_entity
player.add_component(Components::Position.new(1, 1))
player.add_component(Components::Movement.new)
player.add_component(Components::Render.new("@"))
player.add_component(Components::Input.new)
player.add_component(Components::Inventory.new)
player.add_component(Components::Health.new(50))

# Add systems (order matters)
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
world.add_system(Systems::RenderSystem.new(20, 10))

# Start the game
world.run
```

## Outcome

By integrating these UI improvements, your roguelike game now offers:

1. A `MessageSystem` that displays game events like picking up items and completing levels
2. An `InventoryRenderSystem` for a clean, dedicated inventory screen when 'i' is pressed
3. A `HudSystem` showing health and level information at all times
4. Immediate level progression when the player reaches the stairs
5. Visual feedback when completing a level

These enhancements create a more polished, responsive experience for the player. The UI now clearly communicates what's happening in the game, making the dungeon crawling experience more engaging and intuitive.

With proper level completion detection integrated directly after movement processing, players can now smoothly progress through the game without any extra key presses or delays. The combination of visual feedback, informative messages, and automatic level progression creates a seamless gameplay flow.

In the next chapter, we'll continue enhancing the player experience by adding sound effects and more advanced gameplay mechanics!

---

### Notes for Readers

- **Terminal Limits**: This UI fits a text-based game—health and messages stay visible, inventory pauses for focus.
- **Customization**: Add more HUD stats (e.g., item count) or message types (e.g., combat logs) as you see fit.
- **Event Power**: The `MessageSystem` uses events—tap into others like `:level_changed` for more feedback.

This gives readers a solid UI foundation!