module Vanilla
  module Characters
    # @deprecated Use Vanilla::Entities::Player instead
    class Player
      attr_accessor :name, :level, :experience, :inventory
      attr_reader :entity

      def initialize(name: 'player', row:, column:)
        logger = Vanilla::Logger.instance
        logger.warn("DEPRECATED: #{self.class} is deprecated. Please use Vanilla::Entities::Player instead.")

        # Create an entity with required components
        @entity = Vanilla::Components::Entity.new
        @entity.add_component(Vanilla::Components::PositionComponent.new(row: row, column: column))
        @entity.add_component(Vanilla::Components::TileComponent.new(tile: Support::TileType::PLAYER))
        @entity.add_component(Vanilla::Components::StairsComponent.new)

        @name = name
        @level = 1
        @experience = 0
        @inventory = []
      end

      # Delegate position-related methods to the position component
      def row
        @entity.get_component(:position).row
      end

      def row=(value)
        @entity.get_component(:position).row = value
      end

      def column
        @entity.get_component(:position).column
      end

      def column=(value)
        @entity.get_component(:position).column = value
      end

      def coordinates
        @entity.get_component(:position).coordinates
      end

      # Delegate tile-related methods to the tile component
      def tile
        @entity.get_component(:tile).tile
      end

      # Delegate stairs-related methods to the stairs component
      def found_stairs
        @entity.get_component(:stairs).found_stairs
      end

      def found_stairs=(value)
        @entity.get_component(:stairs).found_stairs = value
      end

      alias found_stairs? found_stairs

      # Movement methods are now handled by the MovementSystem
      # All movement methods are deprecated

      def move(direction)
        logger = Vanilla::Logger.instance
        logger.warn("DEPRECATED: #{self.class}##{__method__} is deprecated. Please use Vanilla::Entities::Player with Vanilla::Systems::MovementSystem.")
        # Legacy movement is no longer supported
        logger.info("Movement with #{direction} direction ignored - legacy movement is removed")
      end

      def move_left
        logger = Vanilla::Logger.instance
        logger.warn("DEPRECATED: #{self.class}##{__method__} is deprecated. Please use Vanilla::Entities::Player with Vanilla::Systems::MovementSystem.")
        # Legacy movement is no longer supported
        logger.info("Left movement ignored - legacy movement is removed")
      end

      def move_right
        logger = Vanilla::Logger.instance
        logger.warn("DEPRECATED: #{self.class}##{__method__} is deprecated. Please use Vanilla::Entities::Player with Vanilla::Systems::MovementSystem.")
        # Legacy movement is no longer supported
        logger.info("Right movement ignored - legacy movement is removed")
      end

      def move_up
        logger = Vanilla::Logger.instance
        logger.warn("DEPRECATED: #{self.class}##{__method__} is deprecated. Please use Vanilla::Entities::Player with Vanilla::Systems::MovementSystem.")
        # Legacy movement is no longer supported
        logger.info("Up movement ignored - legacy movement is removed")
      end

      def move_down
        logger = Vanilla::Logger.instance
        logger.warn("DEPRECATED: #{self.class}##{__method__} is deprecated. Please use Vanilla::Entities::Player with Vanilla::Systems::MovementSystem.")
        # Legacy movement is no longer supported
        logger.info("Down movement ignored - legacy movement is removed")
      end

      def gain_experience(amount)
        @experience += amount
        check_for_level_ups
      end

      def level_up
        xp_needed = experience_to_next_level
        @level += 1
        @experience -= xp_needed
        # Add level up bonuses here
      end

      def add_to_inventory(item)
        @inventory << item
      end

      def remove_from_inventory(item)
        @inventory.delete(item)
      end

      # Add method to convert to a proper Entity
      def to_entity
        entity = Vanilla::Entities::Player.new(
          name: @name,
          row: row,
          column: column
        )

        # Transfer state
        entity.level = @level
        entity.experience = @experience
        @inventory.each { |item| entity.add_to_inventory(item) }
        entity.found_stairs = found_stairs

        entity
      end

      private

      def check_for_level_ups
        while @experience >= experience_to_next_level
          next_level_xp = experience_to_next_level
          @level += 1
          @experience -= next_level_xp
        end
      end

      def experience_to_next_level
        @level * 100 # Simple formula, can be adjusted
      end
    end
  end
end