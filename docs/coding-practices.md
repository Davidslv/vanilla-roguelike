# Ruby Coding Practices Guide

This guide outlines best practices for writing clean, readable, and maintainable Ruby code, with a focus on organizing methods within classes. These conventions are designed to improve collaboration, reduce confusion, and make code easier to navigate.

## Table of Contents

* Method Ordering in Classes
* General Ruby Best Practices

## Method Ordering in Classes

While Ruby doesn’t enforce method order, a consistent structure improves readability and helps developers quickly understand a class’s purpose and behavior. Use the following guidelines when organizing methods:

### Recommended Order

1.  **Initialization (`initialize`)**
    * Place first as it defines the object’s setup and dependencies.
    * Example: Constructor with instance variables and subscriptions.
2.  **Core Lifecycle Methods**
    * Methods like `update` and `render` that define the class’s primary role in a system (e.g., game loop).
    * Group together for prominence.
3.  **Interaction/State Methods**
    * Methods for user interaction or querying state (e.g., `selection_mode?`, `toggle_selection_mode`).
    * Order by logical flow (e.g., state checks before state changes).
4.  **Event Handlers**
    * Methods like `handle_event` that respond to external events.
    * Place after lifecycle methods since they’re reactive.
5.  **Helper Methods**
    * Utility methods (e.g., `log_message`, `add_message`) that support the main functionality.
    * Group by purpose (e.g., all logging methods together).
6.  **Private Methods**
    * Implementation details marked with `private`.
    * Order by dependency (e.g., a method called by another should appear after it).

### Tips

* **Group Related Methods:** Keep methods with similar purposes together (e.g., all logging methods).
* **Use Comments as Signposts:** Add brief comments (e.g., `# --- Event Handling ---`) to separate sections.
* **Keep Public API First:** Public methods should precede private ones to emphasize the class’s interface.

## General Ruby Best Practices

Beyond method ordering, follow these practices to write high-quality Ruby code:

### Naming

* Use `snake_case` for methods and variables (e.g., `log_message`).
* Use descriptive names that reveal intent (e.g., `trim_message_queue` vs. `trim`).
* Use `?` for predicate methods (e.g., `selection_mode?`) and `!` for mutating methods when applicable.

### Code Structure

* **Single Responsibility:** Each method should do one thing well. Split large methods like `handle_event` into smaller helpers if they grow too complex.
* **Keep Methods Short:** Aim for methods under 10-15 lines. Refactor long methods into smaller ones.
* **Use Constants:** Define magic numbers or repeated values as constants (e.g., `MAX_MESSAGES = 100`).

### Comments

* Add comments for *why*, not *what*. Example: `# Don’t toggle off here — let the command decide` explains a design choice.
* Avoid redundant comments (e.g., don’t write `# Logs a message` above `log_message`).

### Error Handling and Safety

* Use early returns for guard clauses (e.g., `return unless @manager.selection_mode`).
* Handle nil cases safely (e.g., `entity&.has_tag?(:player)`).

### Performance

* Avoid unnecessary allocations in hot paths (e.g., reuse objects in `update` if possible).
* Use efficient data structures (e.g., arrays for queues, hashes for lookups).