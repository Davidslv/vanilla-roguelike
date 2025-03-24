# frozen_string_literal: true

require_relative '../components'

module Vanilla
  module Entities
    # The Stairs entity represents a staircase to the next level.
    #
    # This entity uses the ECS architecture by combining:
    # * PositionComponent - For tracking position in the grid
    # * RenderComponent - For visual rendering in the system
    class Stairs < Components::Entity
      # Initialize a new stairs entity
      # @param row [Integer] the row position
      # @param column [Integer] the column position
      def initialize(row:, column:)
        super()

        # Add required components
        add_component(Components::PositionComponent.new(row: row, column: column))

        # Add RenderComponent
        add_component(Components::RenderComponent.new(
                        character: Support::TileType::STAIRS,
                        layer: 2 # Above floor, below monsters
                      ))
      end
    end
  end
end
