# frozen_string_literal: true

require_relative '../components'

module Vanilla
  module Entities
    # The Monster entity represents an enemy in the game.
    #
    # This entity uses the ECS architecture by combining various components:
    # * PositionComponent - For tracking position in the grid
    # * MovementComponent - For movement capabilities
    # * RenderComponent - For visual representation and rendering
    #
    # Monsters can move around the map and interact with the player.
    class Monster < Components::Entity
      # @return [String] the monster's type
      attr_accessor :monster_type

      # @return [Integer] the monster's health points
      attr_accessor :health

      # @return [Integer] the damage the monster inflicts
      attr_accessor :damage

      # Initialize a new monster entity
      # @param monster_type [String] the type of monster
      # @param row [Integer] the starting row position
      # @param column [Integer] the starting column position
      # @param health [Integer] the monster's health points
      # @param damage [Integer] the damage the monster inflicts
      def initialize(monster_type: 'goblin', row:, column:, health: 10, damage: 2)
        super()

        @monster_type = monster_type
        @health = health
        @damage = damage

        # Add required components
        add_component(Components::PositionComponent.new(row: row, column: column))
        add_component(Components::MovementComponent.new)

        # Add RenderComponent for visual representation
        add_component(Components::RenderComponent.new(
                        character: Support::TileType::MONSTER,
                        entity_type: @monster_type,
                        layer: 5 # Monsters are below player
        ))
      end

      # Check if the monster is alive
      # @return [Boolean] true if the monster is alive, false otherwise
      def alive?
        @health > 0
      end

      # Take damage from an attack
      # @param amount [Integer] the amount of damage to take
      # @return [Integer] the remaining health
      def take_damage(amount)
        @health -= amount
        @health = 0 if @health < 0
        @health
      end

      # Attack a target entity
      # @param target [Entity] the entity to attack
      # @return [Integer] the amount of damage dealt
      def attack(target)
        if target.respond_to?(:take_damage)
          target.take_damage(@damage)
          @damage
        else
          0
        end
      end

      # Convert the monster entity to a hash representation
      # @return [Hash] serialized monster data
      def to_hash
        super.merge(
          monster_type: @monster_type,
          health: @health,
          damage: @damage
        )
      end

      # Create a monster entity from a hash representation
      # @param hash [Hash] serialized monster data
      # @return [Monster] the deserialized monster entity
      def self.from_hash(hash)
        # First, extract position information from components to initialize the monster
        position = extract_position_from_components(hash[:components])

        # Create a new monster with the position information
        monster = new(
          monster_type: hash[:monster_type],
          row: position[:row],
          column: position[:column],
          health: hash[:health],
          damage: hash[:damage]
        )

        # Set entity ID to match original
        monster.instance_variable_set(:@id, hash[:id])

        monster
      end

      # For backward compatibility - get the tile character
      def tile
        render_component = get_component(:render)
        render_component&.character || Support::TileType::MONSTER
      end

      private

      # Extract position information from serialized components
      # @param components [Array<Hash>] serialized components
      # @return [Hash] position information with :row and :column keys
      def self.extract_position_from_components(components)
        position_component = components.find { |c| c[:type] == :position }

        if position_component && position_component[:data]
          { row: position_component[:data][:row], column: position_component[:data][:column] }
        else
          { row: 0, column: 0 } # Default if not found
        end
      end
    end
  end
end
