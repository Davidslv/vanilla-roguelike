module Vanilla
  # Factory for creating game entities
  module EntityFactory
    # Create a player entity
    # @param world [World] The world to add the entity to
    # @param row [Integer] The starting row position
    # @param column [Integer] The starting column position
    # @param name [String] The player's name
    # @return [Entity] The created player entity
    def self.create_player(world, row, column, name = "Hero")
      entity = Components::Entity.new
      entity.add_component(Components::PositionComponent.new(row: row, column: column))
      entity.add_component(Components::RenderComponent.new(character: '@', color: :white))
      entity.add_component(Components::InputComponent.new)
      entity.add_component(Components::InventoryComponent.new)
      entity.add_component(Components::MovementComponent.new(1))
      entity.add_tag(:player)
      entity.name = name

      world.add_entity(entity)
      entity
    end

    # Create a monster entity
    # @param world [World] The world to add the entity to
    # @param row [Integer] The starting row position
    # @param column [Integer] The starting column position
    # @param type [Symbol] The monster type (:goblin, :troll, etc.)
    # @return [Entity] The created monster entity
    def self.create_monster(world, row, column, type = :goblin)
      entity = Components::Entity.new
      entity.add_component(Components::PositionComponent.new(row: row, column: column))

      # Configure based on monster type
      case type
      when :goblin
        entity.add_component(Components::RenderComponent.new(character: 'M', color: :green))
        entity.add_component(Components::MovementComponent.new(1))
        entity.name = "Goblin"
      when :troll
        entity.add_component(Components::RenderComponent.new(character: 'M', color: :red))
        entity.add_component(Components::MovementComponent.new(0.5))
        entity.name = "Troll"
      else
        entity.add_component(Components::RenderComponent.new(character: 'M', color: :yellow))
        entity.add_component(Components::MovementComponent.new(1))
        entity.name = "Unknown Monster"
      end

      entity.add_tag(:monster)
      entity.add_tag(type)

      world.add_entity(entity)
      entity
    end

    # Create an item entity
    # @param world [World] The world to add the entity to
    # @param row [Integer] The starting row position
    # @param column [Integer] The starting column position
    # @param item_type [Symbol] The item type (:potion, :weapon, etc.)
    # @return [Entity] The created item entity
    def self.create_item(world, row, column, item_type = :potion)
      entity = Components::Entity.new
      entity.add_component(Components::PositionComponent.new(row: row, column: column))

      # Configure based on item type
      case item_type
      when :potion
        entity.add_component(Components::RenderComponent.new(character: '!', color: :red))
        entity.add_component(Components::ItemComponent.new("Health Potion", :potion))
        entity.add_component(Components::ConsumableComponent.new)
        entity.name = "Health Potion"
      when :sword
        entity.add_component(Components::RenderComponent.new(character: '/', color: :cyan))
        entity.add_component(Components::ItemComponent.new("Steel Sword", :weapon))
        entity.add_component(Components::EquippableComponent.new(:weapon))
        entity.name = "Steel Sword"
      when :key
        entity.add_component(Components::RenderComponent.new(character: 'k', color: :yellow))
        entity.add_component(Components::ItemComponent.new("Key", :key))
        entity.add_component(Components::KeyComponent.new)
        entity.name = "Key"
      else
        entity.add_component(Components::RenderComponent.new(character: '?', color: :white))
        entity.add_component(Components::ItemComponent.new("Unknown Item", :misc))
        entity.name = "Unknown Item"
      end

      entity.add_tag(:item)
      entity.add_tag(item_type)

      world.add_entity(entity)
      entity
    end

    # Create a stairs entity
    # @param world [World] The world to add the entity to
    # @param row [Integer] The row position
    # @param column [Integer] The column position
    # @param up [Boolean] Whether these are stairs going up [DEPRECATED]
    # @return [Entity] The created stairs entity
    def self.create_stairs(world, row, column, up = false)
      entity = Components::Entity.new
      entity.add_component(Components::PositionComponent.new(row: row, column: column))

      entity.add_component(Components::RenderComponent.new(character: '%', color: :magenta))
      entity.add_component(Components::StairsComponent.new(found_stairs: false))
      entity.name = "Stairs"

      entity.add_tag(:stairs)

      world.add_entity(entity)
      entity
    end
  end
end
