# Reddit Response (Short Version): How Enemies Tell the Player Apart from Other Enemies

I'm working on a Ruby roguelike with an ECS architecture, and honestly, I haven't really thought deeply about this until I read your question. I just went with what felt natural at the time – but your question got me thinking, so I sat down and wrote it up.

## What I Actually Do

I went with the simple approach: direct player reference + entity tags.

My `MonsterSystem` just gets handed the player during initialization:
```ruby
def initialize(world, player:, logger: nil)
  @player = player
  # ...
end
```

Then I use entity tags (`:player`, `:monster`) throughout the combat and collision systems to figure out who's who.

Is it elegant? Not particularly. Does it work? Absolutely.

## What I Think Would Be Better

Now that I've thought it through – a proper faction system would be more flexible.

Instead of hardcoding 'find the player', entities would have a `FactionComponent`:
```ruby
player.add_component(FactionComponent.new(
  faction_id: :hero_faction,
  hostile_to: [:monster_faction, :undead_faction]
))
```

Monsters would just query for hostile entities based on faction rules, not specifically for "the player". Much cleaner architecturally – and more flexible if your game design evolves.

## The Trade-offs

**Simple approach** (what I use):
- Fast, easy to debug, works perfectly for traditional roguelikes
- But it's player-centric – if you want allied NPCs or monster infighting later, you'll need to refactor

**Faction system** (the optimal approach):
- Player-agnostic architecture, supports allies, infighting, and emergent gameplay naturally
- But it's more complex upfront and requires entity queries (with the performance considerations that come with that)

Honestly, for most traditional roguelikes, the simple approach is fine. Don't over-engineer if you don't need to.

## Full Analysis

Your question made me think through this properly, so I've written up a more in-depth analysis with real code examples:

**[Full Document: Enemy Targeting & Faction Systems](https://github.com/Davidslv/vanilla-roguelike/blob/main/documents/questions/reddit_response_enemy_targeting.md)**


Hope this helps! The examples are in Ruby, but the concepts should translate to whatever language you're using.

Feel free to ask if anything doesn't make sense – happy to clarify.