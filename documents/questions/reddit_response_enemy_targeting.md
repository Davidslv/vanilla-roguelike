# Reddit Question: How Enemies Tell the Player Apart from Other Enemies

Original question: https://www.reddit.com/r/roguelikedev/comments/1p1nr3v/how_do_you_actually_make_enemies_tell_the_player/

Great question! This is one of those deceptively simple design decisions that has significant architectural implications.

Honestly, I'm working on a Ruby roguelike with an ECS architecture, and I haven't really thought deeply about this until now. I just went with the simple approach that felt natural. But your question got me thinking about what the optimal solution would be, so let me share what I currently do and then explore what I think would be the better approach.

## Current Implementation: Hybrid Approach

My codebase currently uses a combination of **direct player reference** and **tag-based differentiation**. Here's how it works:

### 1. Direct Player Reference

The `MonsterSystem` receives a direct reference to the player entity during initialization:

```ruby
def initialize(world, player:, logger: nil)
  super(world)
  @player = player
  @monsters = []
  @logger = logger || Vanilla::Logger.instance
end
```

This player reference is then used throughout the system for collision detection and spawn placement:

```ruby
def player_collision?
  player_pos = @player.get_component(:position)
  monster_at(player_pos.row, player_pos.column) != nil
end

def find_spawn_location(grid)
  walkable_cells = []
  grid.each_cell do |cell|
    player_pos = @player.get_component(:position)
    distance = (cell.row - player_pos.row).abs + (cell.column - player_pos.column).abs
    next if distance < 5 # Ensure distance from player
    # ... rest of spawn logic
  end
end
```

### 2. Tag-Based Differentiation

I also use entity tags (`:player`, `:monster`, `:item`, etc.) as a primitive form of faction identification. The combat system checks tags to determine interaction types:

```ruby
# In AttackCommand
if @attacker.has_tag?(:player) && @target.has_tag?(:monster)
  @logger.info("[AttackCommand] Starting turn-based combat")
  combat_system.process_turn_based_combat(@attacker, @target)
else
  # Single attack for non-player attacks
  combat_system.process_attack(@attacker, @target)
end
```

The collision system also uses tags:

```ruby
if (entity.has_tag?(:player) && other_entity.has_tag?(:stairs)) ||
   (entity.has_tag?(:stairs) && other_entity.has_tag?(:player))
  player = entity.has_tag?(:player) ? entity : other_entity
  # Handle stairs interaction
end
```

## Trade-offs of the Current Approach

### Pros:
- **Simple and Direct**: No complex queries or filtering needed
- **Good Performance**: Direct reference lookup is O(1)
- **Easy to Debug**: Clear data flow and dependencies
- **Sufficient for Traditional Roguelikes**: Works perfectly for single player vs. monsters

### Cons:
- **Player-Centric Architecture**: Systems explicitly depend on the player entity
- **Limited Extensibility**: Can't easily support allied NPCs or complex faction relationships
- **No Monster Infighting**: Impossible to have monsters of different types fight each other
- **Testing Challenges**: Harder to test AI in isolation without a player entity

## What I Think Would Be the Optimal Approach: Faction Component System

Now that I've actually thought about it (thanks for the question!), if I were starting over or planning for a more complex game, I'd implement a proper faction system. Here's what I think that would look like:

### FactionComponent Design

```ruby
module Vanilla
  module Components
    class FactionComponent < Component
      attr_accessor :faction_id
      attr_reader :hostile_to

      def initialize(faction_id:, hostile_to: [])
        @faction_id = faction_id
        @hostile_to = Set.new(hostile_to)
      end

      def hostile_to?(other_faction_id)
        @hostile_to.include?(other_faction_id)
      end

      def ally_of?(other_faction_id)
        @faction_id == other_faction_id
      end

      def type
        :faction
      end
    end
  end
end
```

### Target Selection by Faction

Instead of explicitly looking for "the player", monsters would query for hostile entities:

```ruby
def find_hostile_targets_in_range(entity, range)
  entity_pos = entity.get_component(:position)
  entity_faction = entity.get_component(:faction)

  @world.query_entities([:position, :faction]).select do |other|
    next if other.id == entity.id

    other_pos = other.get_component(:position)
    other_faction = other.get_component(:faction)

    distance = (entity_pos.row - other_pos.row).abs +
               (entity_pos.column - other_pos.column).abs

    distance <= range && entity_faction.hostile_to?(other_faction.faction_id)
  end
end

def find_nearest_hostile(entity)
  targets = find_hostile_targets_in_range(entity, Float::INFINITY)
  return nil if targets.empty?

  entity_pos = entity.get_component(:position)
  targets.min_by do |target|
    target_pos = target.get_component(:position)
    (entity_pos.row - target_pos.row).abs + (entity_pos.column - target_pos.column).abs
  end
end
```

### Entity Initialization with Factions

```ruby
# Player
player = EntityFactory.create_player(row, col)
player.add_component(FactionComponent.new(
  faction_id: :hero_faction,
  hostile_to: [:monster_faction, :undead_faction, :demon_faction]
))

# Regular monsters
goblin = EntityFactory.create_monster('goblin', row, col)
goblin.add_component(FactionComponent.new(
  faction_id: :monster_faction,
  hostile_to: [:hero_faction, :npc_faction]
))

# Allied NPCs
guard = EntityFactory.create_npc('town_guard', row, col)
guard.add_component(FactionComponent.new(
  faction_id: :npc_faction,
  hostile_to: [:monster_faction, :undead_faction, :demon_faction]
))

# Undead that are hostile to everyone
zombie = EntityFactory.create_monster('zombie', row, col)
zombie.add_component(FactionComponent.new(
  faction_id: :undead_faction,
  hostile_to: [:hero_faction, :npc_faction, :monster_faction] # Even monsters fear the undead!
))
```

### Benefits of the Faction System

1. **Player-Agnostic Architecture**: The player is truly "just another actor" with a faction
2. **Allied NPCs**: Trivial to implement - just give them the same faction as the player
3. **Monster Infighting**: Different monster factions can fight each other organically
4. **Dynamic Relationships**: Change faction hostility at runtime (diplomacy, betrayal mechanics)
5. **Better Testability**: AI can be tested without a specific player entity
6. **Emergent Gameplay**: Complex multi-faction battles happen naturally
7. **Scalability**: Easy to add new factions without modifying core systems

### Example Emergent Scenarios

With a faction system, you get interesting scenarios for free:

```ruby
# Scenario 1: Three-way battle
# Player (hero_faction) enters a room where goblins (monster_faction)
# are fighting zombies (undead_faction). All three attack each other!

# Scenario 2: Temporary alliance
# Player drinks a "Faction Disguise" potion
player_faction.hostile_to.delete(:monster_faction)
# Now monsters ignore the player (until effect wears off)

# Scenario 3: NPC companion
# Guard follows player and attacks the same enemies
# No special "companion AI" needed - just matching factions

# Scenario 4: Civil war
# Some goblins switch to :rebel_goblin_faction
# Now regular goblins and rebel goblins fight each other
```

## When to Use Each Approach

### Use Direct Player Reference + Tags When:
- Building a traditional single-player roguelike
- Player is always the only target of interest
- Prototyping and want to move fast
- Performance is critical and you have many entities
- No plans for complex faction mechanics or allied NPCs

### Use Faction System When:
- Planning for allied NPCs or companions
- Want monster-vs-monster combat
- Building a more simulation-heavy roguelike
- Long-term extensibility is important
- Want emergent multi-faction gameplay
- Building something like Dwarf Fortress or Caves of Qud

## My Thoughts on Which to Choose

To be honest, I just went with the simple approach without overthinking it, and that's probably fine for most projects. **Start with the simple approach** (direct reference + tags) and refactor to factions if you need it. Don't over-engineer early - that's what I did and it's working out.

However, now that I've thought it through, if you know from the start you'll want any of these features, implement factions from day one:
- Allied NPCs or pets
- Monster infighting
- Dynamic faction relationships
- Multiple player-controlled characters

The tag system can actually serve as a stepping stone - you can think of tags as "implicit factions" and later refactor them into an explicit `FactionComponent` without changing too much code. That's basically what I have now - tags that could evolve into proper factions if I need them.

## Performance Considerations

One concern with the faction approach is performance - querying all entities to find hostiles can be expensive. Mitigations:

```ruby
# 1. Spatial partitioning - only check nearby entities
def find_hostile_targets_in_range(entity, range)
  # Use a spatial hash or quadtree to get nearby entities first
  nearby = @world.spatial_index.query_radius(entity_pos, range)
  nearby.select { |e| entity_faction.hostile_to?(e.get_component(:faction).faction_id) }
end

# 2. Cache hostile entities per faction
@hostile_cache ||= {}
@hostile_cache[faction_id] ||= @world.query_entities([:faction]).select do |e|
  my_faction.hostile_to?(e.get_component(:faction).faction_id)
end

# 3. Update cache only when needed (entity spawn/death, faction changes)
def invalidate_hostile_cache
  @hostile_cache.clear
end
```

## Conclusion

Both approaches are valid! The direct player reference is simpler and works great for traditional roguelikes. The faction system is more flexible and scalable but adds complexity.

I'll be honest - I went with the simple approach without really thinking about it, and it works perfectly fine for my traditional single-player roguelike. Your question made me think through what the optimal solution would be, and now I'm actually tempted to refactor to a faction system just for the architectural elegance, even though I don't strictly need it yet.

The beauty of ECS architecture is that you can start simple and refactor to the faction system later if needed - just add the `FactionComponent` and update systems to query by faction instead of checking for the player directly. I might actually do that now!

Hope this helps! Happy to discuss further or share more code examples if useful.

---

**TL;DR**: I currently use the simple approach (store player reference, use tags to distinguish entities). Your question made me think about the optimal approach = faction component with hostility rules. Honestly, simple works fine for traditional roguelikes, but factions would be better for complex multi-faction games. I might refactor to factions now just because it's architecturally cleaner!

