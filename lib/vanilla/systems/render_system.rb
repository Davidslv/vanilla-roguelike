require_relative 'system'

module Vanilla
  module Systems
    # System that handles rendering entities to the display
    class RenderSystem < System
      # Initialize a new render system
      # @param world [World] The world this system belongs to
      def initialize(world)
        super
        @renderer = Vanilla::Renderers::TerminalRenderer.new
        @logger = Vanilla::Logger.instance
      end

      # Update method called once per frame
      # @param delta_time [Float] Time since last update
      def update(delta_time)
        begin
          # Clear screen first
          @renderer.clear

          # Early initialization error detection
          if !@world.current_level || !@world.current_level.grid
            @logger.error("Cannot render: No level or grid available")
            return
          end

          # If no entities are available yet, log and display a message
          if @world.entities.empty?
            @logger.warn("No entities found in world during rendering. Level may not be properly initialized.")
            @renderer.draw_grid(@world.current_level.grid)
            @renderer.present
            return
          end

          # Draw the grid
          render_grid

          # Get all entities with position and render components
          renderables = entities_with(:position, :render)

          if renderables.empty?
            @logger.warn("No renderable entities found with position and render components")
          else
            # Sort by render layer
            renderables.sort_by! do |entity|
              render = entity.get_component(:render)
              render.respond_to?(:layer) ? render.layer || 0 : 0
            end

            # Draw entities
            renderables.each do |entity|
              render_entity(entity)
            end
          end

          # Present the rendered frame
          @renderer.present
        rescue => e
          @logger.error("Render error: #{e.class} - #{e.message}")
          @logger.error(e.backtrace.join("\n"))
        end
      end

      # Render a single entity
      # @param entity [Entity] The entity to render
      # @return [void]
      def render_entity(entity)
        position = entity.get_component(:position)
        render = entity.get_component(:render)

        # Skip entities with missing essential components
        if !position || !render
          @logger.debug("Entity #{entity.id} missing position or render component")
          return
        end

        # Get character to render
        character = if render.respond_to?(:character) && !render.character.nil?
                     render.character
                   elsif render.respond_to?(:char) && !render.char.nil?
                     render.char
                   else
                     '?'  # Default character if none is defined
                   end

        # Get color if available
        color = render.respond_to?(:color) ? render.color : nil

        # Draw the character
        begin
          @renderer.draw_character(
            position.row,
            position.column,
            character,
            color
          )
        rescue => e
          @logger.error("Error drawing character: #{e.message}")
        end
      end

      # Legacy render method for backward compatibility
      # @param entities [Array<Entity>] The entities to render
      # @param grid [Grid] The grid to render
      # @return [void]
      def render(entities, grid)
        # Clear screen
        @renderer.clear

        # Draw the provided grid
        @renderer.draw_grid(grid)

        # Filter entities that can be rendered
        renderables = entities.select do |entity|
          entity.has_component?(:position) && entity.has_component?(:render)
        end

        # Sort by render layer
        renderables.sort_by! do |entity|
          render = entity.get_component(:render)
          render.respond_to?(:layer) ? render.layer || 0 : 0
        end

        # Draw entities
        renderables.each do |entity|
          position = entity.get_component(:position)
          render = entity.get_component(:render)

          character = render.respond_to?(:character) ? render.character : render.char
          color = render.color

          @renderer.draw_character(
            position.row,
            position.column,
            character,
            color
          )
        end

        # Update display
        @renderer.present
      end

      # Clear the screen completely (for transitions, etc.)
      # @return [void]
      def clear_screen
        @renderer.clear_screen
      end

      private

      # Render the level grid
      def render_grid
        # Check if we have a world and level
        if !@world
          @logger.error("No world available in render system")
          return false
        end

        # Check if we have a current level
        if !@world.current_level
          @logger.error("No current level available in world")
          return false
        end

        # Check if we have a grid
        grid = @world.current_level.grid
        if !grid
          @logger.error("No grid available in current level")
          return false
        end

        # Draw the grid on the renderer
        @renderer.draw_grid(grid)
        @logger.debug("Grid drawn successfully: #{grid.rows}x#{grid.columns}")
        return true
      end
    end
  end
end