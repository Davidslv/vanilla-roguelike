module Vanilla
  module Components
    # RenderComponent stores visual representation data for entities.
    # It defines how an entity appears in the rendering system, including
    # its character, color, and rendering layer (z-index).
    class RenderComponent < Component
      attr_reader :character, :color, :layer

      def initialize(character:, color: nil, layer: 0)
        @character = character
        @color = color
        @layer = layer
        super()
      end

      def type
        :render
      end

      def data
        {
          character: @character,
          color: @color,
          layer: @layer
        }
      end

      def self.from_hash(hash)
        new(
          character: hash[:character],
          color: hash[:color],
          layer: hash[:layer] || 0
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