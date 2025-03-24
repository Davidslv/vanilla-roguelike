# frozen_string_literal: true
module Vanilla
  module Components
    # Base class for all components
    class Component
      # Registry of component types to their implementation classes
      @component_classes = {}

      class << self
        # Get all registered component classes
        # @return [Hash] component type symbols => component classes
        attr_reader :component_classes

        # Register a component subclass
        # @param klass [Class] the component subclass
        def register(klass)
          instance = klass.new rescue return
          type = instance.type rescue return
          @component_classes[type] = klass
        end

        # Get a component class by type
        # @param type [Symbol] the component type
        # @return [Class, nil] the component class, or nil if not found
        def get_class(type)
          @component_classes[type]
        end

        # Create a component from a hash representation
        # @param hash [Hash] serialized component data
        # @return [Component] the deserialized component
        def from_hash(hash)
          type = hash[:type]
          raise ArgumentError, "Component hash must include a type" unless type

          klass = @component_classes[type]
          raise ArgumentError, "Unknown component type: #{type}" unless klass

          klass.from_hash(hash)
        end
      end

      # Initialize the component and check that type is implemented
      def initialize(*)
        type
      end

      # Required method that returns the component type
      # @return [Symbol] the component type
      def type
        raise NotImplementedError, "Component subclasses must implement #type"
      end

      # Convert component to a hash representation
      # @return [Hash] serialized component data
      def to_hash
        # Merge the component type with any data the component provides
        { type: type }.merge(data || {})
      end

      # Get additional data for serialization
      # @return [Hash] additional data to include in serialization
      def data
        {}
      end

      # Update the component
      # @param entity [Entity] the entity this component belongs to
      # @param delta_time [Float] time since last update in seconds
      def update(entity, delta_time)
        # Default implementation does nothing
      end
    end
  end
end
