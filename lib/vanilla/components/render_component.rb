module Vanilla
  module Components
    # RenderComponent stores visual representation data for entities.
    # It defines how an entity appears in the rendering system, including
    # its character, color, and rendering layer (z-index).
    #
    # It also stores the entity type information to replace TileComponent.
    class RenderComponent < Component
      attr_reader :character, :color, :layer, :entity_type

      # Initialize a new render component
      # @param character [String] The character to display
      # @param color [Symbol, nil] The color to use, or nil for default
      # @param layer [Integer] The rendering layer (z-index)
      # @param entity_type [String, nil] The entity type, defaults to character
      # @raise [ArgumentError] If the character is invalid
      def initialize(character:, color: nil, layer: 0, entity_type: nil)
        unless Vanilla::Support::TileType.valid?(character)
          raise ArgumentError, "Invalid character type: #{character}"
        end

        @character = character
        @color = color
        @layer = layer
        @entity_type = entity_type || character  # Default entity_type to character if not provided
        super()
      end

      # Get the component type
      # @return [Symbol] The component type
      def type
        :render
      end

      # For backward compatibility with TileComponent
      # @return [String] The character
      def tile
        @character
      end

      # Update the visual appearance
      # @param character [String] The new character to display
      # @param color [Symbol, nil] The new color, or nil to leave unchanged
      # @param layer [Integer, nil] The new layer, or nil to leave unchanged
      # @param entity_type [String, nil] The new entity_type, or nil to leave unchanged
      # @return [void]
      # @raise [ArgumentError] If the character is invalid
      def update_appearance(character: nil, color: nil, layer: nil, entity_type: nil)
        if character && !Vanilla::Support::TileType.valid?(character)
          raise ArgumentError, "Invalid character type: #{character}"
        end

        @character = character unless character.nil?
        @color = color unless color.nil?
        @layer = layer unless layer.nil?
        @entity_type = entity_type unless entity_type.nil?
      end

      # Set the rendering layer
      # @param layer [Integer] The new layer value
      # @return [void]
      def set_layer(layer)
        @layer = layer
      end

      # Set the color
      # @param color [Symbol, nil] The new color value
      # @return [void]
      def set_color(color)
        @color = color
      end

      # Get serialized component data for persistence
      # @return [Hash] Serialized component data
      def data
        {
          character: @character,
          color: @color,
          layer: @layer,
          entity_type: @entity_type
        }
      end

      # Create a component from serialized data
      # @param hash [Hash] Serialized component data
      # @return [RenderComponent] The deserialized component
      def self.from_hash(hash)
        new(
          character: hash[:character],
          color: hash[:color],
          layer: hash[:layer] || 0,
          entity_type: hash[:entity_type]
        )
      end
    end

    # Register component within the module definition
    Component.register(RenderComponent)
  end
end

# Note on component registration approach:
#
# We register the RenderComponent twice - once inside the module definition,
# and again here outside of it. This dual registration approach ensures the
# component is reliably available in the Component registry for several reasons:
#
# 1. Redundancy for reliability: The first registration happens inside the module
#    definition, but occasionally Ruby load order issues might prevent proper registration.
#    This second call ensures the component gets registered regardless.
#
# 2. Testing compatibility: During testing, components sometimes aren't properly
#    registered when accessed from test files, causing registration tests to fail.
#    The second registration makes the component consistently available for tests.
#
# 3. Explicit over implicit: Explicitly registering outside the class/module definition
#    makes it clear this component should be available in the component registry.
#
# This defensive programming technique helps avoid subtle bugs that could occur
# if the component wasn't properly registered in all execution contexts.
#
Vanilla::Components::Component.register(Vanilla::Components::RenderComponent)
