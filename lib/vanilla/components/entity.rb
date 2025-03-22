require 'securerandom'

module Vanilla
  module Components
    # An entity is a container for components
    class Entity
      # @return [String] unique identifier for this entity
      attr_reader :id

      # @return [Array<Component>] all components attached to this entity
      attr_reader :components

      # Initialize a new entity
      # @param id [String, nil] optional ID for the entity, will be auto-generated if nil
      def initialize(id: nil)
        @id = id || SecureRandom.uuid
        @components = []
        @component_map = {}
      end

      # Add a component to the entity
      # @param component [Component] the component to add
      # @return [Entity] self, for method chaining
      def add_component(component)
        # Ensure the component has a type method
        unless component.respond_to?(:type)
          raise ArgumentError, "Component must respond to #type"
        end

        type = component.type

        # Check for duplicate component types
        if @component_map.key?(type)
          raise ArgumentError, "Entity already has a component of type #{type}"
        end

        @components << component
        @component_map[type] = component

        self
      end

      # Remove a component from the entity
      # @param type [Symbol] the type of component to remove
      # @return [Component, nil] the removed component, or nil if not found
      def remove_component(type)
        component = @component_map[type]
        return nil unless component

        @components.delete(component)
        @component_map.delete(type)

        component
      end

      # Check if the entity has a component of the given type
      # @param type [Symbol] the component type to check for
      # @return [Boolean] true if the entity has a component of this type
      def has_component?(type)
        @component_map.key?(type)
      end

      # Get a component by type
      # @param type [Symbol] the type of component to get
      # @return [Component, nil] the component, or nil if not found
      def get_component(type)
        @component_map[type]
      end

      # Update all components
      # @param delta_time [Float] time since last update in seconds
      def update(delta_time)
        @components.each do |component|
          component.update(self, delta_time) if component.respond_to?(:update)
        end
      end

      # Convert the entity to a hash representation
      # @return [Hash] serialized entity data
      def to_hash
        {
          id: @id,
          components: @components.map(&:to_hash)
        }
      end

      # Create an entity from a hash representation
      # @param hash [Hash] serialized entity data
      # @return [Entity] the deserialized entity
      def self.from_hash(hash)
        entity = new(id: hash[:id])

        hash[:components].each do |component_hash|
          component = Component.from_hash(component_hash)
          entity.add_component(component)
        end

        entity
      end

      # Handle method missing to delegate to components
      # @param method [Symbol] the method name
      # @param args [Array] arguments to the method
      # @param block [Proc] optional block
      def method_missing(method, *args, &block)
        # Log a warning about using method_missing
        Vanilla::Logger.instance.warn("Entity#method_missing called for #{method}. Consider accessing the component directly instead. Entity: #{id}")

        # Check if method is a setter (ends with =)
        if method.to_s.end_with?('=')
          attr_name = method.to_s.chomp('=').to_sym

          # Find a component that responds to this setter
          @components.each do |component|
            if component.respond_to?(method)
              return component.send(method, *args, &block)
            end
          end
        else
          # For getter methods, check all components
          @components.each do |component|
            if component.respond_to?(method)
              return component.send(method, *args, &block)
            end
          end
        end

        # If we get here, no component handled the method
        super
      end

      # Respond to missing to support method_missing
      # @param method [Symbol] the method name
      # @param include_private [Boolean] whether to include private methods
      def respond_to_missing?(method, include_private = false)
        # Log a warning about using respond_to_missing?
        Vanilla::Logger.instance.warn("Entity#respond_to_missing? called for #{method}. Consider checking component types directly. Entity: #{id}")

        # Check if method is a setter (ends with =)
        if method.to_s.end_with?('=')
          attr_name = method.to_s.chomp('=').to_sym

          # Find a component that responds to this setter
          @components.any? { |c| c.respond_to?(method) }
        else
          # For getter methods, check all components
          @components.any? { |c| c.respond_to?(method) }
        end || super
      end
    end
  end
end