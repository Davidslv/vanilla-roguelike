require 'securerandom'
require 'set'

module Vanilla
  module Components
    # An entity is a container for components
    class Entity
      # @return [String] unique identifier for this entity
      attr_reader :id

      # @return [Array<Component>] all components attached to this entity
      attr_reader :components

      # @return [String] name of the entity (for display purposes)
      attr_accessor :name

      # Initialize a new entity
      # @param id [String, nil] optional ID for the entity, will be auto-generated if nil
      def initialize(id: nil)
        @id = id || SecureRandom.uuid
        @components = []
        @component_map = {}
        @tags = Set.new
        @name = "Entity_#{@id[0..7]}"
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
      # @param type [Symbol] the type to check for
      # @return [Boolean] true if the entity has a component of the given type
      def has_component?(type)
        @component_map.key?(type)
      end

      # Get a component of the given type
      # @param type [Symbol] the type to get
      # @return [Component, nil] the component, or nil if not found
      def get_component(type)
        @component_map[type]
      end

      # Add a tag to the entity
      # @param tag [Symbol, String] the tag to add
      # @return [Entity] self, for method chaining
      def add_tag(tag)
        @tags.add(tag.to_sym)
        self
      end

      # Remove a tag from the entity
      # @param tag [Symbol, String] the tag to remove
      # @return [Entity] self, for method chaining
      def remove_tag(tag)
        @tags.delete(tag.to_sym)
        self
      end

      # Check if the entity has a tag
      # @param tag [Symbol, String] the tag to check for
      # @return [Boolean] true if the entity has the tag
      def has_tag?(tag)
        @tags.include?(tag.to_sym)
      end

      # Get all tags on the entity
      # @return [Array<Symbol>] the tags
      def tags
        @tags.to_a
      end

      # Update all components
      # @param delta_time [Float] time since last update
      def update(delta_time)
        @components.each do |component|
          component.update(delta_time) if component.respond_to?(:update)
        end
      end

      # Convert to hash for serialization
      # @return [Hash] serialized representation
      def to_hash
        {
          id: @id,
          name: @name,
          tags: @tags.to_a,
          components: @components.map(&:to_hash)
        }
      end

      # Create from hash for deserialization
      # @param hash [Hash] serialized representation
      # @return [Entity] the new entity
      def self.from_hash(hash)
        entity = new(id: hash[:id])
        entity.name = hash[:name] if hash[:name]

        # Add tags
        hash[:tags]&.each do |tag|
          entity.add_tag(tag)
        end

        # Add components
        hash[:components]&.each do |component_hash|
          component_type = component_hash[:type]
          component_class = Component.get_class(component_type)

          if component_class
            component = component_class.from_hash(component_hash)
            entity.add_component(component)
          end
        end

        entity
      end

      # Method missing to provide component accessors
      # @deprecated Use #get_component instead
      def method_missing(method, *args, &block)
        # Log a warning about using method_missing
        Vanilla::Logger.instance.warn("Entity#method_missing called for #{method}. Consider accessing the component directly instead. Entity: #{id}")

        # Check for component accessor methods (e.g., position, render, etc.)
        component_type = method.to_sym
        return get_component(component_type) if has_component?(component_type)

        # Check for component predicate methods (e.g., position?, render?, etc.)
        if method.to_s.end_with?('?')
          component_type = method.to_s.chomp('?').to_sym
          return has_component?(component_type)
        end

        super
      end

      # Allow respond_to? to work with method_missing
      # @deprecated Use #has_component? instead
      def respond_to_missing?(method, include_private = false)
        # Log a warning about using respond_to_missing?
        Vanilla::Logger.instance.warn("Entity#respond_to_missing? called for #{method}. Consider checking component types directly. Entity: #{id}")

        component_type = method.to_sym
        return true if has_component?(component_type)

        if method.to_s.end_with?('?')
          component_type = method.to_s.chomp('?').to_sym
          return true if @component_map.key?(component_type)
        end

        super
      end
    end
  end
end
