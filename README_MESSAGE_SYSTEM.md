# Vanilla Roguelike: Message System Implementation

## Overview

This document explains the message system implementation for the Vanilla roguelike game. The message system provides player feedback, displays combat information, environment descriptions, and supports interactive elements such as selectable options.

## Features

- **Localized messages** using I18n for multi-language support
- **Message categories** for organizing different types of messages (combat, items, system, etc.)
- **Visual emphasis** based on message importance (critical, warning, normal, success)
- **Message history** with scrolling capabilities
- **Interactive elements** including selectable options and shortcut keys
- **Mode switching** between navigation and message selection

## Architecture

The message system consists of four primary components:

1. **Message** - Individual message objects with properties like text, category, and importance
2. **MessageLog** - Storage and management of all messages, including filtering and selection
3. **MessagePanel** - UI component that renders messages below the map
4. **MessageManager** - Coordinates between the game and message components

## Component Details

### Message Class

The `Message` class represents individual messages with properties:

```ruby
# Create a simple message
message = Message.new("You found a potion!",
                     category: :item,
                     importance: :normal)

# Create a translatable message
message = Message.new(:item_found,
                     category: :item,
                     metadata: { item: "healing potion" })

# Create a selectable message with a callback
message = Message.new("Pick up the sword",
                     selectable: true,
                     shortcut_key: 'p') { |msg| pick_up_item("sword") }
```

### MessageLog Class

The `MessageLog` manages messages and provides methods for adding, retrieving, and selecting messages:

```ruby
# Add a message
message_log.add("Combat message", category: :combat, importance: :warning)

# Add a translated message
message_log.add_translated("combat.player_hit",
                         metadata: { enemy: "goblin", damage: 5 })

# Add multiple selectable options
message_log.add_selectable_options({
  "Open the chest" => -> { open_chest(chest) },
  "Examine the chest" => -> { examine_chest(chest) },
  "Leave it alone" => -> { /* do nothing */ }
})

# Get recent messages
recent_messages = message_log.get_recent(10)

# Get messages by category
combat_messages = message_log.get_by_category(:combat)
```

### MessagePanel Class

The `MessagePanel` renders messages below the map using the game's renderer:

```ruby
# Set up a message panel below the map
message_panel = MessagePanel.new(
  0,             # x position (left edge)
  map_height,    # y position (just below the map)
  map_width,     # width
  5              # height (number of visible messages)
)

# Render the panel
message_panel.render(renderer, selection_mode)

# Scroll up/down
message_panel.scroll_up()
message_panel.scroll_down()
```

### MessageManager Class

The `MessageManager` provides a simplified interface for game code to interact with the message system:

```ruby
# Log a message
message_manager.log_message("You found a sword!")

# Log a translated message
message_manager.log_translated("items.found", metadata: { item: "healing potion" })

# Present options to the player
message_manager.log_options({
  "Fight" => -> { start_combat(enemy) },
  "Run away" => -> { escape_combat() }
})

# Toggle message selection mode
message_manager.toggle_selection_mode()

# Handle player input for the message system
handled = message_manager.handle_input(key)
```

## User Interface

The message system displays messages below the map area:

```
+-------------------------------------------+
|                                           |
|              @ (player)                   |
|                                           |
|             GAME MAP AREA                 |
|                                           |
+-------------------------------------------+
| You strike the goblin for 5 damage!       | <- Combat message
| The goblin misses you.                    |
| You find a healing potion.                |
| o) Pick up the healing potion             | <- Selectable option
+-------------------------------------------+
```

## Interaction Modes

### Direct Selection with Shortcut Keys

Players can directly select options using shortcut keys without entering selection mode:

```
+-------------------------------------------+
| You discover a chest. What do you do?     |
| o) Open the chest                         | <- Press 'o' to select
| e) Examine the chest for traps            | <- Press 'e' to select
| l) Leave it alone                         | <- Press 'l' to select
+-------------------------------------------+
```

### Selection Mode

For more complex interactions, players can enter selection mode (Tab key):

```
+-------------------------------------------+
| [MESSAGE SELECTION MODE]                  |
| You find several items on the ground:     |
| > p) Pick up the healing potion           | <- Currently selected option
| g) Pick up the gold coins                 |
| a) Pick up all items                      |
+-------------------------------------------+
| [Tab] Exit | [↑/↓] Navigate | [Enter] Select |
+-------------------------------------------+
```

## Integration with I18n

The message system integrates with Ruby's I18n gem for localization:

```ruby
# In locales/en.yml
en:
  combat:
    player_hit: "You strike the %{enemy} for %{damage} damage!"
    enemy_hit: "The %{enemy} hits you for %{damage} damage!"

# In code
message_log.add_translated("combat.player_hit",
                         metadata: { enemy: "goblin", damage: 5 })
```

## Usage Examples

### Basic Messages

```ruby
# Simple informational message
message_manager.log_message("You enter a dark room.")

# Combat message with translation
message_manager.log_translated("combat.player_hit",
                             category: :combat,
                             metadata: { enemy: "goblin", damage: 5 })

# Critical warning
message_manager.log_message("You are poisoned!",
                          importance: :critical,
                          category: :status)
```

### Interactive Options

```ruby
# Present multiple options to the player
message_manager.log_options({
  "Open the chest" => -> {
    # Logic to open the chest
    if chest.trapped?
      message_manager.log_message("It was trapped! You take 3 damage.", importance: :warning)
    else
      message_manager.log_message("You found 10 gold pieces!", importance: :success)
    end
  },
  "Examine the chest" => -> {
    message_manager.log_message("The chest appears to be trapped.")
  },
  "Leave it alone" => -> {
    message_manager.log_message("You decide not to risk it.")
  }
})
```

## Key Bindings

- **Tab** - Toggle message selection mode
- **Up/Down or j/k** - Navigate through selectable messages (in selection mode)
- **Enter** - Activate the currently selected message (in selection mode)
- **Shortcut keys** (a-z) - Directly activate options without entering selection mode

## Conclusion

The message system provides a flexible, localized, and interactive way to communicate with players in the Vanilla roguelike game. It supports both passive information display and active player choices, enhancing the gameplay experience.