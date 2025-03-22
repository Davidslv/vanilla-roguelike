module Vanilla
  module Components
    # Component for storing input state for an entity
    #
    # This component is a pure data container that stores the current input state
    # for an entity, including movement direction and action triggers.
    class InputComponent < Component
      # @return [Symbol, nil] The movement direction (:north, :south, :east, :west, nil)
      attr_reader :move_direction

      # @return [Boolean] Whether an action was triggered
      attr_reader :action_triggered

      # @return [Symbol, nil] The type of action triggered
      attr_reader :action_type

      # Initialize a new input component
      def initialize
        super()
        @move_direction = nil
        @action_triggered = false
        @action_type = nil
      end

      # @return [Symbol] The component type
      def type
        :input
      end

      # Set the movement direction
      # @param direction [Symbol, nil] The movement direction
      def move_direction=(direction)
        @move_direction = direction
      end

      # Set the action triggered flag
      # @param triggered [Boolean] Whether an action was triggered
      def action_triggered=(triggered)
        @action_triggered = triggered
      end

      # Set the action type
      # @param type [Symbol, nil] The type of action triggered
      def action_type=(type)
        @action_type = type
      end

      # Clear all input, typically done after processing
      def clear
        @move_direction = nil
        @action_triggered = false
        @action_type = nil
      end

      # Get additional data for serialization
      # @return [Hash] additional data to include in serialization
      def data
        {
          move_direction: @move_direction,
          action_triggered: @action_triggered,
          action_type: @action_type
        }
      end

      # Create from hash for deserialization
      # @param hash [Hash] The hash data to create from
      # @return [InputComponent] The created component
      def self.from_hash(hash)
        component = new
        component.move_direction = hash[:move_direction]
        component.action_triggered = hash[:action_triggered] || false
        component.action_type = hash[:action_type]
        component
      end
    end

    # Register this component
    Component.register(InputComponent)
  end
end