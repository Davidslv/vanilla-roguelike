require_relative 'components'

module Vanilla
  # Factory functions to create entities instead of using inheritance
  module EntityFactory
    # Create a player entity
    # @param world [Object] The world this entity belongs to
    # @param row [Integer] Starting row position
    # @param column [Integer] Starting column position
    # @param name [String] Player's name
    # @return [Vanilla::Components::Entity] The created player entity
    def self.create_player(world, row, column, name = "Hero")
      entity = Components::Entity.new

      # Add basic components
      entity.add_component(Components::PositionComponent.new(row: row, column: column))
      entity.add_component(Components::MovementComponent.new)
      entity.add_component(Components::RenderComponent.new(
        character: Support::TileType::PLAYER,
        entity_type: 'player',
        layer: 10 # Player is drawn on top
      ))
      entity.add_component(Components::StairsComponent.new)
      entity.add_component(Components::InputComponent.new)

      # Add tag to identify as player
      add_tag(entity, :player)

      # Store name in entity data
      add_data(entity, :name, name)

      # Add entity to world
      world.add_entity(entity) if world.respond_to?(:add_entity)

      entity
    end

    # Create a monster entity
    # @param world [Object] The world this entity belongs to
    # @param row [Integer] Starting row position
    # @param column [Integer] Starting column position
    # @param monster_type [String] Type of monster
    # @param health [Integer] Monster's health points
    # @param damage [Integer] Monster's attack damage
    # @return [Vanilla::Components::Entity] The created monster entity
    def self.create_monster(world, row, column, monster_type = "goblin", health = 10, damage = 2)
      entity = Components::Entity.new

      # Add basic components
      entity.add_component(Components::PositionComponent.new(row: row, column: column))
      entity.add_component(Components::MovementComponent.new)
      entity.add_component(Components::RenderComponent.new(
        character: Support::TileType::MONSTER,
        entity_type: monster_type,
        layer: 5 # Monsters below player
      ))

      # Add combat-related data (will be refactored to proper components in future)
      add_data(entity, :health, health)
      add_data(entity, :damage, damage)
      add_data(entity, :monster_type, monster_type)

      # Add tag to identify as monster
      add_tag(entity, :monster)

      # Add entity to world
      world.add_entity(entity) if world.respond_to?(:add_entity)

      entity
    end

    # Create a stairs entity
    # @param world [Object] The world this entity belongs to
    # @param row [Integer] Row position
    # @param column [Integer] Column position
    # @return [Vanilla::Components::Entity] The created stairs entity
    def self.create_stairs(world, row, column)
      entity = Components::Entity.new

      # Add basic components
      entity.add_component(Components::PositionComponent.new(row: row, column: column))
      entity.add_component(Components::RenderComponent.new(
        character: Support::TileType::STAIRS,
        entity_type: 'stairs',
        layer: 2 # Above floor, below monsters
      ))

      # Add tag to identify as stairs
      add_tag(entity, :stairs)

      # Add entity to world
      world.add_entity(entity) if world.respond_to?(:add_entity)

      entity
    end

    # Helper method to add a tag to an entity
    # @param entity [Vanilla::Components::Entity] The entity to tag
    # @param tag [Symbol] The tag to add
    # @return [Boolean] Whether the tag was added
    def self.add_tag(entity, tag)
      # For now, we'll implement tags as a simple data attribute
      data = entity.instance_variable_get(:@data) || {}
      tags = data[:tags] || []

      unless tags.include?(tag)
        tags << tag
        data[:tags] = tags
        entity.instance_variable_set(:@data, data)
        return true
      end

      false
    end

    # Helper method to check if an entity has a tag
    # @param entity [Vanilla::Components::Entity] The entity to check
    # @param tag [Symbol] The tag to check for
    # @return [Boolean] Whether the entity has the tag
    def self.has_tag?(entity, tag)
      data = entity.instance_variable_get(:@data) || {}
      tags = data[:tags] || []
      tags.include?(tag)
    end

    # Helper method to add arbitrary data to an entity
    # @param entity [Vanilla::Components::Entity] The entity to add data to
    # @param key [Symbol] The data key
    # @param value [Object] The data value
    # @return [Object] The value that was set
    def self.add_data(entity, key, value)
      data = entity.instance_variable_get(:@data) || {}
      data[key] = value
      entity.instance_variable_set(:@data, data)
      value
    end

    # Helper method to get arbitrary data from an entity
    # @param entity [Vanilla::Components::Entity] The entity to get data from
    # @param key [Symbol] The data key
    # @return [Object, nil] The data value or nil if not found
    def self.get_data(entity, key)
      data = entity.instance_variable_get(:@data) || {}
      data[key]
    end
  end
end