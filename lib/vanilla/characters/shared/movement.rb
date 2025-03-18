module Vanilla
  module Characters
    module Shared
      # @deprecated Use Vanilla::Systems::MovementSystem with appropriate components instead
      module Movement
        # @deprecated Use Vanilla::Systems::MovementSystem#move instead
        def move(direction)
          logger = Vanilla::Logger.instance
          logger.warn("DEPRECATED: #{self.class}##{__method__} is deprecated. Please use Vanilla::Systems::MovementSystem.")

          case direction
          when :left
            move_left
          when :right
            move_right
          when :up
            move_up
          when :down
            move_down
          end
        end

        # @deprecated Use Vanilla::Systems::MovementSystem#move with :west direction
        def move_left
          logger = Vanilla::Logger.instance
          logger.warn("DEPRECATED: #{self.class}##{__method__} is deprecated. Please use Vanilla::Systems::MovementSystem.")

          return unless can_move?(:west)

          self.found_stairs = stairs?(:west)
          update_position(:west)
        end

        # @deprecated Use Vanilla::Systems::MovementSystem#move with :east direction
        def move_right
          logger = Vanilla::Logger.instance
          logger.warn("DEPRECATED: #{self.class}##{__method__} is deprecated. Please use Vanilla::Systems::MovementSystem.")

          return unless can_move?(:east)

          self.found_stairs = stairs?(:east)
          update_position(:east)
        end

        # @deprecated Use Vanilla::Systems::MovementSystem#move with :north direction
        def move_up
          logger = Vanilla::Logger.instance
          logger.warn("DEPRECATED: #{self.class}##{__method__} is deprecated. Please use Vanilla::Systems::MovementSystem.")

          return unless can_move?(:north)

          self.found_stairs = stairs?(:north)
          update_position(:north)
        end

        # @deprecated Use Vanilla::Systems::MovementSystem#move with :south direction
        def move_down
          logger = Vanilla::Logger.instance
          logger.warn("DEPRECATED: #{self.class}##{__method__} is deprecated. Please use Vanilla::Systems::MovementSystem.")

          return unless can_move?(:south)

          self.found_stairs = stairs?(:south)
          update_position(:south)
        end

        private

        def can_move?(direction)
          # This method should be implemented in the including class
          # to check if the move is possible based on the game's rules
          raise NotImplementedError, "#{self.class} must implement #can_move?"
        end

        def stairs?(direction)
          # This method should be implemented in the including class
          # to check if there are stairs in the given direction
          raise NotImplementedError, "#{self.class} must implement #stairs?"
        end

        def update_position(direction)
          case direction
          when :west
            self.column -= 1
          when :east
            self.column += 1
          when :north
            self.row -= 1
          when :south
            self.row += 1
          end
        end
      end
    end
  end
end
