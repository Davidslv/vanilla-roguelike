require_relative '../components'

module Vanilla
  module Entities
    # The Player entity represents the player character in the game.
    #
    # This entity uses the ECS architecture by combining various components:
    # * PositionComponent - For tracking position in the grid
    # * MovementComponent - For movement capabilities
    # * TileComponent - For visual representation
    # * StairsComponent - For tracking stairs discovery
    # * RenderComponent - For visual rendering in the new system
    #
    # The entity maintains backward compatibility with the old Unit-based system
    # by delegating methods to the appropriate components.
    class Player < Components::Entity
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
        add_component(Components::TileComponent.new(tile: Support::TileType::PLAYER))
        add_component(Components::StairsComponent.new)

        # Add new RenderComponent
        add_component(Components::RenderComponent.new(
          character: Support::TileType::PLAYER,
          layer: 10  # Player is usually drawn on top
        ))
      end

      # Gain experience points
      # @param amount [Integer] the amount of experience to gain
      def gain_experience(amount)
        @experience += amount
        check_for_level_ups
      end

      # Level up the player
      def level_up
        xp_needed = experience_to_next_level
        @level += 1
        @experience -= xp_needed
        # Add level up bonuses here
      end

      # Add an item to the player's inventory
      # @param item [Object] the item to add
      def add_to_inventory(item)
        @inventory << item
      end

      # Remove an item from the player's inventory
      # @param item [Object] the item to remove
      def remove_from_inventory(item)
        @inventory.delete(item)
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

      def found_stairs?
        stairs_component = get_component(:stairs)
        stairs_component&.found_stairs? || false
      end

      # Create a player entity from a hash representation
      # @param hash [Hash] serialized player data
      # @return [Player] the deserialized player entity
      def self.from_hash(hash)
        # First, extract position information from components to initialize the player
        position = extract_position_from_components(hash[:components])

        # Create a new player with the position information
        player = new(
          name: hash[:name],
          row: position[:row],
          column: position[:column]
        )

        # Set entity ID to match original
        player.instance_variable_set(:@id, hash[:id])

        # Update player attributes
        player.level = hash[:level]
        player.experience = hash[:experience]
        player.inventory = hash[:inventory]

        player
      end

      private

      # Extract position information from serialized components
      # @param components [Array<Hash>] serialized components
      # @return [Hash] position information with :row and :column keys
      def self.extract_position_from_components(components)
        position_component = components.find { |c| c[:type] == :position }

        if position_component
          { row: position_component[:data][:row], column: position_component[:data][:column] }
        else
          { row: 0, column: 0 } # Default if not found
        end
      end

      # Check if the player should level up based on current experience
      def check_for_level_ups
        while @experience >= experience_to_next_level
          next_level_xp = experience_to_next_level
          @level += 1
          @experience -= next_level_xp
        end
      end

      # Calculate experience needed for next level
      # @return [Integer] experience points needed for next level
      def experience_to_next_level
        @level * 100 # Simple formula, can be adjusted
      end
    end
  end
end