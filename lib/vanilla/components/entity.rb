require 'securerandom'

module Vanilla
  module Components
    # An entity is a container for components
    class Entity
      # @return [String] unique identifier for this entity
      attr_reader :id

      # @return [Array<Component>] all components attached to this entity
      attr_reader :components

      # @return [Hash] additional data and tags for this entity
      attr_reader :data

      # Initialize a new entity
      # @param id [String, nil] optional ID for the entity, will be auto-generated if nil
      def initialize(id: nil)
        @id = id || SecureRandom.uuid
        @components = []
        @component_map = {}
        @data = {}
        @data[:tags] = []
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

      # Add a tag to the entity
      # @param tag [Symbol] the tag to add
      # @return [Entity] self, for method chaining
      def add_tag(tag)
        @data[:tags] ||= []
        @data[:tags] << tag unless @data[:tags].include?(tag)
        self
      end

      # Remove a tag from the entity
      # @param tag [Symbol] the tag to remove
      # @return [Entity] self, for method chaining
      def remove_tag(tag)
        @data[:tags] ||= []
        @data[:tags].delete(tag)
        self
      end

      # Check if the entity has the given tag
      # @param tag [Symbol] the tag to check for
      # @return [Boolean] true if the entity has the tag
      def has_tag?(tag)
        @data[:tags] ||= []
        @data[:tags].include?(tag)
      end

      # Get a value from the entity's data
      # @param key [Symbol] the data key
      # @return [Object, nil] the value, or nil if not found
      def get_data(key)
        @data[key]
      end

      # Set a value in the entity's data
      # @param key [Symbol] the data key
      # @param value [Object] the value to set
      # @return [Entity] self, for method chaining
      def set_data(key, value)
        @data[key] = value
        self
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
          components: @components.map(&:to_hash),
          data: @data
        }
      end

      # Create an entity from a hash representation
      # @param hash [Hash] serialized entity data
      # @return [Entity] the deserialized entity
      def self.from_hash(hash)
        entity = new(id: hash[:id])

        # Set data if present
        entity.instance_variable_set(:@data, hash[:data] || {})

        # Add components
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