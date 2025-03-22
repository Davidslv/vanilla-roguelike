# ECS Refactoring Implementation Plan

## Overview

This document outlines a comprehensive implementation plan to address the issues identified in the ECS Implementation Issues Diagnosis. The plan is structured into distinct phases, each with clear objectives, specific tasks, code examples, and validation criteria. This approach allows for incremental improvement while maintaining game functionality throughout the process.

Rather than a complete rewrite, this plan focuses on targeted refactoring of the existing codebase to properly implement ECS principles and resolve the architectural issues causing crashes when adding new components or systems.

## Phase 0: Preparation and Initial Setup (2 weeks)

Before beginning the refactoring process, we need to establish baseline requirements and infrastructure.

### Tasks

1. **Create a Baseline Test Suite (Week 1)**
   - Implement integration tests that verify core game functionality
   - Create snapshot tests of game state at key points
   - Document known bugs as pending tests to be fixed

2. **Define ECS Standards Document (Week 1)**
   - Document architectural rules and patterns
   - Define component and system interfaces
   - Create naming conventions and code style guidelines

3. **Set Up Development Workflow (Week 2)**
   - Create feature branches for each phase
   - Set up continuous integration for test running
   - Establish code review process

4. **Create Component and System Inventory (Week 2)**
   - Document all existing components and their responsibilities
   - Document all existing systems and their dependencies
   - Identify responsibility overlaps and conflicts

### Validation Criteria

- Complete test suite passing on current codebase
- Documentation of current architecture with identified issues
- Development workflow in place for tracking changes

## Phase 1: Component Purification (3 weeks)

In this phase, we'll refactor components to adhere to ECS principles by removing behavior and enforcing data-only components.

### Tasks

1. **Refactor Position Component (Week 1)**

   Before:
   ```ruby
   class PositionComponent < Component
     attr_accessor :row, :column

     def initialize(row, column)
       @row = row
       @column = column
     end

     # Remove these behavior methods
     def move_north
       @row -= 1
     end

     def move_south
       @row += 1
     end

     # etc...
   end
   ```

   After:
   ```ruby
   class PositionComponent < Component
     attr_reader :row, :column  # Change to attr_reader for controlled access

     def initialize(row, column)
       @row = row
       @column = column
     end

     # Only provide setter methods that ensure valid state
     def set_position(row, column)
       @row = row
       @column = column
     end

     # More specific methods that clearly express intent
     def translate(delta_row, delta_column)
       @row += delta_row
       @column += delta_column
     end
   end
   ```

2. **Refactor Render Component (Week 1)**

   Before:
   ```ruby
   class RenderComponent < Component
     attr_accessor :char, :color

     def initialize(char, color = nil)
       @char = char
       @color = color
     end

     # Remove behavior methods
     def draw(display, row, column)
       display.draw_char(@char, row, column, @color)
     end
   end
   ```

   After:
   ```ruby
   class RenderComponent < Component
     attr_reader :char, :color, :layer

     def initialize(char, color = nil, layer = 0)
       @char = char
       @color = color
       @layer = layer  # Add layer for z-ordering
     end

     def update_appearance(char, color = nil)
       @char = char
       @color = color unless color.nil?
     end
   end
   ```

3. **Refactor All Other Components (Weeks 2-3)**
   - Apply the same pattern to all remaining components
   - Remove behavior methods from components
   - Add proper encapsulation with clear accessors
   - Document component responsibilities and valid states

### Validation Criteria

- All components are pure data containers with no behavior
- Test suite passes with refactored components
- Component documentation is complete and accurate

## Phase 2: Entity Simplification (2 weeks)

In this phase, we'll simplify entities to be pure component containers, moving all game logic to systems.

### Tasks

1. **Create Base Entity Class (Week 1)**

   ```ruby
   class Entity
     attr_reader :id, :components

     def initialize(id = SecureRandom.uuid)
       @id = id
       @components = {}
       @tags = Set.new  # Simple string tags for quick filtering
     end

     def add_component(component)
       component_type = component.class.component_type
       @components[component_type] = component
       self
     end

     def remove_component(component_type)
       @components.delete(component_type)
       self
     end

     def get_component(component_type)
       @components[component_type]
     end

     def has_component?(component_type)
       @components.key?(component_type)
     end

     def add_tag(tag)
       @tags.add(tag.to_s)
       self
     end

     def remove_tag(tag)
       @tags.delete(tag.to_s)
       self
     end

     def has_tag?(tag)
       @tags.include?(tag.to_s)
     end
   end
   ```

2. **Refactor Player Entity (Week 1)**

   Before:
   ```ruby
   class Player < Entity
     def initialize(row, column, name = "Hero")
       super()
       add_component(PositionComponent.new(row, column))
       add_component(RenderComponent.new('@'))
       add_component(PlayerComponent.new(name))
       # etc...
     end

     # Remove game logic methods
     def move(direction)
       # Movement logic
     end

     def attack(monster)
       # Combat logic
     end
   end
   ```

   After:
   ```ruby
   # Factory function approach instead of subclassing
   module EntityFactory
     def self.create_player(world, row, column, name = "Hero")
       entity = Entity.new
       entity.add_component(PositionComponent.new(row, column))
       entity.add_component(RenderComponent.new('@'))
       entity.add_component(PlayerComponent.new(name))
       entity.add_component(HealthComponent.new(100))
       entity.add_component(InputComponent.new)
       entity.add_tag(:player)

       world.add_entity(entity)
       entity
     end
   end
   ```

3. **Refactor All Other Entity Types (Week 2)**
   - Convert all entity subclasses to factory functions
   - Move entity-specific logic to appropriate systems
   - Use entity tags for quick identification instead of inheritance

### Validation Criteria

- No entity classes with game logic exist
- All entities are created through factory functions
- Game functionality remains intact with refactored entities

## Phase 3: System Implementation (4 weeks)

In this phase, we'll refactor systems to follow proper ECS principles, operate independently, and communicate through components.

### Tasks

1. **Create System Base Class (Week 1)**

   ```ruby
   class System
     attr_reader :world

     def initialize(world)
       @world = world
     end

     # Called once per frame by the game loop
     def update(delta_time)
       # Override in subclasses
     end

     # Helper method to find entities with specific components
     def entities_with(*component_types)
       @world.query_entities(component_types)
     end

     # Helper to notify the world about events
     def emit_event(event_type, data = {})
       @world.emit_event(event_type, data)
     end
   end
   ```

2. **Implement Input System (Week 1)**

   ```ruby
   class InputSystem < System
     def update(delta_time)
       # Get player entity
       player = @world.find_entity_by_tag(:player)
       return unless player && player.has_component?(:input)

       input_component = player.get_component(:input)

       # Process keyboard input
       if @world.keyboard.key_pressed?(:up)
         input_component.move_direction = :north
       elsif @world.keyboard.key_pressed?(:down)
         input_component.move_direction = :south
       elsif @world.keyboard.key_pressed?(:left)
         input_component.move_direction = :west
       elsif @world.keyboard.key_pressed?(:right)
         input_component.move_direction = :east
       else
         input_component.move_direction = nil
       end

       # Process other inputs
       input_component.action_triggered = @world.keyboard.key_pressed?(:space)

       # Clear one-shot inputs after processing
       emit_event(:input_processed, { entity_id: player.id })
     end
   end
   ```

3. **Implement Movement System (Week 2)**

   ```ruby
   class MovementSystem < System
     def update(delta_time)
       # Get all entities with position and movement components
       movable_entities = entities_with(:position, :movement)

       movable_entities.each do |entity|
         movement = entity.get_component(:movement)
         next unless movement.active?

         # Handle movement based on input component if present
         if entity.has_component?(:input)
           input = entity.get_component(:input)
           movement.direction = input.move_direction
         end

         # Skip if no movement direction
         next unless movement.direction

         position = entity.get_component(:position)
         new_position = calculate_new_position(position, movement.direction)

         # Check for collision
         unless position_blocked?(new_position)
           old_position = { row: position.row, column: position.column }
           position.set_position(new_position[:row], new_position[:column])

           # Emit movement event for other systems
           emit_event(:entity_moved, {
             entity_id: entity.id,
             old_position: old_position,
             new_position: { row: position.row, column: position.column }
           })
         end

         # Clear movement direction if it was processed
         movement.direction = nil if entity.has_component?(:input)
       end
     end

     private

     def calculate_new_position(position, direction)
       row, col = position.row, position.column

       case direction
       when :north then { row: row - 1, column: col }
       when :south then { row: row + 1, column: col }
       when :east then { row: row, column: col + 1 }
       when :west then { row: row, column: col - 1 }
       else { row: row, column: col }
       end
     end

     def position_blocked?(position)
       # Check level grid for obstacles
       grid = @world.current_level.grid
       cell = grid[position[:row], position[:column]]
       return true unless cell

       # Check if cell blocks movement
       cell.blocks_movement?
     end
   end
   ```

4. **Implement Collision System (Week 2)**

   ```ruby
   class CollisionSystem < System
     def initialize(world)
       super
       @world.subscribe(:entity_moved, self)
     end

     def update(delta_time)
       # Handle collision detection that needs to run every frame
       # Most collisions are handled via events
     end

     def handle_event(event_type, data)
       return unless event_type == :entity_moved

       entity_id = data[:entity_id]
       entity = @world.get_entity(entity_id)
       return unless entity

       position = data[:new_position]

       # Find entities at the same position
       entities_at_position = find_entities_at_position(position)
       entities_at_position.each do |other_entity|
         next if other_entity.id == entity_id

         # Emit collision event
         emit_event(:entities_collided, {
           entity_id: entity_id,
           other_entity_id: other_entity.id,
           position: position
         })
       end
     end

     private

     def find_entities_at_position(position)
       entities_with(:position).select do |entity|
         pos = entity.get_component(:position)
         pos.row == position[:row] && pos.column == position[:column]
       end
     end
   end
   ```

5. **Implement Render System (Week 3)**

   ```ruby
   class RenderSystem < System
     def update(delta_time)
       # Clear screen
       @world.display.clear

       # Draw level grid
       render_grid

       # Get all entities with position and render components
       renderables = entities_with(:position, :render)

       # Sort by render layer
       renderables.sort_by! do |entity|
         entity.get_component(:render).layer
       end

       # Draw entities
       renderables.each do |entity|
         position = entity.get_component(:position)
         render = entity.get_component(:render)

         @world.display.draw_char(
           render.char,
           position.row,
           position.column,
           render.color
         )
       end

       # Update display
       @world.display.refresh
     end

     private

     def render_grid
       grid = @world.current_level.grid
       grid.rows.times do |row|
         grid.columns.times do |col|
           cell = grid[row, col]
           @world.display.draw_char(
             cell.char,
             row,
             col,
             cell.color
           )
         end
       end
     end
   end
   ```

6. **Implement Level Transition System (Week 3)**

   ```ruby
   class LevelTransitionSystem < System
     def initialize(world)
       super
       @world.subscribe(:entities_collided, self)
     end

     def update(delta_time)
       # System logic that needs to run every frame
     end

     def handle_event(event_type, data)
       return unless event_type == :entities_collided

       entity_id = data[:entity_id]
       other_entity_id = data[:other_entity_id]

       # Check if player collided with stairs
       player = @world.get_entity(entity_id)
       other = @world.get_entity(other_entity_id)

       if player&.has_tag?(:player) && other&.has_tag?(:stairs)
         handle_level_transition(player)
       elsif other&.has_tag?(:player) && player&.has_tag?(:stairs)
         handle_level_transition(other)
       end
     end

     private

     def handle_level_transition(player)
       # Queue level transition command instead of immediate action
       emit_event(:level_transition_requested, {
         player_id: player.id,
         difficulty: @world.current_level.difficulty + 1
       })
     end
   end
   ```

7. **Implement Message System (Week 4)**

   ```ruby
   class MessageSystem < System
     def initialize(world)
       super
       @world.subscribe(:entity_moved, self)
       @world.subscribe(:entities_collided, self)
       @world.subscribe(:level_transition_requested, self)
       @world.subscribe(:level_transitioned, self)
     end

     def update(delta_time)
       # Process any queued messages
       process_message_queue
     end

     def handle_event(event_type, data)
       case event_type
       when :entity_moved
         entity = @world.get_entity(data[:entity_id])
         if entity&.has_tag?(:player)
           add_message("movement.player_moved", importance: :low)
         end

       when :entities_collided
         # Handle collision messages

       when :level_transition_requested
         add_message("level.stairs_found", importance: :normal)

       when :level_transitioned
         difficulty = data[:difficulty]
         add_message("level.descended", { level: difficulty }, importance: :high)
       end
     end

     def add_message(key, metadata = {}, importance: :normal)
       # Consistent message API with clear parameter structure
       message = {
         key: key,
         metadata: metadata,
         importance: importance,
         timestamp: Time.now
       }

       @message_queue << message
       trim_message_queue if @message_queue.size > 100
     end

     private

     def process_message_queue
       # Process and display messages
     end

     def trim_message_queue
       # Keep message queue at a reasonable size
     end
   end
   ```

8. **Implement All Other Required Systems (Week 4)**
   - Combat system
   - AI system
   - Item system
   - Any other required game systems

### Validation Criteria

- All game logic is contained in systems
- Systems communicate through components and events
- No direct system-to-system calls exist
- Game functionality remains intact with refactored systems

## Phase 4: World and Event Implementation (3 weeks)

In this phase, we'll create a proper World class to manage entities and systems, and implement an event system for communication.

### Tasks

1. **Implement World Class (Week 1)**

   ```ruby
   class World
     attr_reader :entities, :systems, :keyboard, :display, :current_level

     def initialize
       @entities = {}
       @systems = []
       @keyboard = KeyboardHandler.new
       @display = DisplayHandler.new
       @current_level = nil
       @event_subscribers = Hash.new { |h, k| h[k] = [] }
       @event_queue = Queue.new
       @command_queue = Queue.new
     end

     def add_entity(entity)
       @entities[entity.id] = entity
       entity
     end

     def remove_entity(entity_id)
       @entities.delete(entity_id)
     end

     def get_entity(entity_id)
       @entities[entity_id]
     end

     def find_entity_by_tag(tag)
       @entities.values.find { |e| e.has_tag?(tag) }
     end

     def query_entities(component_types)
       return @entities.values if component_types.empty?

       @entities.values.select do |entity|
         component_types.all? { |type| entity.has_component?(type) }
       end
     end

     def add_system(system, priority = 0)
       @systems << [system, priority]
       @systems.sort_by! { |s, p| p }
     end

     def update(delta_time)
       # Process queued commands
       process_commands

       # Update all systems
       @systems.each do |system, _|
         system.update(delta_time)
       end

       # Process events after systems have updated
       process_events
     end

     def queue_command(command_type, params = {})
       @command_queue << [command_type, params]
     end

     def emit_event(event_type, data = {})
       @event_queue << [event_type, data]
     end

     def subscribe(event_type, subscriber)
       @event_subscribers[event_type] << subscriber
     end

     def unsubscribe(event_type, subscriber)
       @event_subscribers[event_type].delete(subscriber)
     end

     def set_level(level)
       @current_level = level
     end

     private

     def process_events
       # Process all queued events
       until @event_queue.empty?
         event_type, data = @event_queue.pop
         @event_subscribers[event_type].each do |subscriber|
           subscriber.handle_event(event_type, data)
         end
       end
     end

     def process_commands
       # Process all queued commands
       until @command_queue.empty?
         command_type, params = @command_queue.pop
         handle_command(command_type, params)
       end
     end

     def handle_command(command_type, params)
       case command_type
       when :change_level
         change_level(params[:difficulty], params[:player_id])
       when :add_entity
         add_entity(params[:entity])
       when :remove_entity
         remove_entity(params[:entity_id])
       # Other command handlers...
       end
     end

     def change_level(difficulty, player_id)
       # Create new level
       level_generator = LevelGenerator.new
       new_level = level_generator.generate(difficulty)

       # Transfer player to new level
       player = get_entity(player_id)
       if player
         # Place player at entrance
         position = player.get_component(:position)
         position.set_position(new_level.entrance_row, new_level.entrance_column)
       end

       # Set new level
       set_level(new_level)

       # Notify systems of level change
       emit_event(:level_transitioned, {
         difficulty: difficulty,
         player_id: player_id
       })
     end
   end
   ```

2. **Create Event System (Week 2)**

   ```ruby
   # Event system is integrated into the World class
   # Here's how a typical event handler would look in a system:

   class CombatSystem < System
     def initialize(world)
       super
       # Subscribe to relevant events
       world.subscribe(:attack_requested, self)
       world.subscribe(:entity_died, self)
     end

     def update(delta_time)
       # Regular update logic
     end

     def handle_event(event_type, data)
       case event_type
       when :attack_requested
         handle_attack(data[:attacker_id], data[:target_id])
       when :entity_died
         handle_death(data[:entity_id])
       end
     end

     private

     def handle_attack(attacker_id, target_id)
       attacker = @world.get_entity(attacker_id)
       target = @world.get_entity(target_id)

       return unless attacker && target
       return unless attacker.has_component?(:combat) && target.has_component?(:health)

       # Calculate damage
       combat = attacker.get_component(:combat)
       health = target.get_component(:health)

       damage = calculate_damage(combat, target)
       health.current_health -= damage

       # Emit damage event
       emit_event(:damage_dealt, {
         attacker_id: attacker_id,
         target_id: target_id,
         damage: damage
       })

       # Check for death
       if health.current_health <= 0
         emit_event(:entity_died, {
           entity_id: target_id,
           killer_id: attacker_id
         })
       end
     end

     def handle_death(entity_id)
       # Handle entity death
     end

     def calculate_damage(combat, target)
       # Damage calculation logic
     end
   end
   ```

3. **Implement Command Queue (Week 2)**

   ```ruby
   # Command system is integrated into the World class
   # Here's how systems would queue commands:

   class ItemSystem < System
     def initialize(world)
       super
       world.subscribe(:entities_collided, self)
     end

     def handle_event(event_type, data)
       return unless event_type == :entities_collided

       entity_id = data[:entity_id]
       other_entity_id = data[:other_entity_id]
       entity = @world.get_entity(entity_id)
       other = @world.get_entity(other_entity_id)

       # Check if player collided with item
       if entity&.has_tag?(:player) && other&.has_tag?(:item)
         handle_item_pickup(entity, other)
       elsif other&.has_tag?(:player) && entity&.has_tag?(:item)
         handle_item_pickup(other, entity)
       end
     end

     private

     def handle_item_pickup(player, item)
       # Queue command to add item to inventory
       @world.queue_command(:add_to_inventory, {
         player_id: player.id,
         item_id: item.id
       })

       # Queue command to remove item from level
       @world.queue_command(:remove_entity, {
         entity_id: item.id
       })

       # Emit event for other systems (like MessageSystem)
       emit_event(:item_picked_up, {
         player_id: player.id,
         item_id: item.id,
         item_name: item.get_component(:item).name
       })
     end
   end
   ```

4. **Integration Testing (Week 3)**
   - Test entity creation and management
   - Test system registration and execution
   - Test event publication and subscription
   - Test command queueing and processing

### Validation Criteria

- World class properly manages entities and systems
- Event system enables decoupled communication
- Command queue provides consistent state updates
- All tests pass without errors

## Phase 5: Game Integration (2 weeks)

In this phase, we'll integrate all the refactored components into the main game loop and ensure everything works together.

### Tasks

1. **Refactor Game Class (Week 1)**

   ```ruby
   class Game
     def initialize
       # Create world and dependencies
       @world = World.new

       # Add systems
       @world.add_system(InputSystem.new(@world), 1)
       @world.add_system(MovementSystem.new(@world), 2)
       @world.add_system(CollisionSystem.new(@world), 3)
       @world.add_system(CombatSystem.new(@world), 4)
       @world.add_system(AISystem.new(@world), 5)
       @world.add_system(LevelTransitionSystem.new(@world), 6)
       @world.add_system(RenderSystem.new(@world), 7)
       @world.add_system(MessageSystem.new(@world), 8)

       # Create initial level
       level_generator = LevelGenerator.new
       starting_level = level_generator.generate(1)
       @world.set_level(starting_level)

       # Create player entity
       player = EntityFactory.create_player(
         @world,
         starting_level.entrance_row,
         starting_level.entrance_column
       )

       # Game loop variables
       @running = true
       @last_update_time = Time.now
     end

     def run
       while @running
         # Calculate delta time
         current_time = Time.now
         delta_time = current_time - @last_update_time
         @last_update_time = current_time

         # Update world (and all systems)
         @world.update(delta_time)

         # Check for exit condition
         @running = false if @world.keyboard.key_pressed?(:escape)

         # Sleep to limit frame rate
         sleep_time = [0, (1.0 / 60) - delta_time].max
         sleep(sleep_time) if sleep_time > 0
       end
     end
   end
   ```

2. **Create Level Generator (Week 1)**

   ```ruby
   class LevelGenerator
     def generate(difficulty)
       level = Level.new(difficulty)

       # Generate level layout
       # ...

       # Create level entities
       create_level_entities(level)

       level
     end

     private

     def create_level_entities(level)
       # Create stairs
       stairs = Entity.new
       stairs.add_component(PositionComponent.new(level.exit_row, level.exit_column))
       stairs.add_component(RenderComponent.new('>'))
       stairs.add_tag(:stairs)
       level.add_entity(stairs)

       # Create monsters
       spawn_monsters(level)

       # Create items
       spawn_items(level)
     end

     def spawn_monsters(level)
       # Monster spawning logic
     end

     def spawn_items(level)
       # Item spawning logic
     end
   end
   ```

3. **Integration Testing (Week 2)**
   - Test full game loop with all systems
   - Verify level transitions work correctly
   - Test player movement and collision
   - Test combat and other game mechanics

### Validation Criteria

- Game runs with refactored ECS architecture
- All core functionality works correctly
- No crashes when transitioning levels
- Performance is acceptable

## Phase 6: Testing and Quality Assurance (3 weeks)

In this phase, we'll focus on comprehensive testing and quality assurance to ensure the refactored codebase is robust and maintainable.

### Tasks

1. **Unit Tests for Components (Week 1)**
   - Test component initialization
   - Test component state changes
   - Test component interfaces

2. **Unit Tests for Systems (Week 1)**
   - Test system initialization
   - Test system update methods
   - Test system event handlers

3. **Integration Tests (Week 2)**
   - Test system interactions
   - Test event propagation
   - Test command processing

4. **End-to-End Tests (Week 2)**
   - Test complete game scenarios
   - Test level generation and transitions
   - Test player progression

5. **Performance Testing (Week 3)**
   - Measure frame rates with different entity counts
   - Identify and resolve performance bottlenecks
   - Test memory usage patterns

6. **Edge Case Testing (Week 3)**
   - Test unusual input combinations
   - Test boundary conditions
   - Test error recovery scenarios

### Validation Criteria

- Comprehensive test suite with high coverage
- No regressions in functionality
- Performance meets or exceeds original codebase
- Edge cases are properly handled

## Phase 7: Documentation and Refinement (2 weeks)

In this final phase, we'll create comprehensive documentation and apply final refinements to the codebase.

### Tasks

1. **Code Documentation (Week 1)**
   - Document all classes, methods, and parameters
   - Create architecture overview
   - Document system relationships and dependencies

2. **Developer Guides (Week 1)**
   - Create guide for adding new components
   - Create guide for adding new systems
   - Document common patterns and best practices

3. **Refinement and Optimization (Week 2)**
   - Apply final code style improvements
   - Remove any unused code
   - Optimize critical paths

4. **Future Planning (Week 2)**
   - Document future improvements
   - Create roadmap for feature additions
   - Identify potential future refactorings

### Validation Criteria

- Comprehensive documentation for all code
- Clear developer guides for future work
- Codebase follows consistent style and patterns
- Performance is optimized for critical paths

## Risk Mitigation and Contingency Plans

1. **Development Risks**
   - **Risk**: Incomplete refactoring introduces new bugs
     - **Mitigation**: Implement changes incrementally with thorough testing at each step

   - **Risk**: Performance degradation with new architecture
     - **Mitigation**: Include performance testing at each phase, optimize critical paths

2. **Scheduling Risks**
   - **Risk**: Phases take longer than estimated
     - **Mitigation**: Include buffer time in each phase, prioritize features to ensure core functionality is addressed first

   - **Risk**: Unexpected technical challenges
     - **Mitigation**: Allocate additional time for exploratory work in complex areas

3. **Operational Risks**
   - **Risk**: Knowledge gaps in ECS implementation
     - **Mitigation**: Provide team training, pair programming for complex changes

   - **Risk**: Difficulty maintaining game functionality during refactoring
     - **Mitigation**: Maintain comprehensive test suite, use feature flags for incremental changes

## Total Implementation Timeline

| Phase | Duration | Description |
|-------|----------|-------------|
| Phase 0 | 2 weeks | Preparation and Initial Setup |
| Phase 1 | 3 weeks | Component Purification |
| Phase 2 | 2 weeks | Entity Simplification |
| Phase 3 | 4 weeks | System Implementation |
| Phase 4 | 3 weeks | World and Event Implementation |
| Phase 5 | 2 weeks | Game Integration |
| Phase 6 | 3 weeks | Testing and Quality Assurance |
| Phase 7 | 2 weeks | Documentation and Refinement |
| **Total** | **21 weeks** | **Approximately 5 months** |

This implementation plan provides a structured approach to refactoring the Vanilla roguelike game's ECS architecture. By addressing the fundamental issues identified in the diagnosis, this plan will result in a properly implemented ECS architecture that is maintainable, extendable, and robust against the types of crashes that have been occurring.

## Expected Outcomes

After completing this refactoring plan, the Vanilla roguelike game will have:

1. **Proper ECS Implementation**
   - Components as pure data
   - Systems with clear responsibilities
   - Entities as simple component containers

2. **Decoupled Systems**
   - Event-based communication
   - No direct system-to-system dependencies
   - Clear data flow patterns

3. **Consistent State Management**
   - Centralized world state
   - Command-based state updates
   - Explicit component ownership

4. **Improved Maintainability**
   - Clear architecture patterns
   - Comprehensive documentation
   - Consistent coding standards

5. **Better Testability**
   - Independent component testing
   - System isolation for unit tests
   - Comprehensive integration tests

The result will be a codebase that is more maintainable, extendable, and resilient to changes, while preserving all existing functionality and enabling faster development of new features.