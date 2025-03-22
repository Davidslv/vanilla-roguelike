module Vanilla
  # Factory for creating game entities
  class EntityFactory
    # Create a player entity
    # @param world [World] The world to add the entity to
    # @param row [Integer] The row position
    # @param column [Integer] The column position
    # @param name [String] The player's name
    # @return [Components::Entity] The created player entity
    def self.create_player(world, row, column, name)
      # Validate parameters
      if !world || row.nil? || column.nil?
        Vanilla::Logger.instance.error("Invalid parameters for create_player: world=#{world}, row=#{row}, column=#{column}")
        return nil
      end

      entity = Components::Entity.new
      entity.name = name || "Player"

      # Add required components
      entity.add_component(Components::PositionComponent.new(row: row, column: column))
      entity.add_component(Components::MovementComponent.new)
      entity.add_component(Components::RenderComponent.new(
        character: Vanilla::Support::TileType::PLAYER,
        color: :cyan,
        layer: 10
      ))
      entity.add_component(Components::StairsComponent.new(found_stairs: false))

      # Add identity tags
      entity.add_tag(:player)

      # Add to world and verify
      world.add_entity(entity)

      # Log creation
      Vanilla::Logger.instance.info("Player entity created and added to world: #{entity.id}")

      entity
    end

    # Create a monster entity
    # @param world [World] The world to add the entity to
    # @param row [Integer] The row position
    # @param column [Integer] The column position
    # @param type [Symbol] The monster type
    # @return [Components::Entity] The created monster entity
    def self.create_monster(world, row, column, type = :orc)
      # Validate parameters
      if !world || row.nil? || column.nil?
        Vanilla::Logger.instance.error("Invalid parameters for create_monster: world=#{world}, row=#{row}, column=#{column}")
        return nil
      end

      entity = Components::Entity.new

      # Add required components
      entity.add_component(Components::PositionComponent.new(row: row, column: column))
      entity.add_component(Components::MovementComponent.new)

      # Configure monster type-specific properties
      case type
      when :orc
        entity.name = "Orc"
        entity.add_component(Components::RenderComponent.new(
          character: Vanilla::Support::TileType::MONSTER,
          color: :green,
          layer: 5
        ))
        health = 10 + rand(10)
        damage = 2 + rand(3)
      when :troll
        entity.name = "Troll"
        entity.add_component(Components::RenderComponent.new(
          character: Vanilla::Support::TileType::MONSTER,
          color: :red,
          layer: 5
        ))
        health = 20 + rand(15)
        damage = 4 + rand(5)
      else
        entity.name = "Unknown Monster"
        entity.add_component(Components::RenderComponent.new(
          character: Vanilla::Support::TileType::MONSTER,
          color: :magenta,
          layer: 5
        ))
        health = 5 + rand(5)
        damage = 1 + rand(2)
      end

      # Add identity tags
      entity.add_tag(:monster)
      entity.add_tag(type)

      # Add to world and verify
      world.add_entity(entity)

      # Log creation
      Vanilla::Logger.instance.info("Monster (#{type}) created and added to world: #{entity.id}")

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
    # @param up [Boolean] Whether the stairs go up or down
    # @return [Components::Entity] The created stairs entity
    def self.create_stairs(world, row, column, up = false)
      # Validate parameters
      if !world || row.nil? || column.nil?
        Vanilla::Logger.instance.error("Invalid parameters for create_stairs: world=#{world}, row=#{row}, column=#{column}")
        return nil
      end

      entity = Components::Entity.new
      entity.add_component(Components::PositionComponent.new(row: row, column: column))

      if up
        # Use a valid character from TileType for stairs up
        entity.add_component(Components::RenderComponent.new(
          character: Support::TileType::STAIRS,
          color: :cyan
        ))
        entity.add_component(Components::StairsComponent.new(found_stairs: false))
        entity.name = "Stairs Up"
      else
        # Use a valid character from TileType for stairs down
        entity.add_component(Components::RenderComponent.new(
          character: Support::TileType::STAIRS,
          color: :magenta
        ))
        entity.add_component(Components::StairsComponent.new(found_stairs: false))
        entity.name = "Stairs Down"
      end

      entity.add_tag(:stairs)

      # Add to world and verify
      world.add_entity(entity)

      # Log creation
      Vanilla::Logger.instance.info("Stairs entity created and added to world: #{entity.id}")

      entity
    end
  end
end