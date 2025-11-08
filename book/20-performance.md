# Chapter 20: Performance Considerations

## When to Optimize: Measure First, Optimize Second

Premature optimization is the root of all evil. Optimize when you have a problem, not before.

### The Optimization Process

1. **Build it**: Make it work first
2. **Measure it**: Find the actual bottlenecks
3. **Optimize it**: Fix the real problems

Don't optimize based on assumptions. Measure first.

### Profiling

Use profiling tools to find bottlenecks:

```ruby
require 'benchmark'

# Profile system update
time = Benchmark.measure do
  world.update(nil)
end

puts "Update took: #{time.real} seconds"
```

Profile to find:
- Which systems are slow
- Which queries are expensive
- Where time is actually spent

## Spatial Partitioning: Optimizing Entity Queries

As entity count grows, querying all entities becomes expensive. Spatial partitioning divides the world into regions.

### The Problem

```ruby
# Slow: checks all entities
def find_entities_at_position(row, column)
  @world.query_entities([:position]).select do |entity|
    pos = entity.get_component(:position)
    pos.row == row && pos.column == column
  end
end
```

This checks every entity every time. With 1000 entities, that's 1000 checks per query.

### The Solution: Spatial Grid

```ruby
class SpatialGrid
  def initialize(rows, columns)
    @grid = Array.new(rows) { Array.new(columns) { [] } }
  end

  def add_entity(entity, row, column)
    @grid[row][column] << entity
  end

  def entities_at(row, column)
    @grid[row][column]
  end
end
```

Now queries are O(1) instead of O(n). Only check entities in the target cell.

## Algorithm Efficiency: Choosing the Right Maze Algorithm

Different algorithms have different performance characteristics:

- **Binary Tree**: O(n) - visits each cell once
- **Aldous-Broder**: O(n²) worst case - random walk can be slow
- **Recursive Backtracker**: O(n) - efficient depth-first search
- **Recursive Division**: O(n log n) - recursive division

For large grids, choose efficient algorithms. But remember: measure first. A slow algorithm might be fine if generation happens once per level.

## Performance Tips

### Cache Queries

If you query the same thing multiple times, cache the result:

```ruby
# Bad: queries every frame
def update
  entities = entities_with(:position, :render)
  entities.each { |e| render(e) }
end

# Good: cache if possible
def update
  @renderable_entities ||= entities_with(:position, :render)
  @renderable_entities.each { |e| render(e) }
end
```

### Batch Operations

Process entities in batches when possible:

```ruby
# Process all movement at once
movable = entities_with(:position, :movement)
movable.each { |e| process_movement(e) }
```

### Avoid Unnecessary Allocations

Reuse objects in hot paths:

```ruby
# Bad: creates new array every time
def update
  entities = entities_with(:position, :render)
end

# Good: reuse if possible
@entity_cache ||= []
@entity_cache.clear
# ... populate cache ...
```

## Key Takeaway

Optimize when you have a problem, not before. Measure to find real bottlenecks. Use spatial partitioning for entity queries. Choose efficient algorithms, but don't optimize prematurely. Good architecture often performs well without optimization.

## Exercises

1. **Profile your game**: Add timing to system updates. Which systems are slowest?

2. **Spatial partitioning**: How would you implement spatial partitioning for your roguelike? What data structure would you use?

3. **Algorithm choice**: For a 100x100 grid, which algorithm would you choose? Why?

4. **Optimization strategy**: What's your optimization strategy? When would you optimize?

