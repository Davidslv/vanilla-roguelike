module Vanilla
  module Systems
    # Factory for creating render systems
    # @deprecated - Use RenderSystem.new(world) directly
    class RenderSystemFactory
      # Create a new render system
      # @param world [World] The world to use (optional for compatibility)
      # @return [RenderSystem] A new render system
      def self.create(world = nil)
        if world
          # New ECS-style initialization
          RenderSystem.new(world)
        else
          # Legacy initialization - provide a warning
          warn "[DEPRECATED] RenderSystemFactory.create() without world parameter is deprecated."
          warn "Use RenderSystem.new(world) instead."

          renderer = Vanilla::Renderers::TerminalRenderer.new
          legacy_render_system = Class.new(RenderSystem) do
            # Override initialize to maintain compatibility
            def initialize(renderer)
              @renderer = renderer
              @logger = Vanilla::Logger.instance
            end

            # Legacy render method
            def render(entities, grid)
              # Simulate what update would do, but with external entities/grid
              @renderer.clear
              @renderer.draw_grid(grid)

              drawable_entities = entities.select do |entity|
                entity.has_component?(:position) && entity.has_component?(:render)
              end

              drawable_entities.sort_by! { |e| e.get_component(:render).layer || 0 }

              drawable_entities.each do |entity|
                render_component = entity.get_component(:render)
                position = entity.get_component(:position)

                @renderer.draw_character(
                  position.row,
                  position.column,
                  render_component.respond_to?(:char) ? render_component.char : render_component.character,
                  render_component.color
                )
              end

              @renderer.present
            end
          end

          legacy_render_system.new(renderer)
        end
      end
    end
  end
end
