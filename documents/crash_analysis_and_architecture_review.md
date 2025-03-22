# Crash Analysis and Architecture Review

## Executive Summary

This document analyzes recent crashes in the Vanilla Roguelike game, explains their root causes, and proposes architectural improvements to prevent similar issues in the future. The game has shown a pattern of breaking when new components or systems are introduced, indicating structural weaknesses in the current architecture.

## Crash Analysis

### Recent Crash: Level Transition Failure

When a player reached the stairs to advance to the next level, the game consistently crashed with two distinct errors:

1. **Private Method Access Error**:
   ```
   [FATAL] Game crashed: private method 'update_grid_with_entities' called for an instance of Vanilla::Level
   ```

2. **Parameter Mismatch Error**:
   ```
   [ERROR] Error during level transition: wrong number of arguments (given 3, expected 1..2)
   [ERROR] /Users/davidslv/projects/vanilla/lib/vanilla/message_system.rb:39:in 'log_message'
   ```

### Root Causes

1. **Encapsulation Issues**: The `update_grid_with_entities` method in the Level class was marked as private but needed to be called from the Game class.

2. **Inconsistent API Usage**: The `log_message` method was called with inconsistent parameter formats throughout the codebase:
   ```ruby
   # Correct format:
   log_message(key, metadata: {data}, importance: :value, category: :value)

   # Incorrect format that caused errors:
   log_message(key, {data}, importance: :value, category: :value)
   ```

3. **Tight Coupling**: Game, Level, MovementSystem, and RenderSystem classes are tightly coupled, making changes in one class require changes in others.

4. **Lack of Comprehensive Testing**: These issues should have been caught by tests, but they weren't.

### Why These Issues Recur With New Components

The Vanilla codebase exhibits several architectural weaknesses that cause recurring issues when new components are added:

1. **Implicit Dependencies**: Many classes depend on each other implicitly rather than through well-defined interfaces.

2. **Mixed Responsibilities**: Classes like Game handle too many concerns (rendering, input, level management, etc.).

3. **Inconsistent Method Visibility**: The distinction between public and private methods is not consistently applied.

4. **Ambiguous Ownership**: It's unclear which class "owns" various game objects, leading to confusion about where methods should be called from.

5. **Brittle Service Location**: The ServiceRegistry pattern is implemented but used inconsistently.

## Architectural Improvement Proposals

Below are three proposals for architectural improvements, each addressing the issues from different angles:

### Proposal 1: Clean Architecture Implementation
### Proposal 2: Enhanced ECS with Dependency Injection
### Proposal 3: Event-Driven Architecture Refactoring

Each proposal will be detailed in separate documents for thorough evaluation.

## Conclusion

The Vanilla Roguelike game has a solid foundation but requires architectural improvements to ensure stability as features are added. By implementing one of the proposed architectural approaches, we can significantly reduce the occurrence of crashes and make the codebase more maintainable.

The separate proposal documents will provide detailed implementation plans, advantages, disadvantages, and transition strategies for each approach.