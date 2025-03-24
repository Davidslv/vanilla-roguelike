# frozen_string_literal: true
require_relative 'component'

module Vanilla
  module Components
    # Component for storing input state
    # This component stores pending input actions for an entity
    class InputComponent < Component
      attr_reader :move_direction, :action_triggered

      # Initialize a new input component
      def initialize
        @move_direction = nil
        @action_triggered = false
        @action_params = {}
        super()
      end

      # Get the component type
      # @return [Symbol] The component type
      def type
        :input
      end

      # Set the movement direction
      # @param direction [Symbol] The direction to move (:north, :south, :east, :west)
      def set_move_direction(direction)
        @move_direction = direction
      end

      # Set the action trigger
      # @param triggered [Boolean] Whether an action was triggered
      # @param params [Hash] Optional parameters for the action
      def set_action_triggered(triggered, params = {})
        @action_triggered = triggered
        @action_params = params if triggered
      end

      # Get the action parameters
      # @return [Hash] The action parameters
      def action_params
        @action_params
      end

      # Clear all input
      def clear
        @move_direction = nil
        @action_triggered = false
        @action_params = {}
      end

      # Convert to hash for serialization
      # @return [Hash] Serialized representation
      def data
        {
          move_direction: @move_direction,
          action_triggered: @action_triggered,
          action_params: @action_params
        }
      end

      # Create from hash for deserialization
      # @param hash [Hash] Serialized representation
      # @return [InputComponent] The new component
      def self.from_hash(hash)
        component = new
        component.set_move_direction(hash[:move_direction])
        component.set_action_triggered(hash[:action_triggered], hash[:action_params] || {})
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
