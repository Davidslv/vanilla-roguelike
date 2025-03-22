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

      # @return [Boolean] Whether movement is active
      attr_accessor :active

      # @return [Symbol, nil] The current movement direction (if any)
      attr_accessor :direction

      # Initialize a new movement component
      # @param speed [Float] Movement speed multiplier
      # @param can_move_directions [Array<Symbol>] Directions this entity can move in
      # @param active [Boolean] Whether movement is active
      def initialize(speed = 1, can_move_directions = [:north, :south, :east, :west], active = true)
        @speed = speed
        @can_move_directions = can_move_directions
        @active = active
        @direction = nil
        super()
      end

      # @return [Symbol] the component type
      def type
        :movement
      end

      # Check if movement is active
      # @return [Boolean] Whether movement is enabled
      def active?
        @active
      end

      # Enable or disable movement
      # @param value [Boolean] Whether movement should be enabled
      def set_active(value)
        @active = value
      end

      # Set the movement direction
      # @param direction [Symbol] The direction to move
      def set_direction(direction)
        @direction = direction
      end

      # @return [Hash] serialized component data
      def data
        {
          speed: @speed,
          can_move_directions: @can_move_directions,
          active: @active,
          direction: @direction
        }
      end

      # Create a movement component from a hash
      # @param hash [Hash] serialized component data
      # @return [MovementComponent] deserialized component
      def self.from_hash(hash)
        component = new(
          hash[:speed] || 1,
          hash[:can_move_directions] || [:north, :south, :east, :west],
          hash[:active].nil? ? true : hash[:active]
        )
        component.direction = hash[:direction]
        component
      end
    end

    # Register component
    Component.register(MovementComponent)
  end
end