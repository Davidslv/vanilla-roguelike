# Finding the Longest Path: A Key to Better Level Design

In roguelike game development, placing objectives at the right distance from the player is crucial for creating engaging gameplay. Too close, and the level feels trivial. Too far, and it becomes frustrating. The longest path algorithm provides a mathematical way to find optimal placement locations and measure maze complexity.

## What is the Longest Path?

The longest path in a maze is the path between two cells that requires the most steps to traverse. Unlike shortest path algorithms (like Dijkstra's), which find the quickest route, longest path algorithms find the route that maximizes exploration.

In graph theory terms, we're looking for the diameter of the graph—the longest shortest path between any two vertices.

## Why It Matters for Gameplay

The longest path has several important applications:

1. **Objective Placement**: Place stairs, quest items, or bosses at maximum distance to encourage exploration
2. **Difficulty Scaling**: Measure maze complexity to adjust difficulty
3. **Level Validation**: Ensure levels have sufficient complexity before accepting them
4. **Player Experience**: Create natural difficulty progression as players traverse longer paths

## The Algorithm: Two-Pass Dijkstra

The longest path algorithm uses Dijkstra's algorithm twice:

1. **First pass**: Find the cell farthest from the starting point
2. **Second pass**: From that farthest cell, find the cell farthest from it

The path between these two endpoints is guaranteed to be one of the longest paths in the maze.

```mermaid
flowchart LR
    A[Start: Player Cell] --> B[First Pass: Calculate Distances]
    B --> C[Find Farthest Cell]
    C --> D[Second Pass: Calculate Distances from Farthest]
    D --> E[Find Opposite Endpoint]
    E --> F[Extract Path Between Endpoints]
    F --> G[Longest Path Found]

    style A fill:#e1f5ff
    style C fill:#fff4e1
    style E fill:#fff4e1
    style G fill:#e8f5e9
```

This diagram illustrates the two-pass approach: first finding one end of the longest path, then finding the other end from that point.

### Implementation

Here's how Vanilla Roguelike implements it:

```ruby
class LongestPath < AbstractAlgorithm
  def self.on(grid, start:)
    # First pass: find farthest cell from start
    distances = start.distances
    new_start, = distances.max

    # Second pass: find farthest cell from new_start
    new_distances = new_start.distances
    goal, = new_distances.max

    # Store the path for visualization or use
    grid.distances = new_distances.path_to(goal)

    grid
  end
end
```

### Step-by-Step Breakdown

Let's trace through what happens:

1. **Start at player position**: `start` is typically the player's spawn point
2. **Calculate distances**: Run Dijkstra's from start to find all reachable cells and their distances
3. **Find farthest point**: Use `distances.max` to find the cell with maximum distance
4. **Second distance calculation**: Run Dijkstra's again from this farthest point
5. **Find opposite end**: The farthest point from the first farthest point is the other end of the longest path
6. **Extract path**: Use `path_to` to get the actual path between these two points

### The Distance Calculation

The `distances` method uses breadth-first search:

```ruby
def distances
  distances = DistanceBetweenCells.new(self)
  frontier = [self]

  while frontier.any?
    new_frontier = []

    frontier.each do |cell|
      cell.links.each do |linked|
        next if distances[linked]  # Already visited

        distances[linked] = distances[cell] + 1
        new_frontier << linked
      end
    end

    frontier = new_frontier
  end

  distances
end
```

This creates a distance map where each cell knows its distance from the root.

### Finding the Maximum

The `max` method finds the cell with the highest distance:

```ruby
def max
  max_distance = 0
  max_cell = @root

  @cells.each do |cell, distance|
    if distance > max_distance
      max_cell = cell
      max_distance = distance
    end
  end

  [max_cell, max_distance]
end
```

## Using Longest Path for Stairs Placement

In Vanilla Roguelike, we use a simplified version of longest path for stairs placement:

```ruby
def find_stairs_position(grid, player_cell)
  # Calculate distances from player
  distances = player_cell.distances

  # Find farthest cell (one end of longest path from player)
  farthest_cell = distances.max&.first || grid.random_cell

  { row: farthest_cell.row, column: farthest_cell.column }
end
```

This is essentially the first half of the longest path algorithm. We find the farthest point from the player and place stairs there.

### Why This Works

Placing stairs at the farthest point from the player:
- **Guarantees reachability**: The farthest point is always reachable (it's in the distance map)
- **Encourages exploration**: Players must traverse the entire maze
- **Creates natural difficulty**: Longer paths mean more encounters and challenges
- **Feels intentional**: Players sense the level was designed, not random

## Measuring Maze Complexity

The longest path length is a good measure of maze complexity:

```ruby
def measure_complexity(grid, start_cell)
  distances = start_cell.distances
  farthest_cell, distance = distances.max

  # Longer paths = more complex mazes
  case distance
  when 0..10
    :simple
  when 11..25
    :medium
  when 26..50
    :complex
  else
    :very_complex
  end
end
```

You can use this to:
- **Reject simple mazes**: If complexity is too low, regenerate
- **Scale difficulty**: Adjust monster count or item placement based on complexity
- **Balance gameplay**: Ensure levels have appropriate challenge

## Advanced: Full Longest Path

For more sophisticated placement, calculate the full longest path:

```ruby
def find_longest_path_endpoints(grid, start_cell)
  # First pass
  distances1 = start_cell.distances
  endpoint1, distance1 = distances1.max

  # Second pass
  distances2 = endpoint1.distances
  endpoint2, distance2 = distances2.max

  {
    start: start_cell,
    endpoint1: endpoint1,
    endpoint2: endpoint2,
    length: distance2,
    path: distances2.path_to(endpoint2)
  }
end
```

This gives you:
- Both endpoints of the longest path
- The actual path between them
- The path length

You can then:
- Place stairs at `endpoint2`
- Place important items along the path
- Use path length for difficulty scaling

## Performance Considerations

The longest path algorithm runs Dijkstra's twice, so it's O(2n) = O(n) for grid-based mazes where n is the number of cells. This is efficient enough for real-time generation.

However, for very large grids (> 1000x1000), consider:
- **Caching results**: If you generate multiple levels, cache longest paths
- **Approximation**: Use a sample of cells instead of full calculation
- **Background calculation**: Calculate longest path asynchronously

## Trade-offs

### Using Longest Path for Placement

**Pros:**
- Mathematically optimal placement
- Guarantees maximum exploration
- Creates natural difficulty progression
- Measurable complexity

**Cons:**
- Predictable placement (always farthest)
- May feel too structured
- Requires two pathfinding calculations
- Doesn't account for player preferences

### Alternatives

1. **Random placement**: Simple but may create trivial or frustrating levels
2. **Weighted random**: Place at random, but prefer farther cells
3. **Multiple candidates**: Calculate longest path, then randomly choose from top N farthest cells

## Implementation Tips

1. **Cache distance calculations**: If placing multiple entities, reuse distance maps
2. **Validate results**: Always check that longest path endpoints are valid cells
3. **Handle edge cases**: What if the maze is a single cell? What if all cells are walls?
4. **Visualize for debugging**: Draw the longest path to understand maze structure
5. **Combine with other metrics**: Use longest path with dead-end count, branching factor, etc.

## Lessons Learned

From implementing longest path in Vanilla Roguelike:

1. **Longest path creates better gameplay**: Players appreciate the intentional design
2. **Complexity measurement is valuable**: Helps ensure level quality
3. **Two-pass is worth it**: The extra calculation creates significantly better placement
4. **Visualization helps**: Seeing the longest path helps understand maze structure
5. **Combine techniques**: Longest path works well with other placement strategies

## Future Enhancements

The longest path algorithm opens up possibilities:

- **Dynamic difficulty**: Adjust longest path length based on player level
- **Path-based item placement**: Place items along the longest path for guaranteed discovery
- **Maze quality metrics**: Use longest path as one metric in a quality scoring system
- **Procedural quests**: Generate quests that follow the longest path

## Further Reading

- [Ensuring Player Accessibility in Procedurally Generated Levels](./01-ensuring-player-accessibility.md) - Using pathfinding for accessibility
- [Implementing Dijkstra's Algorithm for Game Pathfinding](./04-implementing-dijkstra.md) - Deep dive into Dijkstra's implementation
- [Optimizing Procedural Generation: When Speed Matters](./10-optimizing-procedural-generation.md) - Performance considerations

## Conclusion

The longest path algorithm is a powerful tool for roguelike level design. By finding the path that requires maximum exploration, you can place objectives optimally, measure maze complexity, and create more engaging gameplay experiences.

While it requires two pathfinding calculations, the benefits in terms of level quality and player experience make it worthwhile. Combined with other techniques like path verification and complexity measurement, longest path algorithms help create procedurally generated levels that feel intentional and well-designed.

