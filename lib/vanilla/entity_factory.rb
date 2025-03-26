# frozen_string_literal: true

module Vanilla
  class EntityFactory
    def self.create_player(row, column)
      player = Vanilla::Entities::Entity.new

      player.name = "Player"
      player.add_tag(:player)
      player.add_component(Vanilla::Components::PositionComponent.new(row: row, column: column))
      player.add_component(Vanilla::Components::RenderComponent.new(character: Vanilla::Support::TileType::PLAYER, color: :white))
      player.add_component(Vanilla::Components::InputComponent.new)
      player.add_component(Vanilla::Components::MovementComponent.new(active: true))
      player
    end

    def self.create_stairs(row, column)
      stairs = Vanilla::Entities::Entity.new
      stairs.name = "Stairs"
      stairs.add_tag(:stairs)
      stairs.add_component(Vanilla::Components::PositionComponent.new(row: row, column: column))
      stairs.add_component(Vanilla::Components::RenderComponent.new(character: Vanilla::Support::TileType::STAIRS, color: :white))
      stairs
    end

    def self.create_monster(type, row, column, health, damage)
      monster = Vanilla::Entities::Entity.new
      monster.name = type.capitalize
      monster.add_tag(:monster)
      monster.add_component(Vanilla::Components::PositionComponent.new(row: row, column: column))
      monster.add_component(Vanilla::Components::RenderComponent.new(character: Vanilla::Support::TileType::MONSTER, color: :white))
      # Placeholder for health/damage; add HealthComponent later if needed
      monster.instance_variable_set(:@health, health)
      monster.instance_variable_set(:@damage, damage)
      monster.define_singleton_method(:alive?) { @health > 0 }
      monster
    end
  end
end
