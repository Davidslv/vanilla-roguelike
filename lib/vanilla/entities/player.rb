# frozen_string_literal: true

require_relative '../components'

module Vanilla
  module Entities
    # The Player entity represents the player character in the game.
    #
    # This entity uses the ECS architecture by combining various components:
    # * PositionComponent - For tracking position in the grid
    # * MovementComponent - For movement capabilities
    # * StairsComponent - For tracking stairs discovery
    # * RenderComponent - For visual representation and rendering
    #
    # The entity maintains backward compatibility with the old Unit-based system
    # by delegating methods to the appropriate components.
    class Player < Entities::Entity
      # @return [String] the player's name
      attr_accessor :name

      # @return [Integer] the player's current level
      attr_accessor :level

      # @return [Integer] the player's current experience points
      attr_accessor :experience

      # @return [Array] the player's inventory
      attr_accessor :inventory

      # Initialize a new player entity
      # @param name [String] the player's name
      # @param row [Integer] the starting row position
      # @param column [Integer] the starting column position
      def initialize(name: 'player', row:, column:)
        super()

        @name = name
        @level = 1
        @experience = 0
        @inventory = []

        # Add required components
        add_component(Components::PositionComponent.new(row: row, column: column))
        add_component(Components::MovementComponent.new)
        add_component(Components::StairsComponent.new)
        add_component(Components::RenderComponent.new(
                        character: Support::TileType::PLAYER,
                        entity_type: Support::TileType::PLAYER,
                        layer: 10 # Player is usually drawn on top
                      ))
      end

      # Convert the player entity to a hash representation
      # @return [Hash] serialized player data
      def to_hash
        super.merge(
          name: @name,
          level: @level,
          experience: @experience,
          inventory: @inventory
        )
      end

      # Create a player entity from a hash representation
      # @param hash [Hash] serialized player data
      # @return [Player] the deserialized player entity
      def self.from_hash(hash)
        # First, extract position information from components to initialize the player
        position = extract_position_from_components(hash[:components])

        # Create a new player with the position information
        new(
          name: hash[:name],
          row: position[:row],
          column: position[:column]
        )
      end
    end
  end
end
