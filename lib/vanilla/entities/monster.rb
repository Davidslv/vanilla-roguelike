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
    class Monster < Entities::Entity
      # @return [String] the monster's type
      attr_accessor :monster_type

      # Initialize a new monster entity
      # @param monster_type [String] the type of monster
      # @param row [Integer] the starting row position
      # @param column [Integer] the starting column position
      def initialize(monster_type: 'goblin', row:, column:, health: 10)
        super()

        @monster_type = monster_type

        # Add required components
        add_component(Components::PositionComponent.new(row: row, column: column))
        add_component(Components::MovementComponent.new)

        # Add RenderComponent for visual representation
        add_component(Components::RenderComponent.new(
                        character: Support::TileType::MONSTER,
                        entity_type: @monster_type,
                        layer: 5 # Monsters are below player
                      ))

        add_component(Components::HealthComponent.new(max_health: health))
      end

      # Convert the monster entity to a hash representation
      # @return [Hash] serialized monster data
      def to_hash
        health = get_component(:health).current_health

        super.merge(
          monster_type: @monster_type,
          health: health
        )
      end

      # Create a monster entity from a hash representation
      # @param hash [Hash] serialized monster data
      # @return [Monster] the deserialized monster entity
      def self.from_hash(hash)
        # Create a new monster with the position information
        new(
          monster_type: hash[:monster_type],
          row: hash[:row],
          column: hash[:column],
          health: hash[:health]
        )
      end
    end
  end
end
