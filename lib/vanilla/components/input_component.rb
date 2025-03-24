# frozen_string_literal: true

require_relative 'component'

module Vanilla
  module Components
    # Component for storing input state
    # This component stores pending input actions for an entity
    class InputComponent < Component
      attr_accessor :move_direction

      # Initialize a new input component
      def initialize
        super()
        @move_direction = nil
      end

      # Get the component type
      # @return [Symbol] The component type
      def type
        :input
      end

      # TODO: remove this method for pure ECS
      # Set the movement direction
      # @param direction [Symbol] The direction to move (:north, :south, :east, :west)
      # def set_move_direction(direction)
      #   @move_direction = direction
      # end

      # Convert to hash for serialization
      # @return [Hash] Serialized representation
      def to_hash
        {
          move_direction: @move_direction
        }
      end

      # Create from hash for deserialization
      # @param hash [Hash] Serialized representation
      # @return [InputComponent] The new component
      def self.from_hash(hash)
        component = new
        component.move_direction = hash[:move_direction]
        component
      end

      # Get the component type
      # @return [Symbol] The component type
      def self.component_type
        :input
      end
    end

    # Register this component
    Component.register(InputComponent)
  end
end
