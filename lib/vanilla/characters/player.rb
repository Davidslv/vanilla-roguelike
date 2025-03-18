module Vanilla
  module Characters
    # @deprecated Use Vanilla::Entities::Player instead
    class Player < Unit
      attr_accessor :name, :level, :experience, :inventory

      def initialize(name: 'player', row:, column:)
        logger = Vanilla::Logger.instance
        logger.warn("DEPRECATED: #{self.class} is deprecated. Please use Vanilla::Entities::Player instead.")

        super(row: row, column: column, tile: Support::TileType::PLAYER)
        @name = name

        @level = 1
        @experience = 0
        @inventory = []
      end

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