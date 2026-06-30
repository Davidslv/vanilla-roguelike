# frozen_string_literal: true

module Vanilla
  class EntityFactory
    # How far (in tiles) a monster can see when hunting. Line of sight is still
    # blocked by walls, so this is an upper bound, not a guaranteed range.
    MONSTER_VISION_RADIUS = 5

    def self.create_player(row, column, dev_mode: false)
      player = Vanilla::Entities::Entity.new

      player.name = "Player"
      player.add_tag(:player)
      player.add_component(Vanilla::Components::PositionComponent.new(row: row, column: column))
      player.add_component(Vanilla::Components::RenderComponent.new(character: Vanilla::Support::TileType::PLAYER, color: :white))
      player.add_component(Vanilla::Components::InputComponent.new)
      player.add_component(Vanilla::Components::MovementComponent.new(active: true))
      player.add_component(Vanilla::Components::HealthComponent.new(max_health: 100))
      player.add_component(Vanilla::Components::CombatComponent.new(attack_power: 10, defense: 2, accuracy: 0.8))
      player.add_component(Vanilla::Components::InventoryComponent.new(max_size: 20))
      player.add_component(Vanilla::Components::CurrencyComponent.new(0, :gold))
      player.add_component(Vanilla::Components::VisibilityComponent.new(vision_radius: 3))
      player.add_component(Vanilla::Components::FactionComponent.new(faction_id: Vanilla::Factions::HERO, hostile_to: [Vanilla::Factions::MONSTER]))

      # Add dev mode component if requested
      if dev_mode
        player.add_component(Vanilla::Components::DevModeComponent.new(fov_disabled: true))
      end

      player
    end

    def self.create_stairs(row, column)
      stairs = Vanilla::Entities::Entity.new
      stairs.name = "Stairs"
      stairs.add_tag(:stairs)

      stairs.add_component(Vanilla::Components::PositionComponent.new(row: row, column: column))
      stairs.add_component(Vanilla::Components::RenderComponent.new(character: Vanilla::Support::TileType::STAIRS, color: :white))
      stairs.add_component(Vanilla::Components::StairsComponent.new)

      stairs
    end

    def self.create_monster(type, row, column, health, damage)
      monster = Vanilla::Entities::Entity.new
      monster.name = type.capitalize
      monster.add_tag(:monster)
      monster.add_component(Vanilla::Components::PositionComponent.new(row: row, column: column))
      monster.add_component(Vanilla::Components::RenderComponent.new(character: Vanilla::Support::TileType::MONSTER, color: :white))
      monster.add_component(Vanilla::Components::HealthComponent.new(max_health: health))
      monster.add_component(Vanilla::Components::CombatComponent.new(attack_power: damage, defense: 1, accuracy: 0.7))
      monster.add_component(Vanilla::Components::FactionComponent.new(faction_id: Vanilla::Factions::MONSTER, hostile_to: [Vanilla::Factions::HERO]))
      # Movement lets MonsterAISystem drive the monster via MovementSystem#move;
      # visibility lets FOVSystem compute the monster's line of sight so it only
      # hunts targets it can actually see.
      monster.add_component(Vanilla::Components::MovementComponent.new(active: true))
      monster.add_component(Vanilla::Components::VisibilityComponent.new(vision_radius: MONSTER_VISION_RADIUS))
      monster
    end
  end
end
