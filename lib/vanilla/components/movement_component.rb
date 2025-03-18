module Vanilla
  module Components
    # MovementComponent represents an entity's ability to move within the game world.
    #
    # This component is a pure data container that follows the ECS pattern by only
    # storing movement-related state without containing movement logic. The actual
    # movement calculations and grid interactions are handled by the MovementSystem.
    #
    # == Attributes
    # * +speed+ - How fast the entity moves (used for animation or time-based movement)
    # * +can_move_directions+ - Which directions the entity is allowed to move in
    #
    # == Usage
    #   entity = Entity.new
    #   movement = MovementComponent.new(speed: 2)
    #   entity.add_component(movement)
    #
    #   # The entity can now be processed by the MovementSystem
    #   movement_system.move(entity, :north)
    class MovementComponent < Component
      # @return [Float] Movement speed factor
      attr_accessor :speed

      # @return [Array<Symbol>] Directions this entity can move in (:north, :south, :east, :west)
      attr_accessor :can_move_directions

      # Initialize a new movement component
      # @param speed [Float] Movement speed multiplier
      # @param can_move_directions [Array<Symbol>] Directions this entity can move in
      def initialize(speed: 1, can_move_directions: [:north, :south, :east, :west])
        @speed = speed
        @can_move_directions = can_move_directions
        super()
      end

      # @return [Symbol] the component type
      def type
        :movement
      end

      # @return [Hash] serialized component data
      def data
        {
          speed: @speed,
          can_move_directions: @can_move_directions
        }
      end

      # Create a movement component from a hash
      # @param hash [Hash] serialized component data
      # @return [MovementComponent] deserialized component
      def self.from_hash(hash)
        new(
          speed: hash[:speed] || 1,
          can_move_directions: hash[:can_move_directions] || [:north, :south, :east, :west]
        )
      end
    end

    # Register this component type
    Component.register(MovementComponent)
  end
end