# Chapter 5: Maze Generation Algorithms

## Binary Tree Algorithm: The Simplest Starting Point

The Binary Tree algorithm is where Vanilla Roguelike began. It's the simplest maze generation algorithm, perfect for understanding the fundamentals before moving to more complex approaches.

### The Concept

For each cell in the grid, randomly choose to link it either north or east (if both are available). That's it. The entire algorithm fits in a few lines of code.

Here's how it works in Vanilla:

^code binary-tree

### Step-by-Step Walkthrough

Let's trace through what happens:

1. **Iterate over every cell**: The algorithm visits each cell exactly once
2. **Check available neighbours**: For each cell, see if it has a north and/or east neighbour
3. **Randomly choose**: If both exist, randomly pick one. If only one exists, use that one
4. **Create the link**: Link the cell to the chosen neighbour
5. **Set walls**: After linking, any cell with no links becomes a wall

### Visual Example

Imagine a 3x3 grid. Here's what might happen:

```
Initial state (all cells isolated):
[?][?][?]
[?][?][?]
[?][?][?]

After processing (example):
[→][→][↑]
[→][→][↑]
[→][→][↑]
```

Arrows show which direction each cell linked. Notice:
- Top row: All link east (can't link north, no neighbour)
- Right column: All link north (can't link east, no neighbour)
- Other cells: Randomly choose north or east

### Characteristics of Binary Tree Mazes

Binary Tree creates mazes with distinct properties:

**Bias toward northeast:**
- Cells always link north or east, never south or west
- This creates a diagonal bias, paths tend to flow northeast
- The northeast corner is always reachable from anywhere

^aside binary-bias
The diagonal bias is a fingerprint. Show a maze experienced reader a Binary Tree output and they will name the algorithm at a glance, just from the north-east drift of the corridors. Every algorithm leaves traces like this; learning to recognise them is half of understanding them.
^endaside

**Many dead ends:**
- Because cells only link in two directions, many paths end abruptly
- This creates challenging navigation, you'll hit many dead ends

**Fast generation:**
- Visits each cell once
- Simple logic, no backtracking or complex state
- Very efficient for large grids

### Performance Characteristics

**Time Complexity**: O(n) where n = number of cells. Visits each cell exactly once, with constant work per cell. Fast and predictable.

**Space Complexity**: O(1) additional space. No extra data structures, works in-place on the grid.

### Why Start Here?

Binary Tree is perfect for learning because:

1. **Simplicity**: The algorithm is easy to understand completely
2. **Immediate results**: You see a working maze right away
3. **Foundation**: Concepts learned here apply to all maze algorithms
4. **Debugging**: When something goes wrong, it's easy to trace

### The Algorithm Flow

```d2
direction: down

start: "Start: Create Grid"
each: "For Each Cell\n(repeat for all cells)"
has_ne: "Has North AND East?" {shape: diamond}
random: "Random: North or East"
link_n: "Link North"
link_e: "Link East"
skip: "Skip"
create: "Create Link"
walls: "Set Walls for Unlinked Cells"
done: "Complete Maze"

start -> each
each -> has_ne
has_ne -> random: Yes
has_ne -> link_n: Only North
has_ne -> link_e: Only East
has_ne -> skip: Neither
random -> create
link_n -> create
link_e -> create
skip -> walls
create -> walls
walls -> done
```

### Understanding the Randomness

The `rand(2).zero?` check randomly chooses between north and east. This randomness is what makes each maze unique. But notice: the randomness is constrained. You can only link north or east, never south or west. This constraint is what creates the algorithm's characteristic bias.

### From Algorithm to Playable Maze

Once the algorithm runs, you have a grid with linked cells. But that's not enough for a game, you need to render it. The algorithm sweeps the grid one more time to convert the link structure into tiles:

```ruby
grid.each_cell do |cell|
  if cell.links.empty?
    cell.tile = Vanilla::Support::TileType::WALL  # '#'
  end
end
```

Cells with links keep their default floor tile. Cells without links become walls (`#`).

### The Journey Begins

This simple algorithm was Vanilla's starting point in April 2020. It wasn't perfect, the bias was obvious, dead ends were frustrating, but it worked. It created playable mazes. And that was enough to begin the journey.

From here, you can:
- Experiment with different random choices
- Try linking in different directions
- Understand why the bias exists
- Move on to more sophisticated algorithms

## Key Takeaway

The Binary Tree algorithm demonstrates the core concept of maze generation: visit cells, create links, render the result. It's simple, biased, and imperfect, but it works. Understanding this algorithm gives you the foundation to appreciate more sophisticated approaches.

## Exercises

1. **Trace the algorithm**: On paper, draw a 4x4 grid. Manually run the Binary Tree algorithm, making random choices. What does the resulting maze look like?

2. **Modify the bias**: What if you changed the algorithm to link south or west instead? How would the maze feel different?

3. **Count dead ends**: Generate a Binary Tree maze and count how many dead ends it has. Compare this to mazes from other algorithms (once you learn them).

4. **Implement it**: Try implementing Binary Tree in your own code. Start with a simple grid structure, then add the linking logic.
