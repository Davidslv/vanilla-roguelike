# Chapter 19: Testing Your Roguelike

## Testing ECS: Testing Systems in Isolation

ECS architecture makes testing easier because systems are independent. You can test a system without setting up the entire game.

### Testing a System

```ruby
describe MovementSystem do
  let(:world) { Vanilla::World.new }
  let(:system) { Vanilla::Systems::MovementSystem.new(world) }

  it "moves entity to new position" do
    # Create test entity
    entity = Vanilla::Entity.new
    entity.add_component(PositionComponent.new(row: 5, column: 5))
    entity.add_component(MovementComponent.new(active: true))
    entity.add_component(InputComponent.new(move_direction: :north))
    entity.add_component(RenderComponent.new(character: '@'))

    world.add_entity(entity)

    # Create test grid
    grid = create_test_grid(10, 10)
    world.set_level(Vanilla::Level.new(grid: grid, difficulty: 1))

    # Execute movement
    system.move(entity, :north)

    # Verify
    position = entity.get_component(:position)
    expect(position.row).to eq(4)
    expect(position.column).to eq(5)
  end
end
```

You test the system with:
- Mock entities (just the components needed)
- Test grid (simple, known state)
- No game loop needed
- Fast, isolated tests

## Testing Algorithms: Verifying Maze Generation

Maze generation algorithms can be tested by verifying properties:

```ruby
describe BinaryTree do
  it "creates a spanning tree" do
    grid = Grid.new(10, 10)
    BinaryTree.on(grid)

    # Verify all cells are reachable
    start = grid[0, 0]
    distances = start.distances

    grid.each_cell do |cell|
      expect(distances[cell]).not_to be_nil
    end
  end

  it "has bias toward northeast" do
    # Test algorithm characteristics
    # (implementation depends on how you measure bias)
  end
end
```

Algorithm tests verify:
- Correctness (creates valid mazes)
- Properties (spanning tree, connectivity)
- Characteristics (bias, dead ends)

## Integration Testing: Testing System Interactions

Integration tests verify systems work together:

```ruby
describe "Combat Integration" do
  it "kills monster when health reaches zero" do
    # Setup
    world = create_test_world
    player = create_player(world)
    monster = create_monster(world, health: 10)

    # Execute
    combat_system = world.systems.find { |s, _| s.is_a?(CombatSystem) }[0]
    combat_system.process_attack(player, monster)

    # Verify
    expect(world.get_entity(monster.id)).to be_nil
    expect(world.entities.size).to eq(1)  # Only player remains
  end
end
```

Integration tests:
- Use real systems (not mocks)
- Test interactions between systems
- Verify end-to-end behavior
- Catch integration bugs

## Good Architecture Makes Testing Easier

ECS makes testing easier because:
- **Systems are independent**: Test in isolation
- **Components are data**: Easy to create test entities
- **Events are observable**: Verify through events
- **No hidden state**: Everything is explicit

## Key Takeaway

Testing ECS is straightforward: test systems in isolation, test algorithms for correctness, test integrations for system interactions. Good architecture makes testing easier by keeping systems independent and state explicit.

## Exercises

1. **Write a test**: Write a test for `CombatSystem.calculate_damage`. What edge cases would you test?

2. **Test an algorithm**: How would you test that Recursive Backtracker creates fewer dead ends than Binary Tree?

3. **Integration test**: Design an integration test for the full combat flow (attack → damage → death → loot).

4. **Test strategy**: What's your testing strategy? Unit tests, integration tests, or both?

